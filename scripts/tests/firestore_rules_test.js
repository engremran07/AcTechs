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
      activeTech.firestore().collection('jobs').add({
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