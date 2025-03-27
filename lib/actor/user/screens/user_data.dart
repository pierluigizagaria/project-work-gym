import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../provider/category_provider.dart';
import '../../../settings/auth.dart';

class MyDataScreen extends StatelessWidget {
  const MyDataScreen({super.key});

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
            String dataNascita =
                userData['data_nascita'] ?? 'Data di nascita non disponibile';
            String luogoNascita =
                userData['luogo_nascita'] ?? 'Luogo di nascita non disponibile';
            String indirizzo =
                userData['indirizzo'] ?? 'Indirizzo non disponibile';
            String telefono =
                userData['telefono'] ?? 'Telefono non disponibile';

            return Scaffold(
              appBar: screenWidth > 500
                  ? AppBar(
                      title: const Text('I Miei Dati'),
                    )
                  : AppBar(
                      title: const Center(
                          child:
                              SizedBox(width: 800, child: Text('I Miei Dati'))),
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
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildUserDetailTile(
                                    Icons.person,
                                    'Nome',
                                    '$displayName $surname',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildEditableUserDetailTile(
                                    Icons.email,
                                    'Email',
                                    email,
                                    () {
                                      _showEditDialog(context, 'Email', email);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _buildUserDetailTile(
                                    Icons.calendar_today,
                                    'Data di nascita',
                                    dataNascita,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildUserDetailTile(
                                    Icons.location_on,
                                    'Luogo di nascita',
                                    luogoNascita,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildEditableUserDetailTile(
                                    Icons.home,
                                    'Indirizzo',
                                    indirizzo,
                                    () {
                                      _showEditDialog(
                                          context, 'Indirizzo', indirizzo);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _buildEditableUserDetailTile(
                                    Icons.phone,
                                    'Telefono',
                                    telefono,
                                    () {
                                      _showEditDialog(
                                          context, 'Telefono', telefono);
                                    },
                                  ),
                                ],
                              ),
                            ),
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
                            _buildUserDetailTile(
                              Icons.person,
                              'Nome',
                              '$displayName $surname',
                            ),
                            const SizedBox(height: 8),
                            _buildEditableUserDetailTile(
                              Icons.email,
                              'Email',
                              email,
                              () {
                                _showEditDialog(context, 'Email', email);
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildUserDetailTile(
                              Icons.calendar_today,
                              'Data di nascita',
                              dataNascita,
                            ),
                            const SizedBox(height: 8),
                            _buildUserDetailTile(
                              Icons.location_on,
                              'Luogo di nascita',
                              luogoNascita,
                            ),
                            const SizedBox(height: 8),
                            _buildEditableUserDetailTile(
                              Icons.home,
                              'Indirizzo',
                              indirizzo,
                              () {
                                _showEditDialog(
                                    context, 'Indirizzo', indirizzo);
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildEditableUserDetailTile(
                              Icons.phone,
                              'Telefono',
                              telefono,
                              () {
                                _showEditDialog(context, 'Telefono', telefono);
                              },
                            ),
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

  Widget _buildUserDetailTile(
    IconData iconData,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(iconData),
          title:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(value),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildEditableUserDetailTile(
    IconData iconData,
    String label,
    String value,
    VoidCallback? onPressed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(iconData),
          title:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(value),
          trailing: onPressed != null
              ? IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onPressed,
                )
              : null,
        ),
        const Divider(height: 1),
      ],
    );
  }

  void _showEditDialog(BuildContext context, String label, String value) {
    TextEditingController textController = TextEditingController(text: value);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifica $label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label == 'Email')
                const Text(
                    'Dopo aver cambiato l\'email, effettuerai il logout automatico e dovrai effettuare nuovamente il login.'),
              TextField(
                controller: textController,
                decoration: InputDecoration(labelText: label),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                // Get the new value from the textController
                String newValue = textController.text;
                if (label == 'Email') {
                  // Update Firestore first
                  _updateFirestoreField(label.toLowerCase(), newValue);

                  // Then update Firebase Authentication email
                  await _updateEmail(context, newValue);

                  // Logout the user after email update
                  // ignore: use_build_context_synchronously
                  _logout(context);
                } else {
                  _updateFirestoreField(label.toLowerCase(), newValue);
                }
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _updateFirestoreField(String field, String newValue) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .update({field: newValue}).then((_) {
        // Data updated successfully
        // You can reload the page here to reflect the changes
      }).catchError((error) {
        // ignore: avoid_print
        print('Error updating $field: $error');
        // Handle the error here
      });
    }
  }

  Future<void> _updateEmail(BuildContext context, String newEmail) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Update the email on Firebase Authentication
        await user.updateEmail(newEmail);

        // Success: Email updated on Firebase Authentication
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email aggiornata con successo'),
          ),
        );
      } catch (error) {
        // ignore: avoid_print
        print('Errore durante l\'aggiornamento dell\'email: $error');
        // Handle the error here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Errore durante l\'aggiornamento dell\'email: $error'),
          ),
        );
      }
    }
  }

  void _logout(BuildContext context) {
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
}
