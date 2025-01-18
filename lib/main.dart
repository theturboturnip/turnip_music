import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turnip_music/library/data/db.dart';
import 'package:turnip_music/library/library.dart';
import 'package:turnip_music/nav.dart';
import 'package:turnip_music/repos/db/db_repo.dart';
import 'package:turnip_music/repos/db/db_user.dart';

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

  final libraryDbUser = LibraryDbUser();
  final libraryPlugins = getLibraryPluginsForPlatform();

  var dbUsers = <String, DbUser>{
    for (var dbUser in [
      libraryDbUser,
      ...libraryPlugins,
    ])
      dbUser.id: dbUser
  };

  final dbRepo = await DbRepo.createDatabase(dbPath, dbUsers);

  runApp(MyApp(dbRepo: dbRepo));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.dbRepo});

  final DbRepo dbRepo;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => dbRepo,
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
