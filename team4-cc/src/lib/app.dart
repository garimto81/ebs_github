// Root widget for ebs_cc.
//
// Determines startup screen: AT-00 Login → AT-01 Main (BS-05-00 §화면 카탈로그).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EbsCcApp extends ConsumerWidget {
  const EbsCcApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'EBS CC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      // TODO(BS-05-00): route based on auth state → AT-00 Login or AT-01 Main
      home: const _BootstrapScreen(),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('ebs_cc — bootstrap'),
      ),
    );
  }
}
