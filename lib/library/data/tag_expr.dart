// TODO: Tag expressions are stored as text(?) in a lisp-like ExprLang:
// - Leaf nodes are encoded as kind:id, with ~ preceding the kind for negation:
//  - album:1023
//    - i.e. select all within album 1023
//  - ~user:12
//    - i.e. select all which do *not* have user tag 12.
// - Joins are encoded inside parentheses, with ! preceding the kind for negation:
//  - (and album:1023 ~user:12)
//    - i.e. select all that are both (within album 1023, do *not* have user tag 12)
//  - (!or user:14 user:12)
//    - i.e. select all that are neither of (have user tag 14, have user tag 12)

abstract class TagExprNode {
  String encodeToExprLang();
}

enum TagExprLeafKind {
  user,
  album,
  artist;
}

class TagExprLeaf extends TagExprNode {
  // If this leaf represents (songs that are NOT tagged by kind:leafId)
  final bool not;
  final TagExprLeafKind kind;
  // The rowid of the user tag/album/artist/genre
  final int leafId;

  TagExprLeaf({
    required this.not,
    required this.kind,
    required this.leafId,
  });

  @override
  String encodeToExprLang() {
    return "${not ? '~' : ''}${kind.name}:$leafId";
  }
}

enum TagExprJoinKind {
  and,
  or;
}

class TagExprJoin extends TagExprNode {
  final bool not;
  final TagExprJoinKind kind;
  final List<TagExprNode> joined;

  TagExprJoin({
    required this.not,
    required this.kind,
    required this.joined,
  });

  @override
  String encodeToExprLang() {
    return "(${not ? '!' : ''}${kind.name} ${joined.map((n) => n.encodeToExprLang()).join(' ')})";
  }
}

extension type UserTagExprId(int id) {}

/// User-defined tag which applies implicitly to songs that fulfil the criteria shown in the expression.
class UserExprTag {
  // with UNIQUE constraint in the DB
  final String name;
  final String expr;
  // incremented every time the expression is changed
  final int exprVersion;

  UserExprTag({
    required this.name,
    required this.expr,
    required this.exprVersion,
  });
}

// and a join table of (SongId, UserTagExprId, exprVersion) for cached song<->expr lookup, performed in the background
// TODO the data repository should maintain a sensitivity list of (expr -> user tags, album tags, artist tags)
