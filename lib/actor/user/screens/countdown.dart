import 'package:flutter/material.dart';

class CountdownPage extends StatefulWidget {
  final int initialCountdownSeconds;

  const CountdownPage({Key? key, required this.initialCountdownSeconds})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CountdownPageState createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  late int countdownSeconds;
  late String countdownText;
  late Color backgroundColor;
  late bool isDisposed;

  @override
  void initState() {
    super.initState();
    countdownSeconds = widget.initialCountdownSeconds;
    countdownText = formatCountdownText(countdownSeconds);
    backgroundColor = Colors.green;
    isDisposed = false;
    startCountdown();
  }

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }

  void startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (countdownSeconds > 0 && !isDisposed) {
        setState(() {
          countdownSeconds--;
          countdownText = formatCountdownText(countdownSeconds);
        });
        startCountdown();
      } else {
        if (!isDisposed) {
          Navigator.pop(context);
        }
      }
    });
  }

  String formatCountdownText(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double calculateProgress() {
    return (widget.initialCountdownSeconds - countdownSeconds) /
        widget.initialCountdownSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: CircularProgressIndicator(
                strokeWidth: 10,
                value: calculateProgress(),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                backgroundColor: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              countdownText,
              style: const TextStyle(fontSize: 48, color: Colors.white),
            ),
            ElevatedButton(
              onPressed: () {
                // Questo gestore viene chiamato quando si preme il pulsante "Esci"
                Navigator.pop(context);
              },
              child: const Text(
                "Esci",
                style: TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
