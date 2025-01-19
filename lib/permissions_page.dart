import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:turnip_music/nav.dart';

Future<bool> checkAllPermissionsAvailable() async {
  if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
    return true;
  }

  final hasAudio = await Permission.audio.isGranted;
  return hasAudio;
}

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<StatefulWidget> createState() => PermissionsPageState();
}

class PermissionsPageState extends State<PermissionsPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: SafeArea(
        child: Center(
          child: Column(
            children: [
              Spacer(),
              Text(
                "Please enable the following permissions to continue:",
                style: Theme.of(context).primaryTextTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              FilledButton(
                onPressed: () async {
                  final hasAudio = await Permission.audio.request();
                  final hasAudioPermission = (hasAudio == PermissionStatus.granted);
                  if (hasAudioPermission) {
                    router.go(NavBarRoute.library.route);
                  }
                },
                child: Text("Access your audio library"),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
