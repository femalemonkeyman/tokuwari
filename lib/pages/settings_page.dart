//TODO settings

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:tokuwari/models/settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final isar = Isar.get(name: "tokudb", schemas: [SettingsSchema]);
  late var settings = isar.settings.get(1) ?? Settings();

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Nsfw?'),
            value: settings.isNsfw,
            onChanged: (v) {
              setState(() {
                isar.write((isar) {
                  settings.isNsfw = v;
                  isar.settings.put(settings);
                });
              });
            },
          ),
        ],
      ),
    );
  }
}
