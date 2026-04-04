import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/routing/app_router.dart';

void main() {
  test('unauthenticated users are redirected to login', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/splash',
      isAuthLoading: false,
      isLoggedIn: false,
      currentUser: const AsyncData(null),
      approvalConfig: ApprovalConfig.defaults(),
      appBuild: 7,
    );

    expect(redirect, '/login');
  });

  test('technicians can open AC installations route', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/tech/ac-installs',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(uid: 'tech-1', name: 'Tech One', email: 'tech@example.com'),
      ),
      approvalConfig: ApprovalConfig.defaults(),
      appBuild: 7,
    );

    expect(redirect, isNull);
  });

  test('inactive users are redirected back to login', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/tech',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(
          uid: 'tech-1',
          name: 'Tech One',
          email: 'tech@example.com',
          isActive: false,
        ),
      ),
      approvalConfig: ApprovalConfig.defaults(),
      appBuild: 7,
    );

    expect(redirect, '/login');
  });

  test('minimum build gate holds on splash until app build loads', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/tech',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(uid: 'tech-1', name: 'Tech One', email: 'tech@example.com'),
      ),
      approvalConfig: const ApprovalConfig(
        jobApprovalRequired: false,
        sharedJobApprovalRequired: false,
        inOutApprovalRequired: false,
        enforceMinimumBuild: true,
        minSupportedBuildNumber: 99,
        lockedBeforeDate: null,
      ),
      appBuild: null,
    );

    expect(redirect, '/splash');
  });

  test('minimum build gate redirects outdated builds', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/tech',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(uid: 'tech-1', name: 'Tech One', email: 'tech@example.com'),
      ),
      approvalConfig: const ApprovalConfig(
        jobApprovalRequired: false,
        sharedJobApprovalRequired: false,
        inOutApprovalRequired: false,
        enforceMinimumBuild: true,
        minSupportedBuildNumber: 9,
        lockedBeforeDate: null,
      ),
      appBuild: 7,
    );

    expect(redirect, '/update-required');
  });

  test('admin users are redirected away from technician routes', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/tech/ac-installs',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(
          uid: 'admin-1',
          name: 'Admin',
          email: 'admin@example.com',
          role: 'admin',
        ),
      ),
      approvalConfig: ApprovalConfig.defaults(),
      appBuild: 7,
    );

    expect(redirect, '/admin');
  });
}
