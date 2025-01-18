import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:turnip_music/util/empty_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Library"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go("/library/import"),
          )
        ],
      ),
      body: EmptyPage(),
    );
  }
}

class LibraryImportPage extends StatelessWidget {
  const LibraryImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Import from..."),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go("/library"),
        ),
      ),
      body: EmptyPage(),
    );
  }
}
