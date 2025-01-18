import 'package:sqflite/sqflite.dart';

abstract class DbUser {
  // A string uniquely identifying this user among all other DbUsers.
  String get id;

  // Must be >0
  int get dbVersion;

  // Called when loading the database if the stored version for the given ID
  // is less than DbUser.dbVersion. Called when first creating the database
  // with oldVersion == 0
  Future<void> upgradeDb(DatabaseExecutor db, int oldVersion);
}
