import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

Future<bool> openClassroomLinkForPlatform(Uri uri) async {
  if (Platform.isWindows) {
    await Process.start('explorer.exe', [
      uri.toString(),
    ], mode: ProcessStartMode.detached);
    return true;
  }

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
