// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AC Techs';

  @override
  String get techMgmtSystem => 'Technician Management System';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get enterValidEmail => 'Please enter a valid email';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get required => 'Required';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String minChars(int count) {
    return 'Min $count characters';
  }

  @override
  String get technician => 'Technician';

  @override
  String get admin => 'Admin';

  @override
  String get administrator => 'Administrator';

  @override
  String get home => 'Home';

  @override
  String get jobs => 'Jobs';

  @override
  String get expenses => 'Expenses';

  @override
  String get profile => 'Profile';

  @override
  String get approvals => 'Approvals';

  @override
  String get analytics => 'Analytics';

  @override
  String get team => 'Team';

  @override
  String get export => 'Export';

  @override
  String get submit => 'Submit';

  @override
  String get submitForApproval => 'Submit for Approval';

  @override
  String get submitting => 'Submitting...';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get today => 'Today';

  @override
  String get thisMonth => 'This Month';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get invoiceNumber => 'Invoice Number';

  @override
  String get clientName => 'Client Name';

  @override
  String get clientNameOptional => 'Client Name (optional)';

  @override
  String get clientContact => 'Client Contact';

  @override
  String get clientPhone => 'Client Phone Number';

  @override
  String get acUnits => 'AC Units';

  @override
  String get addUnit => 'Add Unit';

  @override
  String get unitType => 'Unit Type';

  @override
  String get quantity => 'Quantity';

  @override
  String get expenseAmount => 'Expense Amount';

  @override
  String get expenseNote => 'Expense Note';

  @override
  String get adminNote => 'Admin Note';

  @override
  String get rejectReason => 'Reason for rejection';

  @override
  String get noJobsYet => 'No jobs submitted yet';

  @override
  String get noJobsToday => 'No jobs submitted today';

  @override
  String get noMatchingJobs => 'No matching jobs';

  @override
  String get noApprovals => 'No pending approvals';

  @override
  String get noMatchingApprovals => 'No matching approvals';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get todaysJobs => 'Today\'s Jobs';

  @override
  String get totalJobs => 'Total Jobs';

  @override
  String get pendingApprovals => 'Pending Approvals';

  @override
  String get approvedJobs => 'Approved Jobs';

  @override
  String get rejectedJobs => 'Rejected Jobs';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get teamMembers => 'Team Members';

  @override
  String get activeMembers => 'Active Members';

  @override
  String get jobSubmitted =>
      'Job submitted successfully! Waiting for admin approval.';

  @override
  String get jobApproved => 'Job approved!';

  @override
  String get jobRejected => 'Job returned with your feedback.';

  @override
  String get couldNotApprove => 'Could not approve. Please try again.';

  @override
  String get couldNotReject => 'Could not reject. Please try again.';

  @override
  String bulkApproveSuccess(int count) {
    return '$count jobs approved!';
  }

  @override
  String bulkRejectSuccess(int count) {
    return '$count jobs rejected.';
  }

  @override
  String get bulkApproveFailed => 'Bulk approve failed. Try again.';

  @override
  String get bulkRejectFailed => 'Bulk reject failed. Try again.';

  @override
  String get rejectSelectedJobs => 'Reject Selected Jobs';

  @override
  String get rejectAll => 'Reject All';

  @override
  String get rejectJob => 'Reject Job';

  @override
  String exportSuccess(int count) {
    return 'Export ready! $count jobs exported to Excel.';
  }

  @override
  String get exportFailed =>
      'Couldn\'t create the export file. Please try again.';

  @override
  String get noJobsForPeriod =>
      'No jobs found for this period. Try a different date range.';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportExcel => 'Export to Excel';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get urdu => 'اردو';

  @override
  String get arabic => 'العربية';

  @override
  String get settings => 'Settings';

  @override
  String get offline => 'Offline';

  @override
  String get syncing => 'Syncing...';

  @override
  String get jobHistory => 'Job History';

  @override
  String get submitJob => 'Submit Job';

  @override
  String get submitInvoice => 'Submit Invoice';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get welcomeBack => 'Welcome back,';

  @override
  String get selectDate => 'Select Date';

  @override
  String get tapToChange => 'Tap to change';

  @override
  String get invoiceDetails => 'Invoice Details';

  @override
  String get acServices => 'AC Services';

  @override
  String get serviceType => 'Service type';

  @override
  String get add => 'Add';

  @override
  String get additionalCharges => 'Additional Charges';

  @override
  String get acOutdoorBracket => 'AC Outdoor Bracket';

  @override
  String get bracketSubtitle => 'Bracket for outdoor unit mounting';

  @override
  String get bracketCharge => 'Bracket charge (SAR)';

  @override
  String get deliveryCharge => 'Delivery Charge';

  @override
  String get deliverySubtitle => 'Customer location >50 km away';

  @override
  String get deliveryChargeAmount => 'Delivery charge (SAR)';

  @override
  String get locationNote => 'Location / note (optional)';

  @override
  String get addServiceFirst =>
      'Add at least one AC service before submitting.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get activate => 'Activate';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get totalUnits => 'Total Units';

  @override
  String get date => 'Date';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeAutoDesc => 'Follow system dark/light setting';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDarkDesc => 'Arctic dark — easy on the eyes';

  @override
  String get themeLight => 'Light';

  @override
  String get themeLightDesc => 'Clean and bright for outdoor use';

  @override
  String get themeHighContrast => 'High Contrast';

  @override
  String get themeHighContrastDesc => 'Maximum readability, bold borders';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get company => 'Company';

  @override
  String get region => 'Region';

  @override
  String get saudiArabia => 'Saudi Arabia';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get total => 'Total';

  @override
  String get noTeamMembers => 'No team members yet';

  @override
  String get noMatchingMembers => 'No matching team members';

  @override
  String get searchByNameOrEmail => 'Search by name or email...';

  @override
  String get addTechnician => 'Add Technician';

  @override
  String get editTechnician => 'Edit Technician';

  @override
  String get deleteTechnician => 'Delete Technician';

  @override
  String deleteConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get deleteWarning => 'This action cannot be undone.';

  @override
  String get name => 'Name';

  @override
  String get role => 'Role';

  @override
  String get userCreated => 'User created successfully!';

  @override
  String get userUpdated => 'User updated successfully!';

  @override
  String get userDeleted => 'User deleted successfully!';

  @override
  String get usersActivated => 'Users activated';

  @override
  String get usersDeactivated => 'Users deactivated';

  @override
  String get bulkActivate => 'Activate Selected';

  @override
  String get bulkDeactivate => 'Deactivate Selected';

  @override
  String get bulkDelete => 'Delete Selected';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get inOut => 'In / Out';

  @override
  String get monthlySummary => 'Monthly Summary';

  @override
  String get todaysInOut => 'Today\'s In / Out';

  @override
  String get todaysEntries => 'Today\'s Entries';

  @override
  String get noEntriesToday => 'No entries today';

  @override
  String get addFirstEntry => 'Add your first IN or OUT above';

  @override
  String get inEarned => 'IN  (Earned)';

  @override
  String get outSpent => 'OUT  (Spent)';

  @override
  String get category => 'Category';

  @override
  String get amountSar => 'Amount (SAR)';

  @override
  String get remarksOptional => 'Remarks (optional)';

  @override
  String get saving => 'Saving...';

  @override
  String get addEarning => 'Add Earning';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get enterAmount => 'Enter an amount.';

  @override
  String get enterValidAmount => 'Enter a valid positive amount.';

  @override
  String get earned => 'IN';

  @override
  String get spent => 'OUT';

  @override
  String get profit => 'Profit';

  @override
  String get loss => 'Loss';

  @override
  String get newestFirst => 'Newest first';

  @override
  String get oldestFirst => 'Oldest first';

  @override
  String get copyInvoice => 'Copy Invoice #';

  @override
  String get viewInHistory => 'View in History';

  @override
  String get invoiceCopied => 'Invoice number copied!';

  @override
  String get newJob => 'New Job';

  @override
  String get submitAJob => 'Submit a Job';

  @override
  String get splits => 'Splits';

  @override
  String get windowAc => 'Window';

  @override
  String get standing => 'Standing';

  @override
  String get cassette => 'Cassette';

  @override
  String get uninstalls => 'Uninstalls';

  @override
  String get jobStatus => 'Job Status';

  @override
  String get jobsPerTechnician => 'Jobs per Technician';

  @override
  String get technicians => 'Technicians';

  @override
  String get recentPending => 'Recent Pending';

  @override
  String get invoice => 'Invoice';

  @override
  String get client => 'Client';

  @override
  String get units => 'Units';

  @override
  String get expensesSar => 'Expenses (SAR)';

  @override
  String get status => 'Status';

  @override
  String get sort => 'Sort';

  @override
  String get installations => 'Installations';

  @override
  String get earningsIn => 'Earnings (IN)';

  @override
  String get expensesOut => 'Expenses (OUT)';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get earningsBreakdown => 'Earnings Breakdown';

  @override
  String get expensesBreakdown => 'Expenses Breakdown';

  @override
  String get installationsByType => 'Installations by Type';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get history => 'History';

  @override
  String get searchByClientOrInvoice => 'Search by client or invoice...';

  @override
  String get searchByTechClientInvoice =>
      'Search by tech, client, or invoice...';

  @override
  String get exportAsPdf => 'Export as PDF';

  @override
  String nUnits(int count) {
    return '$count units';
  }

  @override
  String activeOfTotal(int active, int total) {
    return '$active / $total active';
  }

  @override
  String get exportToPdf => 'Export to PDF';

  @override
  String get exportToExcel => 'Export to Excel';

  @override
  String exportReady(int count) {
    return 'Export ready! $count jobs exported to Excel.';
  }

  @override
  String get couldNotExport =>
      'Couldn\'t create the export file. Please try again.';

  @override
  String get appSubtitle => 'Technician Management System';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String passwordResetSent(String email) {
    return 'Password reset email sent to $email';
  }

  @override
  String confirmDeleteUser(String name) {
    return 'This will deactivate $name and they won\'t be able to sign in. Continue?';
  }

  @override
  String get addMoreEarning => '+ Add Another Earning';

  @override
  String get addMoreExpense => '+ Add Another Expense';

  @override
  String get companies => 'Companies';

  @override
  String get addCompany => 'Add Company';

  @override
  String get editCompany => 'Edit Company';

  @override
  String get companyName => 'Company Name';

  @override
  String get invoicePrefix => 'Invoice Prefix';

  @override
  String get invoiceSuffix => 'Invoice Number';

  @override
  String get selectCompany => 'Select company (optional)';

  @override
  String get noCompany => 'No company';

  @override
  String get noCompaniesYet => 'No companies added yet';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get changeYourName => 'Change your display name';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get companyCreated => 'Company created successfully!';

  @override
  String get companyUpdated => 'Company updated successfully!';

  @override
  String get companyActivated => 'Company activated';

  @override
  String get companyDeactivated => 'Company deactivated';

  @override
  String get workExpenses => 'Work Expenses';

  @override
  String get homeExpenses => 'Home Expenses';

  @override
  String get catSplitAc => 'Split AC';

  @override
  String get catWindowAc => 'Window AC';

  @override
  String get catFreestandingAc => 'Freestanding AC';

  @override
  String get catCassetteAc => 'Cassette AC';

  @override
  String get catUninstallOldAc => 'Uninstallation (Old AC)';

  @override
  String get catFood => 'Food';

  @override
  String get catPetrol => 'Petrol';

  @override
  String get catPipes => 'Pipes';

  @override
  String get catTools => 'Tools';

  @override
  String get catTape => 'Tape';

  @override
  String get catInsulation => 'Insulation';

  @override
  String get catGas => 'Gas';

  @override
  String get catOtherConsumables => 'Other Consumables';

  @override
  String get catHouseRent => 'House Rent';

  @override
  String get catOther => 'Other';

  @override
  String get catInstalledBracket => 'Installed Bracket';

  @override
  String get catInstalledExtraPipe => 'Installed Extra Pipe';

  @override
  String get catOldAcRemoval => 'Old AC Removal';

  @override
  String get catOldAcInstallation => 'Old AC Installation';

  @override
  String get catSoldOldAc => 'Sold Old AC';

  @override
  String get catSoldScrap => 'Sold Scrap';

  @override
  String get catBreadRoti => 'Bread/Roti';

  @override
  String get catMeat => 'Meat';

  @override
  String get catChicken => 'Chicken';

  @override
  String get catTea => 'Tea';

  @override
  String get catSugar => 'Sugar';

  @override
  String get catRice => 'Rice';

  @override
  String get catVegetables => 'Vegetables';

  @override
  String get catCookingOil => 'Cooking Oil';

  @override
  String get catMilk => 'Milk';

  @override
  String get catSpices => 'Spices';

  @override
  String get catOtherGroceries => 'Other Groceries';
}
