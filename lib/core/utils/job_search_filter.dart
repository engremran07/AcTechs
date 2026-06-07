import 'package:ac_techs/core/models/job_model.dart';
import 'package:ac_techs/core/models/user_model.dart';

/// Centralised search filter for job list screens.
/// Replaces the three copy-pasted _filter/_applyFilters lambdas in
/// approvals_screen, admin_all_jobs_screen, and job_history_screen.
///
/// Matches against:
///   - invoice number (contains, case-insensitive)
///   - Firestore document ID (exact prefix, case-insensitive)
///   - client name (contains)
///   - client contact / phone (digits-only match within stored digits)
///   - technician name (contains)
class JobSearchFilter {
  JobSearchFilter._();

  static List<JobModel> apply(List<JobModel> jobs, {required String query}) {
    if (query.isEmpty) return jobs;
    final q = query.trim().toLowerCase();
    final digits = q.replaceAll(RegExp(r'\D'), '');

    return jobs.where((j) {
      // Invoice number
      if (j.invoiceNumber.toLowerCase().contains(q)) return true;
      // Firestore document ID prefix
      if (j.id.toLowerCase().startsWith(q)) return true;
      // Client name
      if (j.clientName.toLowerCase().contains(q)) return true;
      // Tech name
      if (j.techName.toLowerCase().contains(q)) return true;
      // Client phone — digits-only comparison so '+966 554' matches '966554'
      if (digits.isNotEmpty) {
        final storedDigits = j.clientContact.replaceAll(RegExp(r'\D'), '');
        if (storedDigits.contains(digits)) return true;
      }
      return false;
    }).toList();
  }
}

/// Centralised search filter for user/technician list screens.
///
/// Matches against:
///   - name (contains, case-insensitive)
///   - email (contains)
///   - phone (digits-only match)
class UserSearchFilter {
  UserSearchFilter._();

  static List<UserModel> apply(List<UserModel> users, {required String query}) {
    if (query.isEmpty) return users;
    final q = query.trim().toLowerCase();
    final digits = q.replaceAll(RegExp(r'\D'), '');

    return users.where((u) {
      if (u.name.toLowerCase().contains(q)) return true;
      if (u.email.toLowerCase().contains(q)) return true;
      if (digits.isNotEmpty) {
        final storedDigits = u.phone.replaceAll(RegExp(r'\D'), '');
        if (storedDigits.contains(digits)) return true;
      }
      return false;
    }).toList();
  }
}
