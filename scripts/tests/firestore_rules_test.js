const fs = require('fs');
const path = require('path');
const assert = require('assert');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const projectId = 'actechs-rules-test';
const rules = fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8');

async function seedDoc(context, docPath, data) {
  await context.firestore().doc(docPath).set(data);
}

async function createJobWithClaim(context, job) {
  const batch = context.firestore().batch();
  const invoiceNumber = job.invoiceNumber;
  const claimRef = context.firestore().doc(`invoice_claims/${invoiceNumber}`);
  const jobRef = context.firestore().collection('jobs').doc();
  const existingClaim = await claimRef.get();
  const now = job.submittedAt;

  if (!existingClaim.exists) {
    batch.set(claimRef, {
      invoiceNumber,
      companyId: job.companyId,
      companyName: job.companyName,
      reuseMode: job.isSharedInstall ? 'shared' : 'solo',
      activeJobCount: 1,
      createdBy: job.techId,
      createdAt: now,
      updatedAt: now,
    });
  } else {
    const claim = existingClaim.data();
    batch.update(claimRef, {
      invoiceNumber,
      companyId: claim.companyId,
      companyName: claim.companyName,
      reuseMode: claim.reuseMode,
      activeJobCount: (claim.activeJobCount || 0) + 1,
      createdBy: claim.createdBy,
      createdAt: claim.createdAt,
      updatedAt: now,
    });
  }

  batch.set(jobRef, job);
  await batch.commit();
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });

  try {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await seedDoc(context, 'users/admin-1', {
        name: 'Admin',
        email: 'admin@example.com',
        role: 'admin',
        isActive: true,
      });
      await seedDoc(context, 'users/tech-1', {
        name: 'Tech One',
        email: 'tech1@example.com',
        role: 'technician',
        isActive: true,
      });
      await seedDoc(context, 'users/tech-2', {
        name: 'Tech Two',
        email: 'tech2@example.com',
        role: 'technician',
        isActive: false,
      });
      await seedDoc(context, 'app_settings/approval_config', {
        inOutApprovalRequired: true,
        jobApprovalRequired: true,
        sharedJobApprovalRequired: true,
        enforceMinimumBuild: false,
        minSupportedBuildNumber: 1,
      });
      await seedDoc(context, 'ac_installs/install-1', {
        techId: 'tech-1',
        techName: 'Tech One',
        splitTotal: 2,
        splitShare: 1,
        windowTotal: 0,
        windowShare: 0,
        freestandingTotal: 0,
        freestandingShare: 0,
        note: 'Pending install',
        status: 'pending',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T08:00:00Z'),
        createdAt: new Date('2024-01-12T08:00:00Z'),
        reviewedAt: null,
      });
    });

    const activeTech = testEnv.authenticatedContext('tech-1');
    const inactiveTech = testEnv.authenticatedContext('tech-2');
    const admin = testEnv.authenticatedContext('admin-1');

    await assertSucceeds(
      activeTech.firestore().collection('ac_installs').add({
        techId: 'tech-1',
        techName: 'Tech One',
        splitTotal: 3,
        splitShare: 2,
        windowTotal: 0,
        windowShare: 0,
        freestandingTotal: 0,
        freestandingShare: 0,
        note: 'Fresh install',
        status: 'pending',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T09:00:00Z'),
        createdAt: new Date('2024-01-12T09:00:00Z'),
        reviewedAt: null,
      }),
    );

    await assertFails(
      inactiveTech.firestore().collection('ac_installs').add({
        techId: 'tech-2',
        techName: 'Tech Two',
        splitTotal: 1,
        splitShare: 1,
        windowTotal: 0,
        windowShare: 0,
        freestandingTotal: 0,
        freestandingShare: 0,
        note: 'Blocked install',
        status: 'pending',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T09:00:00Z'),
        createdAt: new Date('2024-01-12T09:00:00Z'),
        reviewedAt: null,
      }),
    );

    await assertFails(
      activeTech.firestore().doc('ac_installs/install-1').update({
        status: 'approved',
        approvedBy: 'tech-1',
        adminNote: 'self approved',
        reviewedAt: new Date('2024-01-12T10:00:00Z'),
      }),
    );

    await assertSucceeds(
      activeTech.firestore().doc('users/tech-1').update({
        name: 'Tech One Updated',
      }),
    );

    await assertFails(
      activeTech.firestore().doc('users/tech-1').update({
        email: 'other@example.com',
      }),
    );

    await assertFails(activeTech.firestore().doc('users/tech-1').delete());

    await assertSucceeds(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-350',
        clientName: 'Solo Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: false,
        charges: null,
        date: new Date('2024-01-12T08:30:00Z'),
        submittedAt: new Date('2024-01-12T08:30:00Z'),
      }),
    );

    await assertSucceeds(
      createJobWithClaim(admin, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-351',
        clientName: 'Imported Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'approved',
        expenses: 0,
        expenseNote: 'Historical import',
        adminNote: 'Imported by admin',
        approvedBy: 'admin-1',
        isSharedInstall: false,
        charges: null,
        date: new Date('2024-01-11T08:30:00Z'),
        submittedAt: new Date('2024-01-11T08:30:00Z'),
      }),
    );

    await assertSucceeds(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-400',
        clientName: 'Client',
        clientContact: '',
        acUnits: [
          { type: 'Split AC', quantity: 1 },
          { type: 'Uninstallation Split', quantity: 1 },
        ],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: true,
        sharedInstallGroupKey: 'company-1-inv-400',
        sharedInvoiceTotalUnits: 3,
        sharedContributionUnits: 2,
        sharedInvoiceSplitUnits: 2,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 1,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        techSplitShare: 1,
        techWindowShare: 0,
        techFreestandingShare: 0,
        techUninstallSplitShare: 1,
        techUninstallWindowShare: 0,
        techUninstallFreestandingShare: 0,
        techBracketShare: 0,
        charges: null,
        date: new Date('2024-01-12T09:00:00Z'),
        submittedAt: new Date('2024-01-12T09:00:00Z'),
      }),
    );

    await assertFails(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-401',
        clientName: 'Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: true,
        sharedInstallGroupKey: 'company-1-inv-401',
        sharedInvoiceTotalUnits: 1,
        sharedContributionUnits: 1,
        sharedInvoiceSplitUnits: 1,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 0,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 2,
        sharedInvoiceDeliveryAmount: 1000001,
        techSplitShare: 1,
        techWindowShare: 0,
        techFreestandingShare: 0,
        techUninstallSplitShare: 0,
        techUninstallWindowShare: 0,
        techUninstallFreestandingShare: 0,
        techBracketShare: 0,
        charges: null,
        date: new Date('2024-01-12T09:05:00Z'),
        submittedAt: new Date('2024-01-12T09:05:00Z'),
      }),
    );

    await assertFails(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-2',
        companyName: 'Other Company',
        invoiceNumber: 'INV-350',
        clientName: 'Cross Company Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: false,
        charges: null,
        date: new Date('2024-01-12T08:45:00Z'),
        submittedAt: new Date('2024-01-12T08:45:00Z'),
      }),
    );

    await assertFails(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-2',
        companyName: 'Other Company',
        invoiceNumber: 'INV-400',
        clientName: 'Cross Company Shared Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: true,
        sharedInstallGroupKey: 'company-2-inv-400',
        sharedInvoiceTotalUnits: 1,
        sharedContributionUnits: 1,
        sharedInvoiceSplitUnits: 1,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 0,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        techSplitShare: 1,
        techWindowShare: 0,
        techFreestandingShare: 0,
        techUninstallSplitShare: 0,
        techUninstallWindowShare: 0,
        techUninstallFreestandingShare: 0,
        techBracketShare: 0,
        charges: null,
        date: new Date('2024-01-12T09:01:00Z'),
        submittedAt: new Date('2024-01-12T09:01:00Z'),
      }),
    );

    await assertSucceeds(
      activeTech.firestore().doc('shared_install_aggregates/group-1').set({
        groupKey: 'group-1',
        sharedInvoiceSplitUnits: 2,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 1,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        consumedSplitUnits: 1,
        consumedWindowUnits: 0,
        consumedFreestandingUnits: 0,
        consumedUninstallSplitUnits: 1,
        consumedUninstallWindowUnits: 0,
        consumedUninstallFreestandingUnits: 0,
        consumedBracketCount: 0,
        consumedDeliveryAmount: 0,
        createdBy: 'tech-1',
        createdAt: new Date('2024-01-12T09:00:00Z'),
        updatedAt: new Date('2024-01-12T09:00:00Z'),
      }),
    );

    await assertSucceeds(
      activeTech.firestore().doc('shared_install_aggregates/group-1').update({
        groupKey: 'group-1',
        sharedInvoiceSplitUnits: 2,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 1,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        consumedSplitUnits: 2,
        consumedWindowUnits: 0,
        consumedFreestandingUnits: 0,
        consumedUninstallSplitUnits: 1,
        consumedUninstallWindowUnits: 0,
        consumedUninstallFreestandingUnits: 0,
        consumedBracketCount: 0,
        consumedDeliveryAmount: 0,
        createdBy: 'tech-1',
        createdAt: new Date('2024-01-12T09:00:00Z'),
        updatedAt: new Date('2024-01-12T09:05:00Z'),
      }),
    );

    await assertFails(
      activeTech.firestore().doc('shared_install_aggregates/group-1').update({
        groupKey: 'group-1',
        sharedInvoiceSplitUnits: 2,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 1,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        consumedSplitUnits: 1,
        consumedWindowUnits: 0,
        consumedFreestandingUnits: 0,
        consumedUninstallSplitUnits: 0,
        consumedUninstallWindowUnits: 0,
        consumedUninstallFreestandingUnits: 0,
        consumedBracketCount: 0,
        consumedDeliveryAmount: 0,
        createdBy: 'tech-1',
        createdAt: new Date('2024-01-12T09:00:00Z'),
        updatedAt: new Date('2024-01-12T09:06:00Z'),
      }),
    );

    await assertFails(activeTech.firestore().doc('ac_installs/install-1').delete());

    await assertSucceeds(
      admin.firestore().doc('ac_installs/install-1').update({
        status: 'approved',
        approvedBy: 'admin-1',
        adminNote: '',
        reviewedAt: new Date('2024-01-12T10:00:00Z'),
      }),
    );

    await assertSucceeds(
      admin.firestore().doc('ac_installs/install-1/history/event-1').set({
        changedBy: 'admin-1',
        changedAt: new Date('2024-01-12T10:00:00Z'),
        previousStatus: 'pending',
        newStatus: 'approved',
      }),
    );

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await seedDoc(context, 'app_settings/approval_config', {
        inOutApprovalRequired: false,
        jobApprovalRequired: true,
        sharedJobApprovalRequired: true,
        enforceMinimumBuild: false,
        minSupportedBuildNumber: 1,
      });
    });

    await assertFails(
      activeTech.firestore().collection('expenses').add({
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Fuel',
        amount: 25,
        note: '',
        expenseType: 'work',
        status: 'approved',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T09:00:00Z'),
        createdAt: new Date('2024-01-12T09:00:00Z'),
        reviewedAt: null,
      }),
    );

    await assertFails(
      activeTech.firestore().collection('earnings').add({
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Other',
        amount: 25,
        note: '',
        paymentType: 'cash',
        status: 'approved',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T09:00:00Z'),
        createdAt: new Date('2024-01-12T09:00:00Z'),
        reviewedAt: null,
      }),
    );

    await assertSucceeds(
      activeTech.firestore().collection('expenses').add({
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Fuel',
        amount: 25,
        note: '',
        expenseType: 'work',
        status: 'approved',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T09:00:00Z'),
        createdAt: new Date('2024-01-12T09:00:00Z'),
        reviewedAt: new Date('2024-01-12T09:05:00Z'),
      }),
    );

    await assertSucceeds(
      activeTech.firestore().collection('earnings').add({
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Other',
        amount: 25,
        note: '',
        paymentType: 'cash',
        status: 'approved',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T09:00:00Z'),
        createdAt: new Date('2024-01-12T09:00:00Z'),
        reviewedAt: new Date('2024-01-12T09:05:00Z'),
      }),
    );

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('app_settings/approval_config').delete();
    });

    await assertFails(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-999',
        clientName: 'Fail Closed Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'approved',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: false,
        charges: null,
        date: new Date('2024-01-12T09:30:00Z'),
        submittedAt: new Date('2024-01-12T09:30:00Z'),
      }),
    );

    await assertSucceeds(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-1000',
        clientName: 'Pending Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: false,
        charges: null,
        date: new Date('2024-01-12T09:35:00Z'),
        submittedAt: new Date('2024-01-12T09:35:00Z'),
      }),
    );

    const historyDoc = await admin
      .firestore()
      .doc('ac_installs/install-1/history/event-1')
      .get();
    assert.strictEqual(historyDoc.data().newStatus, 'approved');
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});