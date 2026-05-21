import 'package:firebase_database/firebase_database.dart';

class FirebaseDatabaseService {
  FirebaseDatabaseService({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  DatabaseReference get students => _database.ref('STUDENTS');
  DatabaseReference get admins => _database.ref('ADMIN');
  DatabaseReference get classrooms => _database.ref('CLASSROOMS');

  DatabaseReference notesFolder(String storageFolder) {
    return _database.ref(storageFolder);
  }
}
