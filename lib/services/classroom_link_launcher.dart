import 'classroom_link_launcher_stub.dart'
    if (dart.library.io) 'classroom_link_launcher_io.dart'
    if (dart.library.html) 'classroom_link_launcher_web.dart';

Future<bool> openClassroomLink(Uri uri) {
  return openClassroomLinkForPlatform(uri);
}
