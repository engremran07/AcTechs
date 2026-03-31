class AppConstants {
  AppConstants._();

  static const String appName = 'AC Techs';
  static const String firebaseProject = 'actechs-d415e';

  // Collections
  static const String usersCollection = 'users';
  static const String jobsCollection = 'jobs';
  static const String expensesCollection = 'expenses';
  static const String earningsCollection = 'earnings';
  static const String companiesCollection = 'companies';

  static const String expenseTypeWork = 'work';
  static const String expenseTypeHome = 'home';

  // AC Service Types — what a tech records per invoice
  static const List<String> acUnitTypes = [
    'Split AC',
    'Window AC',
    'Freestanding AC',
    'Cassette AC',
    'Uninstallation (Old AC)',
  ];

  // Expense Categories
  static const List<String> expenseCategories = [
    'Food',
    'Petrol',
    'Pipes',
    'Tools',
    'Tape',
    'Insulation',
    'Gas',
    'Other Consumables',
    'House Rent',
    'Other',
  ];

  // Earning Categories (IN — money earned from services / sales)
  static const List<String> earningCategories = [
    'Installed Bracket',
    'Installed Extra Pipe',
    'Old AC Removal',
    'Old AC Installation',
    'Sold Old AC',
    'Sold Scrap',
    'Other',
  ];

  // Home Chore Expense Categories (personal groceries etc.)
  static const List<String> homeChoreCategories = [
    'Bread/Roti',
    'Meat',
    'Chicken',
    'Tea',
    'Sugar',
    'Rice',
    'Vegetables',
    'Cooking Oil',
    'Milk',
    'Spices',
    'Other Groceries',
  ];

  // Job Status
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleTechnician = 'technician';

  // Language Codes
  static const String langEnglish = 'en';
  static const String langUrdu = 'ur';
  static const String langArabic = 'ar';

  // Free Tier Limits
  static const int maxFirestoreReadsPerDay = 50000;
  static const int maxFirestoreWritesPerDay = 20000;
}
