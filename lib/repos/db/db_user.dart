import 'package:sqflite/sqflite.dart';

abstract class DbUser {
  // A string uniquely identifying this user among all other DbUsers.
  String get id;

  // Must have >=1 value
  List<Future<void> Function(DatabaseExecutor)> get migrations;
}
