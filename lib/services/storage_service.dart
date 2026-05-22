import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Reference classroomNotesFolder(String classroomId) {
    return _storage.ref('${classroomId}_NOTES');
  }

  Reference noteFile(String storageFolder, int noteId) {
    return _storage.ref('$storageFolder/$noteId');
  }
}
