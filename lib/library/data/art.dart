import 'dart:typed_data';

extension type ArtId(int raw) {
  const ArtId.c(this.raw);
}

class Art {
  final Uint8List data;

  Art({required this.data});
}
