//TODO settings

import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  @override
  Widget build(context) {
    return const Scaffold(
      body: Column(
        children: [
          BackButton(),
          Placeholder(),
        ],
      ),
    );
  }
}
