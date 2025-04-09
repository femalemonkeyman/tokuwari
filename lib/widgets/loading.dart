import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(context) => Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      TextButton(onPressed: () => context.pop(), child: const Text("Escape?")),
      const Center(child: CircularProgressIndicator()),
    ],
  );
}
