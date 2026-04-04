const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');

admin.initializeApp();

const db = admin.firestore();
const jobsCollection = 'jobs';
const usersCollection = 'users';
const approvalConfigPath = 'app_settings/approval_config';
const sharedAggregatesCollection = 'shared_install_aggregates';
const sharedBracketType = 'Bracket';

function normalizeInvoice(invoice) {
  const trimmed = `${invoice ?? ''}`.trim();
  if (!trimmed) return '';
  const upper = trimmed.toUpperCase();
  if (upper.startsWith('INV-') || upper.startsWith('INV ')) {
    return trimmed.substring(4).trim();
  }
  return trimmed;
}

function safeAggregateDocId(groupKey) {
  const safe = `${groupKey}`.replace(/[^a-z0-9_-]/g, '_');
  const scoped = `shared_${safe || Date.now()}`;
  return scoped.length > 140 ? scoped.substring(0, 140) : scoped;
}

function unitsForType(job, type) {
  return (job.acUnits || [])
    .filter((unit) => unit.type === type)
    .reduce((total, unit) => total + (Number(unit.quantity) || 0), 0);
}

function bracketCount(job) {
  return Number(job.charges?.bracketCount || 0);
}

function numberValue(value) {
  return Number(value || 0);
}

function ensureAuth(request) {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  return request.auth.uid;
}

async function getActiveUser(tx, uid) {
  const userRef = db.collection(usersCollection).doc(uid);
  const userSnap = await tx.get(userRef);
  if (!userSnap.exists) {
    throw new HttpsError('permission-denied', 'User is not provisioned.');
  }
  const user = userSnap.data() || {};
  if (user.isActive === false) {
    throw new HttpsError('permission-denied', 'User is inactive.');
  }
  return user;
}

function ensureAdmin(user) {
  const role = `${user.role || ''}`.trim().toLowerCase();
  if (role !== 'admin' && role !== 'administrator') {
    throw new HttpsError('permission-denied', 'Admin access required.');
  }
}

function ensureSharedJobShape(job, callerUid) {
  if (!job || typeof job !== 'object') {
    throw new HttpsError('invalid-argument', 'Job payload is required.');
  }
  if (job.techId !== callerUid) {
    throw new HttpsError('permission-denied', 'Job owner mismatch.');
  }
  if (job.isSharedInstall !== true) {
    throw new HttpsError('invalid-argument', 'Shared job payload expected.');
  }

  const invoiceNumber = normalizeInvoice(job.invoiceNumber);
  if (!invoiceNumber) {
    throw new HttpsError('invalid-argument', 'Invoice number is required.');
  }

  const companyKey = `${job.companyId || 'no-company'}`.toLowerCase();
  const normalizedGroupKey = `${job.sharedInstallGroupKey || ''}`
    .trim()
    .toLowerCase();
  const resolvedGroupKey =
    normalizedGroupKey || `${companyKey}-${invoiceNumber.toLowerCase()}`;

  const splitContribution = unitsForType(job, 'Split AC');
  const windowContribution = unitsForType(job, 'Window AC');
  const freestandingContribution = unitsForType(job, 'Freestanding AC');
  const bracketContribution = bracketCount(job);
  const deliveryContribution = numberValue(job.charges?.deliveryAmount);
  const invoiceDeliveryAmount = numberValue(job.sharedInvoiceDeliveryAmount);

  const limits = [
    ['Split AC', splitContribution, numberValue(job.sharedInvoiceSplitUnits)],
    ['Window AC', windowContribution, numberValue(job.sharedInvoiceWindowUnits)],
    ['Freestanding AC', freestandingContribution, numberValue(job.sharedInvoiceFreestandingUnits)],
    [sharedBracketType, bracketContribution, numberValue(job.sharedInvoiceBracketCount)],
  ];

  for (const [unitType, contribution, totalAllowed] of limits) {
    if (contribution <= 0) continue;
    if (totalAllowed <= 0 || contribution > totalAllowed) {
      throw new HttpsError(
        'failed-precondition',
        'Shared units exceed invoice total.',
        { code: 'job_shared_type_units_exceeded', unitType, remaining: Math.max(totalAllowed, 0) },
      );
    }
  }

  if (deliveryContribution > 0 && invoiceDeliveryAmount <= 0) {
    throw new HttpsError(
      'failed-precondition',
      'Delivery share exceeds invoice total.',
      { code: 'job_shared_units_exceeded', remaining: 0 },
    );
  }

  if (invoiceDeliveryAmount > 0 && numberValue(job.sharedDeliveryTeamCount) <= 0) {
    throw new HttpsError(
      'failed-precondition',
      'Enter the shared team size for delivery split.',
      { code: 'job_shared_delivery_split_invalid' },
    );
  }

  return {
    invoiceNumber,
    resolvedGroupKey,
    splitContribution,
    windowContribution,
    freestandingContribution,
    bracketContribution,
    deliveryContribution,
  };
}

function aggregateCreateData(job, resolvedGroupKey, contributions, callerUid) {
  return {
    groupKey: resolvedGroupKey,
    sharedInvoiceSplitUnits: numberValue(job.sharedInvoiceSplitUnits),
    sharedInvoiceWindowUnits: numberValue(job.sharedInvoiceWindowUnits),
    sharedInvoiceFreestandingUnits: numberValue(job.sharedInvoiceFreestandingUnits),
    sharedInvoiceBracketCount: numberValue(job.sharedInvoiceBracketCount),
    sharedDeliveryTeamCount: numberValue(job.sharedDeliveryTeamCount),
    sharedInvoiceDeliveryAmount: numberValue(job.sharedInvoiceDeliveryAmount),
    consumedSplitUnits: contributions.splitContribution,
    consumedWindowUnits: contributions.windowContribution,
    consumedFreestandingUnits: contributions.freestandingContribution,
    consumedBracketCount: contributions.bracketContribution,
    consumedDeliveryAmount: contributions.deliveryContribution,
    createdBy: callerUid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

function ensureAggregateTotals(aggregate, job, resolvedGroupKey) {
  const sameTotals =
    aggregate.groupKey === resolvedGroupKey &&
    numberValue(aggregate.sharedInvoiceSplitUnits) === numberValue(job.sharedInvoiceSplitUnits) &&
    numberValue(aggregate.sharedInvoiceWindowUnits) === numberValue(job.sharedInvoiceWindowUnits) &&
    numberValue(aggregate.sharedInvoiceFreestandingUnits) === numberValue(job.sharedInvoiceFreestandingUnits) &&
    numberValue(aggregate.sharedInvoiceBracketCount) === numberValue(job.sharedInvoiceBracketCount) &&
    numberValue(aggregate.sharedDeliveryTeamCount) === numberValue(job.sharedDeliveryTeamCount) &&
    Math.abs(numberValue(aggregate.sharedInvoiceDeliveryAmount) - numberValue(job.sharedInvoiceDeliveryAmount)) <= 0.01;

  if (!sameTotals) {
    throw new HttpsError(
      'failed-precondition',
      'Shared invoice totals do not match.',
      { code: 'job_shared_group_mismatch' },
    );
  }
}

function sharedJobDoc(job, invoiceNumber, resolvedGroupKey, status) {
  const createdAt = job.date ? admin.firestore.Timestamp.fromMillis(Number(job.date)) : admin.firestore.FieldValue.serverTimestamp();
  const submittedAt = job.submittedAt ? admin.firestore.Timestamp.fromMillis(Number(job.submittedAt)) : admin.firestore.FieldValue.serverTimestamp();

  return {
    techId: `${job.techId}`,
    techName: `${job.techName || ''}`,
    companyId: `${job.companyId || ''}`,
    companyName: `${job.companyName || ''}`,
    invoiceNumber,
    clientName: `${job.clientName || ''}`,
    clientContact: `${job.clientContact || ''}`,
    acUnits: Array.isArray(job.acUnits) ? job.acUnits : [],
    status,
    expenses: numberValue(job.expenses),
    expenseNote: `${job.expenseNote || ''}`,
    adminNote: '',
    approvedBy: job.approvedBy || null,
    isSharedInstall: true,
    sharedInstallGroupKey: resolvedGroupKey,
    sharedInvoiceTotalUnits: numberValue(job.sharedInvoiceTotalUnits),
    sharedContributionUnits: numberValue(job.sharedContributionUnits),
    sharedInvoiceSplitUnits: numberValue(job.sharedInvoiceSplitUnits),
    sharedInvoiceWindowUnits: numberValue(job.sharedInvoiceWindowUnits),
    sharedInvoiceFreestandingUnits: numberValue(job.sharedInvoiceFreestandingUnits),
    sharedInvoiceBracketCount: numberValue(job.sharedInvoiceBracketCount),
    sharedDeliveryTeamCount: numberValue(job.sharedDeliveryTeamCount),
    sharedInvoiceDeliveryAmount: numberValue(job.sharedInvoiceDeliveryAmount),
    techSplitShare: numberValue(job.techSplitShare),
    techWindowShare: numberValue(job.techWindowShare),
    techFreestandingShare: numberValue(job.techFreestandingShare),
    techBracketShare: numberValue(job.techBracketShare),
    charges: job.charges || null,
    date: createdAt,
    submittedAt,
  };
}

function aggregateUpdateData(currentAggregate, job, contributions, direction) {
  const delta = direction === 'release' ? -1 : 1;
  return {
    consumedSplitUnits: Math.max(0, numberValue(currentAggregate.consumedSplitUnits) + delta * contributions.splitContribution),
    consumedWindowUnits: Math.max(0, numberValue(currentAggregate.consumedWindowUnits) + delta * contributions.windowContribution),
    consumedFreestandingUnits: Math.max(0, numberValue(currentAggregate.consumedFreestandingUnits) + delta * contributions.freestandingContribution),
    consumedBracketCount: Math.max(0, numberValue(currentAggregate.consumedBracketCount) + delta * contributions.bracketContribution),
    consumedDeliveryAmount: Math.max(0, numberValue(currentAggregate.consumedDeliveryAmount) + delta * contributions.deliveryContribution),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

function ensureRemainingCapacity(aggregate, job, contributions) {
  const typeChecks = [
    ['Split AC', contributions.splitContribution, numberValue(job.sharedInvoiceSplitUnits), numberValue(aggregate.consumedSplitUnits)],
    ['Window AC', contributions.windowContribution, numberValue(job.sharedInvoiceWindowUnits), numberValue(aggregate.consumedWindowUnits)],
    ['Freestanding AC', contributions.freestandingContribution, numberValue(job.sharedInvoiceFreestandingUnits), numberValue(aggregate.consumedFreestandingUnits)],
    [sharedBracketType, contributions.bracketContribution, numberValue(job.sharedInvoiceBracketCount), numberValue(aggregate.consumedBracketCount)],
  ];

  for (const [unitType, contribution, totalAllowed, consumed] of typeChecks) {
    if (contribution <= 0) continue;
    const remaining = totalAllowed - consumed;
    if (contribution > remaining) {
      throw new HttpsError(
        'failed-precondition',
        'Shared units exceed invoice total.',
        { code: 'job_shared_type_units_exceeded', unitType, remaining: Math.max(remaining, 0) },
      );
    }
  }

  const invoiceDeliveryAmount = numberValue(job.sharedInvoiceDeliveryAmount);
  if (invoiceDeliveryAmount > 0) {
    const remainingDelivery = invoiceDeliveryAmount - numberValue(aggregate.consumedDeliveryAmount);
    if (contributions.deliveryContribution - remainingDelivery > 0.01) {
      throw new HttpsError(
        'failed-precondition',
        'Shared units exceed invoice total.',
        { code: 'job_shared_units_exceeded', remaining: remainingDelivery <= 0 ? 0 : Math.floor(remainingDelivery) },
      );
    }
  }
}

exports.submitSharedJob = onCall(async (request) => {
  const callerUid = ensureAuth(request);
  const rawJob = request.data?.job;

  await db.runTransaction(async (tx) => {
    await getActiveUser(tx, callerUid);
    const contributions = ensureSharedJobShape(rawJob, callerUid);
    const duplicateQuery = db.collection(jobsCollection)
      .where('techId', '==', callerUid)
      .where('companyId', '==', `${rawJob.companyId || ''}`)
      .where('invoiceNumber', '==', contributions.invoiceNumber)
      .limit(1);
    const duplicateSnap = await tx.get(duplicateQuery);
    if (!duplicateSnap.empty) {
      throw new HttpsError(
        'already-exists',
        'A job with this invoice number already exists.',
        { code: 'job_duplicate_invoice' },
      );
    }

    const approvalSnap = await tx.get(db.doc(approvalConfigPath));
    const sharedJobApprovalRequired = approvalSnap.exists && approvalSnap.get('sharedJobApprovalRequired') === true;
    const status = sharedJobApprovalRequired ? 'pending' : 'approved';

    const aggregateRef = db.collection(sharedAggregatesCollection)
      .doc(safeAggregateDocId(contributions.resolvedGroupKey));
    const aggregateSnap = await tx.get(aggregateRef);
    const aggregate = aggregateSnap.exists ? aggregateSnap.data() : null;

    if (aggregate) {
      ensureAggregateTotals(aggregate, rawJob, contributions.resolvedGroupKey);
      ensureRemainingCapacity(aggregate, rawJob, contributions);
      tx.update(
        aggregateRef,
        aggregateUpdateData(aggregate, rawJob, contributions, 'reserve'),
      );
    } else {
      tx.set(
        aggregateRef,
        aggregateCreateData(rawJob, contributions.resolvedGroupKey, contributions, callerUid),
      );
    }

    const jobRef = db.collection(jobsCollection).doc();
    tx.set(jobRef, sharedJobDoc(rawJob, contributions.invoiceNumber, contributions.resolvedGroupKey, status));
  });

  return { ok: true };
});

exports.reviewJob = onCall(async (request) => {
  const callerUid = ensureAuth(request);
  const action = `${request.data?.action || ''}`;
  const reason = `${request.data?.reason || ''}`.trim();
  const jobId = `${request.data?.jobId || ''}`.trim();

  if (!jobId) {
    throw new HttpsError('invalid-argument', 'Job id is required.');
  }
  if (action !== 'approve' && action !== 'reject') {
    throw new HttpsError('invalid-argument', 'Unsupported review action.');
  }
  if (action === 'reject' && !reason) {
    throw new HttpsError('invalid-argument', 'Reject reason is required.');
  }

  await db.runTransaction(async (tx) => {
    const reviewer = await getActiveUser(tx, callerUid);
    ensureAdmin(reviewer);

    const jobRef = db.collection(jobsCollection).doc(jobId);
    const jobSnap = await tx.get(jobRef);
    if (!jobSnap.exists) {
      throw new HttpsError('not-found', 'Job not found.');
    }

    const job = jobSnap.data() || {};
    const previousStatus = `${job.status || 'pending'}`;
    const isSharedInstall = job.isSharedInstall === true;

    if (isSharedInstall) {
      const contributions = {
        splitContribution: unitsForType(job, 'Split AC'),
        windowContribution: unitsForType(job, 'Window AC'),
        freestandingContribution: unitsForType(job, 'Freestanding AC'),
        bracketContribution: bracketCount(job),
        deliveryContribution: numberValue(job.charges?.deliveryAmount),
        resolvedGroupKey: `${job.sharedInstallGroupKey || ''}`,
      };
      const aggregateRef = db.collection(sharedAggregatesCollection)
        .doc(safeAggregateDocId(contributions.resolvedGroupKey));
      const aggregateSnap = await tx.get(aggregateRef);
      const aggregate = aggregateSnap.exists ? aggregateSnap.data() : null;

      if (action === 'reject' && previousStatus !== 'rejected' && aggregate) {
        tx.update(
          aggregateRef,
          aggregateUpdateData(aggregate, job, contributions, 'release'),
        );
      }

      if (action === 'approve' && previousStatus === 'rejected') {
        if (!aggregate) {
          throw new HttpsError(
            'failed-precondition',
            'Shared aggregate is missing.',
            { code: 'job_shared_group_mismatch' },
          );
        }
        ensureAggregateTotals(aggregate, job, contributions.resolvedGroupKey);
        ensureRemainingCapacity(aggregate, job, contributions);
        tx.update(
          aggregateRef,
          aggregateUpdateData(aggregate, job, contributions, 'reserve'),
        );
      }
    }

    tx.update(jobRef, {
      status: action === 'approve' ? 'approved' : 'rejected',
      approvedBy: callerUid,
      adminNote: action === 'approve' ? '' : reason,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(jobRef.collection('history').doc(), {
      changedBy: callerUid,
      changedAt: admin.firestore.FieldValue.serverTimestamp(),
      previousStatus,
      newStatus: action === 'approve' ? 'approved' : 'rejected',
      ...(action === 'reject' ? { reason } : {}),
    });
  });

  return { ok: true };
});