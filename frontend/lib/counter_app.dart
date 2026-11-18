import 'package:flutter/material.dart';

/// A minimal app used only for the widget test.
///
/// It shows a counter starting at 0 and a floating‑action button that
/// increments the counter. The test in `test/widget_test.dart` expects a
/// widget called `MyApp` with a `Text('0')` initially and a `+` icon that
/// updates the text to `1` when tapped.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _counter = 0;

  void _increment() {
    setState(() => _counter++);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Counter Demo')),
        body: Center(
          child: Text('$_counter', style: const TextStyle(fontSize: 48)),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _increment,
          tooltip: 'increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
