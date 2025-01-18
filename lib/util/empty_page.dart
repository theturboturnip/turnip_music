import 'package:flutter/widgets.dart';

class EmptyPage extends StatelessWidget {
  const EmptyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Text("Empty page, nothing here"),
    );
  }
}
