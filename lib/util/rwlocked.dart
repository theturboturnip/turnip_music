import 'package:mutex/mutex.dart';

/// Protected reference to T that can be use()-d or swap()-d.
/// Protected using a ReadWriteMutex, so multiple use()-rs can run concurrently
/// but use() will never run concurrently with a swap().
///
/// I found this useful in a previous project, which allowed database backups
/// by simply closing the database, copying the file bytes, and reopening the database
/// once the bytes had been copied into a new file.
/// Using this pattern, the database backup would swap() the old database for a reopened one
/// and we can be certain no-one will try the database during the backup process.
///
/// It's important to remember that even if this is holding e.g. a database,
/// which may have some concept of 'reads' and 'writes' while being use()-d,
/// this lock only protects reading/writing *the reference to the database*,
/// not the contents of the database.
class RwLocked<T> {
  RwLocked(this._item) : _mutex = ReadWriteMutex();

  T _item;
  final ReadWriteMutex _mutex;

  Future<TReturn> use<TReturn>(Future<TReturn> Function(T) callback) {
    return _mutex.protectRead(() => callback(_item));
  }

  Future<void> swap(Future<T> Function(T) consumeAndReplace) {
    return _mutex.protectWrite(() async {
      _item = await consumeAndReplace(_item);
    });
  }
}
