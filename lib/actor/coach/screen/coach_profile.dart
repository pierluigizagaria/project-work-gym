import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:random_color/random_color.dart';

import '../../../provider/category_provider.dart';
import '../../../settings/auth.dart';
import 'coach_data.dart';

class CoachProfile extends StatelessWidget {
  const CoachProfile({super.key});

  @override
  Widget build(BuildContext context) {
    CategoryProvider cat =
        Provider.of<CategoryProvider>(context, listen: false);
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 500) {
            return Center(
              child: Container(
                width: 800,
                decoration: const BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(cat.category!)
                      .doc(userId)
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Errore durante il recupero dei dati'),
                      );
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      Map<String, dynamic> userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      String displayName = userData['nome'] ?? 'Nome Utente';
                      String surname = userData['cognome'] ?? 'Cognome';
                      String email =
                          userData['email'] ?? 'Email non disponibile';

                      // Genera un colore casuale, escludendo il bianco e il nero
                      Color randomColor = _generateRandomColor();

                      // Ottieni le iniziali del nome e cognome
                      String initials =
                          (displayName.isNotEmpty ? displayName[0] : '') +
                              (surname.isNotEmpty ? surname[0] : '');

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Informazioni utente
                            ListTile(
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundColor: randomColor,
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.white),
                                ),
                              ),
                              title: Text('$displayName $surname',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text('Email: $email',
                                  style: const TextStyle(fontSize: 14)),
                            ),
                            const SizedBox(height: 8),
                            Divider(color: Colors.grey.shade300, thickness: 1),
                            // Voci separate
                            _buildProfileListItem(Icons.person, 'I miei dati',
                                () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const CoachDataScreen()));
                            }),

                            Divider(color: Colors.grey.shade300, thickness: 1),
                            _buildProfileListItem(Icons.logout, 'Esci', () {
                              _signOut(
                                  context); // Azione da eseguire al tocco di "Esci"
                            }),
                            Divider(color: Colors.grey.shade300, thickness: 1),
                          ],
                        ),
                      );
                    } else {
                      return const Center(
                        child: Text('Dati dell\'utente non trovati.'),
                      );
                    }
                  },
                ),
              ),
            );
          } else {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(cat.category!)
                  .doc(userId)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Errore durante il recupero dei dati'),
                  );
                }

                if (snapshot.hasData && snapshot.data != null) {
                  Map<String, dynamic> userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  String displayName = userData['nome'] ?? 'Nome Utente';
                  String surname = userData['cognome'] ?? 'Cognome';
                  String email = userData['email'] ?? 'Email non disponibile';

                  // Genera un colore casuale, escludendo il bianco e il nero
                  Color randomColor = _generateRandomColor();

                  // Ottieni le iniziali del nome e cognome
                  String initials =
                      (displayName.isNotEmpty ? displayName[0] : '') +
                          (surname.isNotEmpty ? surname[0] : '');

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informazioni utente
                        ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor: randomColor,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                  fontSize: 20, color: Colors.white),
                            ),
                          ),
                          title: Text('$displayName $surname',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          subtitle: Text('Email: $email',
                              style: const TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(height: 8),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        // Voci separate
                        _buildProfileListItem(Icons.person, 'I miei dati', () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CoachDataScreen()));
                        }),

                        Divider(color: Colors.grey.shade300, thickness: 1),
                        _buildProfileListItem(Icons.logout, 'Esci', () {
                          _signOut(
                              context); // Azione da eseguire al tocco di "Esci"
                        }),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                    child: Text('Dati dell\'utente non trovati.'),
                  );
                }
              },
            );
          }
        },
      );
    } else {
      return const Center(
        child: Text(
            'Utente non autenticato. Effettua il login per visualizzare i dati.'),
      );
    }
  }

  Color _generateRandomColor() {
    // Genera un colore casuale
    RandomColor randomColor0 = RandomColor();
    Color randomColor;
    do {
      randomColor = randomColor0.randomColor();
    } while (_isColorSimilarToBlackOrWhite(randomColor));
    return randomColor;
  }

  bool _isColorSimilarToBlackOrWhite(Color color) {
    // Verifica se il colore è simile al nero o al bianco in base al contrasto
    final luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance < 0.2 || luminance > 0.8;
  }

  void _signOut(BuildContext context) {
    FirebaseAuth.instance.signOut().then((_) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const AuthScreen()));
    }).catchError((error) {
      if (error.code == 'email-already-in-use') {}
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Error')),
      );
    });
  }

  Widget _buildProfileListItem(
      IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
