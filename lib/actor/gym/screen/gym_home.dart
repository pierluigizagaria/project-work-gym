import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:univeristy/provider/gym_provider.dart';
import '../../../provider/category_provider.dart';

class GymHome extends StatefulWidget {
  const GymHome({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GymHomeState();
  }
}

class _GymHomeState extends State<GymHome> {
  String _name = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    CategoryProvider cat =
        Provider.of<CategoryProvider>(context, listen: false);
    GymProvider gymProv = Provider.of<GymProvider>(context, listen: false);

    User? user = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance
        .collection(cat.category!)
        .doc(user!.uid)
        .get()
        .then(
      (userData) {
        setState(() {
          gymProv.gym.uid = user.uid;
          gymProv.gym.nome = userData.data()?['nome'];
          gymProv.gym.user = userData.data()?['users'];
          gymProv.gym.email = userData.data()?['email'];
          gymProv.gym.password = userData.data()?['password'];
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: screenWidth > 500
          ? AppBar(
              title: Center(
                child: SizedBox(
                  width: 600,
                  child: Card(
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Cerca...',
                      ),
                      onChanged: (val) {
                        setState(() {
                          _name = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
              actions: const [],
            )
          : AppBar(
              title: Card(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Cerca...',
                  ),
                  onChanged: (val) {
                    setState(() {
                      _name = val;
                    });
                  },
                ),
              ),
              actions: const [],
            ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 500) {
            return Center(
              child: Container(
                decoration: const BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                ),
                width: 800,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                          16.0, 16.0, 16.0, 8.0), // Reduced bottom padding
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Align text to the left
                        children: [],
                      ),
                    ),
                    Expanded(
                      child: returnUser(),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                      16.0, 16.0, 16.0, 8.0), // Reduced bottom padding
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align text to the left
                    children: [
                      // Add a Divider
                    ],
                  ),
                ),
                Expanded(
                  child: returnUser(),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  void permissionUser(String id, BuildContext context) async {
    GymProvider gymProv = Provider.of<GymProvider>(context, listen: false);

    final isExisting = gymProv.gym.user.contains(id);

    try {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('gym').doc(gymProv.gym.uid);

      if (isExisting) {
        setState(() {
          gymProv.gym.user.remove(id);
        });

        // Rimuovi l'elemento dall'array usando l'operatore FieldValue.arrayRemove
        await userRef.update({
          'users': FieldValue.arrayRemove([id]),
        });
      } else {
        setState(() {
          gymProv.gym.user.add(id);
        });

        // Aggiungi il nuovo elemento all'array usando l'operatore FieldValue.arrayUnion
        await userRef.update({
          'users': FieldValue.arrayUnion([id]),
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Errore durante l\'aggiornamento del documento utente: $e');
    }

    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }
  }

  Widget returnUser() {
    GymProvider? gymProv = Provider.of<GymProvider>(context, listen: false);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 500) {
          if (gymProv.gym.uid.isNotEmpty) {
            // Costruisci il Scaffold solo se gymProv.gym.uid è valido
            return Scaffold(
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  String enteredEmail = "";
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Aggiungi mail alla palestra'),
                        content: TextField(
                          onChanged: (value) {
                            enteredEmail = value;
                          },
                          decoration: const InputDecoration(
                            hintText: 'Inserisci l\'indirizzo email',
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Annulla'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('Aggiungi'),
                            onPressed: () async {
                              // Esegui il controllo dell'email e l'aggiunta dell'utente alla palestra qui
                              // Assumiamo che tu abbia una funzione "addUserToGym" che esegue questa operazione.

                              // Controllo se l'email è già presente nel database degli utenti
                              QuerySnapshot querySnapshot =
                                  await FirebaseFirestore.instance
                                      .collection('user')
                                      .where('email', isEqualTo: enteredEmail)
                                      .get();

                              if (querySnapshot.docs.isNotEmpty) {
                                // L'email è presente nel database degli utenti
                                // Ottieni l'ID del primo documento corrispondente (presumendo che ci sia una sola corrispondenza)
                                String userId = querySnapshot.docs.first.id;

                                // Aggiungi l'ID dell'utente all'array "users" nella tabella "gym"

                                await FirebaseFirestore.instance
                                    .collection('gym')
                                    .doc(gymProv.gym.uid)
                                    .update({
                                  'users': FieldValue.arrayUnion([userId]),
                                });

                                // ignore: use_build_context_synchronously
                                Navigator.of(context)
                                    .pop(); // Chiudi l'AlertDialog
                              } else {
                                // L'email non è stata trovata nel database degli utenti
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Questa email non è presente nel database degli utenti'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Icon(Icons.add),
              ),
              body: Center(
                child: SizedBox(
                  width: 800,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('gym')
                        .doc(gymProv.gym.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(child: Text('Dati non trovati'));
                      }

                      final gymData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final usersList = gymData['users'] as List<dynamic>;

                      // Rimuovi valori nulli o vuoti dalla lista
                      final cleanedUsersList = usersList
                          .where(
                              (userId) => userId != null && userId.isNotEmpty)
                          .toList();

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: cleanedUsersList.length,
                              itemBuilder: (context, index) {
                                final userId = cleanedUsersList[index];

                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('user')
                                      .doc(userId)
                                      .get(),
                                  builder: (context, userSnapshot) {
                                    if (userSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    } else if (!userSnapshot.hasData ||
                                        !userSnapshot.data!.exists) {
                                      return Container(); // Utente non trovato, quindi non viene mostrato
                                    }

                                    final userData = userSnapshot.data!.data()
                                        as Map<String, dynamic>;
                                    final nome = userData['nome'] as String;
                                    final cognome =
                                        userData['cognome'] as String;
                                    final email = userData['email'] as String;

                                    if (_name.isEmpty ||
                                        nome.toLowerCase().startsWith(_name) ||
                                        cognome
                                            .toLowerCase()
                                            .startsWith(_name) ||
                                        email.toLowerCase().startsWith(_name)) {
                                      return ListTile(
                                        title: Text('$nome $cognome',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        subtitle: Text(email,
                                            style:
                                                const TextStyle(fontSize: 16)),
                                        trailing: ElevatedButton(
                                          onPressed: () {
                                            // Esegui azione per questo utente
                                            permissionUser(userId, context);
                                            ScaffoldMessenger.of(context)
                                                .clearSnackBars();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content:
                                                  Text('Azione completata'),
                                            ));
                                          },
                                          child: const Text("Rimuovi"),
                                        ),
                                      );
                                    }

                                    return Container();
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          } else {
            // Gestisci il caso in cui gymProv.gym.uid sia nullo o vuoto
            return const CircularProgressIndicator(); // o qualsiasi altro comportamento di fallback
          }
        } else {
          if (gymProv.gym.uid.isNotEmpty) {
            // Costruisci il Scaffold solo se gymProv.gym.uid è valido
            return Scaffold(
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  String enteredEmail = "";
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Aggiungi mail alla palestra'),
                        content: TextField(
                          onChanged: (value) {
                            enteredEmail = value;
                          },
                          decoration: const InputDecoration(
                            hintText: 'Inserisci l\'indirizzo email',
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Annulla'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('Aggiungi'),
                            onPressed: () async {
                              // Esegui il controllo dell'email e l'aggiunta dell'utente alla palestra qui
                              // Assumiamo che tu abbia una funzione "addUserToGym" che esegue questa operazione.

                              // Controllo se l'email è già presente nel database degli utenti
                              QuerySnapshot querySnapshot =
                                  await FirebaseFirestore.instance
                                      .collection('user')
                                      .where('email', isEqualTo: enteredEmail)
                                      .get();

                              if (querySnapshot.docs.isNotEmpty) {
                                // L'email è presente nel database degli utenti
                                // Ottieni l'ID del primo documento corrispondente (presumendo che ci sia una sola corrispondenza)
                                String userId = querySnapshot.docs.first.id;

                                // Aggiungi l'ID dell'utente all'array "users" nella tabella "gym"
                                await FirebaseFirestore.instance
                                    .collection('gym')
                                    .doc(gymProv.gym.uid)
                                    .update({
                                  'users': FieldValue.arrayUnion([userId]),
                                });

                                // ignore: use_build_context_synchronously
                                Navigator.of(context)
                                    .pop(); // Chiudi l'AlertDialog
                              } else {
                                // L'email non è stata trovata nel database degli utenti
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Questa email non è presente nel database degli utenti'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Icon(Icons.add),
              ),
              body: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('gym')
                    .doc(gymProv.gym.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('Dati non trovati'));
                  }

                  final gymData = snapshot.data!.data() as Map<String, dynamic>;
                  final usersList = gymData['users'] as List<dynamic>;

                  // Rimuovi valori nulli o vuoti dalla lista
                  final cleanedUsersList = usersList
                      .where((userId) => userId != null && userId.isNotEmpty)
                      .toList();

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: cleanedUsersList.length,
                          itemBuilder: (context, index) {
                            final userId = cleanedUsersList[index];

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('user')
                                  .doc(userId)
                                  .get(),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (!userSnapshot.hasData ||
                                    !userSnapshot.data!.exists) {
                                  return Container(); // Utente non trovato, quindi non viene mostrato
                                }

                                final userData = userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                                final nome = userData['nome'] as String;
                                final cognome = userData['cognome'] as String;
                                final email = userData['email'] as String;

                                if (_name.isEmpty ||
                                    nome.toLowerCase().startsWith(_name) ||
                                    cognome.toLowerCase().startsWith(_name) ||
                                    email.toLowerCase().startsWith(_name)) {
                                  return ListTile(
                                    title: Text('$nome $cognome',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(email,
                                        style: const TextStyle(fontSize: 16)),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        // Esegui azione per questo utente
                                        permissionUser(userId, context);
                                        ScaffoldMessenger.of(context)
                                            .clearSnackBars();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text('Azione completata'),
                                        ));
                                      },
                                      child: const Text("Rimuovi"),
                                    ),
                                  );
                                }

                                return Container();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          } else {
            // Gestisci il caso in cui gymProv.gym.uid sia nullo o vuoto
            return const CircularProgressIndicator(); // o qualsiasi altro comportamento di fallback
          }
        }
      },
    );
  }
}
