import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turnip_music/library/library.dart';
import 'package:turnip_music/nav.dart';
import 'package:turnip_music/permissions_page.dart';
import 'package:turnip_music/repos/db/db_repo.dart';
import 'package:turnip_music/repos/plugin_repo.dart';

Future<void> main() async {
  // Use sqflite on MacOS/iOS/Android.
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    throw "This application requires SQFlite and does not currently enable that on web.";
  } else {
    // Use ffi on Linux and Windows.
    if (Platform.isLinux || Platform.isWindows) {
      databaseFactory = databaseFactoryFfi;
      sqfliteFfiInit();
    }
  }

  // Pick a path for the database. In debug mode this may be in an ephemeral directory such as a temp directory,
  // but it still needs to be a real file for the backup/restore functionality to work.

  late final String dbFolder;

  if (Platform.isAndroid) {
    dbFolder = await getDatabasesPath();
  } else if (Platform.isIOS || Platform.isMacOS) {
    dbFolder = (await getLibraryDirectory()).path;
  } else if (kDebugMode) {
    dbFolder = (await getTemporaryDirectory()).path;
  } else {
    dbFolder = (await getApplicationDocumentsDirectory()).path;
  }

  final dbPath = join(
    dbFolder,
    "turnip_music.db",
  );
  if (kDebugMode) {
    // truncate the file to clear the db
    await File(dbPath).openWrite().close();
  }

  final pluginRepo = PluginRepo.makePluginRepo(
    libraryPlugins: getLibraryPluginsForPlatform(),
  );
  final dbRepo = await DbRepo.createDatabase(
    dbPath,
    pluginRepo.dbUsers,
  );

  runApp(MyApp(
    dbRepo,
    pluginRepo,
    permissionsInitiallyAvailable: await checkAllPermissionsAvailable(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp(this.dbRepo, this.pluginRepo, {super.key, required this.permissionsInitiallyAvailable});

  final bool permissionsInitiallyAvailable;
  final DbRepo dbRepo;
  final PluginRepo pluginRepo;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (permissionsInitiallyAvailable) {
      router.go(NavBarRoute.library.route);
    }
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => dbRepo,
        ),
        RepositoryProvider(
          create: (context) => pluginRepo,
        ),
      ],
      // child: MultiBlocProvider(
      //   providers: [
      //     // TODO
      //   ],
      child: MaterialApp.router(
        title: 'Turnip Music',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: (kDebugMode) ? Colors.red : Colors.green),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
      // ),
    );
  }
}
