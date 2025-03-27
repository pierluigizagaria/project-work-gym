import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordResetPage extends StatelessWidget {
  const PasswordResetPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    String email = ''; // Variabile per l'indirizzo email

    void resetPassword() async {
      if (email.isNotEmpty) {
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Email di reset della password inviata con successo.'),
          ));
        } on FirebaseAuthException catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.message ??
                'Errore durante l\'invio dell\'email di reset della password.'),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Inserisci l\'indirizzo email per il reset della password.'),
        ));
      }
    }

    return Scaffold(
      appBar: screenWidth > 500
          ? AppBar(
              title: const Center(
                  child:
                      SizedBox(width: 800, child: Text('Recupera Password'))),
            )
          : AppBar(
              title: const Text('Recupera Password'),
            ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth > 500) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 800,
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: Colors.grey, width: 2.0),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Indirizzo Email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Inserisci un indirizzo email valido';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          email = value;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: resetPassword,
                        child: const Text('Invia Email di Recupero Password'),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Indirizzo Email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty ||
                          !value.contains('@')) {
                        return 'Inserisci un indirizzo email valido';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      email = value;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: resetPassword,
                    child: const Text('Invia Email di Recupero Password'),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
