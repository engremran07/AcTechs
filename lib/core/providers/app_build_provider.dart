import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final appBuildNumberProvider = FutureProvider<int>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final parsed = int.tryParse(info.buildNumber);
  return parsed == null || parsed < 1 ? 1 : parsed;
});
