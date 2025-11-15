import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Eski NewMatchScreen - Yeni CreateMatchScreen'e yönlendiriyor
class NewMatchScreen extends StatelessWidget {
  const NewMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Yeni ekrana yönlendir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offNamed('/create_match');
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
