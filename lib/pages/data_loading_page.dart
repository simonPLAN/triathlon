import 'package:flutter/material.dart';

import '../constants/sports.dart';
import '../services/event_data.dart';
import 'home_page.dart';

class DataLoadingPage extends StatefulWidget {
  const DataLoadingPage({super.key});

  @override
  State<DataLoadingPage> createState() => _DataLoadingPageState();
}

class _DataLoadingPageState extends State<DataLoadingPage> {
  late final Future<void> loadingFuture;

  @override
  void initState() {
    super.initState();
    loadingFuture = EventData.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: loadingFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('${AppTexts.errorLoading}${snapshot.error}'),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const HomePage();
      },
    );
  }
}
