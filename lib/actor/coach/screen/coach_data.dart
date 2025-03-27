import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:random_color/random_color.dart';

import '../../../provider/category_provider.dart';

class CoachDataScreen extends StatelessWidget {
  const CoachDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    CategoryProvider cat =
        Provider.of<CategoryProvider>(context, listen: false);
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(cat.category!)
            .doc(userId)
            .snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
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
            String surname = userData['cognome'] ?? '';
            String email = userData['email'] ?? 'Email non disponibile';
            String indirizzo =
                userData['indirizzo'] ?? 'Indirizzo non disponibile';
            String telefono =
                userData['telefono'] ?? 'Telefono non disponibile';
            // Altri dati specifici dell'utente

            return Scaffold(
              appBar: screenWidth > 500
                  ? AppBar(
                      title: const Center(
                          child:
                              SizedBox(width: 800, child: Text('I Miei Dati'))),
                    )
                  : AppBar(
                      title: const Text('I Miei Dati'),
                    ),
              body: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  if (constraints.maxWidth > 500) {
                    return Center(
                      child: Container(
                        width: 800,
                        decoration: const BoxDecoration(
                          border: Border.symmetric(
                            vertical:
                                BorderSide(color: Colors.grey, width: 2.0),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Informazioni utente
                                      ListTile(
                                        leading: CircleAvatar(
                                          radius: 30,
                                          backgroundColor:
                                              _generateRandomColor(),
                                          child: Text(
                                            (displayName.isNotEmpty
                                                    ? displayName[0]
                                                    : '') +
                                                (surname.isNotEmpty
                                                    ? surname[0]
                                                    : ''),
                                            style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.white),
                                          ),
                                        ),
                                        title: Text('$displayName $surname',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        subtitle: Text('Email: $email',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      ),
                                      const SizedBox(height: 16),
                                      // Separatore visivo
                                      Divider(
                                          color: Colors.grey.shade300,
                                          thickness: 1),
                                      // Altri dati specifici dell'utente
                                      _buildUserDetailTile(Icons.person, 'Nome',
                                          '$displayName $surname'),
                                      const SizedBox(height: 8),
                                      _buildUserDetailTile(
                                          Icons.email, 'Email', email),
                                      // Aggiungi altre righe per gli altri dati specifici dell'utente

                                      const SizedBox(height: 8),
                                      _buildUserDetailTile(
                                          Icons.home, 'Indirizzo', indirizzo),
                                      const SizedBox(height: 8),
                                      _buildUserDetailTile(
                                          Icons.phone, 'Telefono', telefono),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Informazioni utente
                            ListTile(
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundColor: _generateRandomColor(),
                                child: Text(
                                  (displayName.isNotEmpty
                                          ? displayName[0]
                                          : '') +
                                      (surname.isNotEmpty ? surname[0] : ''),
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
                            const SizedBox(height: 16),
                            // Separatore visivo
                            Divider(color: Colors.grey.shade300, thickness: 1),
                            // Altri dati specifici dell'utente
                            _buildUserDetailTile(
                                Icons.person, 'Nome', '$displayName $surname'),
                            const SizedBox(height: 8),
                            _buildUserDetailTile(Icons.email, 'Email', email),
                            // Aggiungi altre righe per gli altri dati specifici dell'utente

                            const SizedBox(height: 8),
                            _buildUserDetailTile(
                                Icons.home, 'Indirizzo', indirizzo),
                            const SizedBox(height: 8),
                            _buildUserDetailTile(
                                Icons.phone, 'Telefono', telefono),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          } else {
            return const Center(
              child: Text('Dati dell\'utente non trovati.'),
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

  Widget _buildUserDetailTile(IconData iconData, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(iconData),
          title:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(value),
        ),
        const Divider(height: 1), // Add a horizontal line separator
      ],
    );
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
}
