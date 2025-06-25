//TODO settings

import 'package:flutter/material.dart';
import 'package:tokuwari/models/repo.dart';
import 'package:tokuwari/models/settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final box = Repo.i.settings;
  late Settings settings;

  @override
  void initState() {
    super.initState();
    settings = box.get(1) ?? Settings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Nsfw?'),
            value: settings.isNsfw,
            onChanged: (v) {
              setState(() {
                settings.isNsfw = v;
                box.put(settings);
              });
            },
          ),
        ],
      ),
    );
  }
}
