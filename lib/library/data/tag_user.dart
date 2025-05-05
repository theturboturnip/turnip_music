extension type UserTagId(int raw) {}

/// User-defined tag which can be applied directly to songs.
class UserTag {
  // with UNIQUE constraint in the DB
  final String name;

  UserTag({
    required this.name,
  });
}

// and a join table of (SongId, UserTagId) for manual associations
