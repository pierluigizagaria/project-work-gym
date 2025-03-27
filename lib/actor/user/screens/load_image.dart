import 'package:flutter/material.dart';

class ImageUploadPage extends StatelessWidget {
  const ImageUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Caricamento in corso..."),
          ],
        ),
      ),
    );
  }
}
