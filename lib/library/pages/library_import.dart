import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turnip_music/library/importing.dart';
import 'package:turnip_music/library/library_plugin.dart';
import 'package:turnip_music/repos/db/db_repo.dart';
import 'package:turnip_music/repos/plugin_repo.dart';
import 'package:turnip_music/util/empty_page.dart';

typedef ImportSessionGenerator = Future<ImportSession> Function(DbRepo);

abstract class LibraryImportState {
  const LibraryImportState({required this.availablePlugins});

  final List<LibraryPlugin> availablePlugins;

  LibraryPlugin? get importer;
  ImportSessionGenerator? get sessionGenerator;
}

class InitialLibraryImportState extends LibraryImportState {
  const InitialLibraryImportState({
    required super.availablePlugins,
  });

  @override
  LibraryPlugin? get importer => null;
  @override
  ImportSessionGenerator? get sessionGenerator => null;
}

class LibraryImportStateFromImporter extends LibraryImportState {
  @override
  final LibraryPlugin importer;
  @override
  final ImportSessionGenerator? sessionGenerator;

  const LibraryImportStateFromImporter({
    required super.availablePlugins,
    required this.importer,
    required this.sessionGenerator,
  });
}

class LibraryImportEvent {}

class LibrarySelectImporterEvent extends LibraryImportEvent {
  final LibraryPlugin importer;

  LibrarySelectImporterEvent({required this.importer});
}

class LibrarySelectSongsToImportEvent extends LibraryImportEvent {
  final ImportSessionGenerator sessionGenerator;

  LibrarySelectSongsToImportEvent({required this.sessionGenerator});
}

class LibraryImportBloc extends Bloc<LibraryImportEvent, LibraryImportState> {
  LibraryImportBloc(PluginRepo plugins) : super(InitialLibraryImportState(availablePlugins: plugins.libraryPlugins.toList())) {
    on<LibrarySelectImporterEvent>((event, emit) {
      if (state.importer != event.importer) {
        emit(LibraryImportStateFromImporter(
          availablePlugins: plugins.libraryPlugins.toList(),
          importer: event.importer,
          sessionGenerator: null,
        ));
      }
    });
    on<LibrarySelectSongsToImportEvent>((event, emit) {
      emit(LibraryImportStateFromImporter(
        availablePlugins: plugins.libraryPlugins.toList(),
        importer: state.importer!,
        sessionGenerator: event.sessionGenerator,
      ));
    });
  }
}

class LibraryImportPage extends StatelessWidget {
  const LibraryImportPage({super.key});

  Widget _buildImporterSelector(BuildContext context, LibraryImportState state) {
    // return ExpansionTile(
    //   leading: state.importer?.icon,
    //   title: Text(state.importer?.userVisibleName ?? "Select Importer"),
    //   initiallyExpanded: state.importer == null,
    //   children: state.availablePlugins.map(toElement),
    // );
    return DropdownMenu<LibraryPlugin>(
      leadingIcon: state.importer?.icon,
      initialSelection: null,
      label: const Text("Select Importer Plugin"),
      onSelected: (value) {
        if (value != null) {
          context.read<LibraryImportBloc>().add(
                LibrarySelectImporterEvent(
                  importer: value,
                ),
              );
        }
      },
      dropdownMenuEntries: state.availablePlugins
          .map(
            (plugin) => DropdownMenuEntry(
              value: plugin,
              label: plugin.userVisibleName,
              leadingIcon: plugin.icon,
            ),
          )
          .toList(),
      expandedInsets: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Import from..."),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocProvider(
        create: (context) => LibraryImportBloc(context.read<PluginRepo>()),
        child: BlocBuilder<LibraryImportBloc, LibraryImportState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: _buildImporterSelector(context, state),
                ),
                Expanded(child: state.importer?.buildSelectSongSetsToImportWidget(context) ?? EmptyPage()),
                FilledButton(
                  onPressed: state.sessionGenerator == null
                      ? null
                      : () async {
                          final session = await state.sessionGenerator!(context.read<DbRepo>());
                          if (context.mounted) {
                            context.go("/library/import/finalize", extra: session);
                          }
                        },
                  child: const Text("Select Songs"),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
