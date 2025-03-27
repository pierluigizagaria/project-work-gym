import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:univeristy/actor/user/screens/bookings.dart';
import 'package:univeristy/actor/user/screens/requests.dart';

import '../../../provider/category_provider.dart';
import '../../../provider/gym_provider.dart';
import '../../../provider/user_provider.dart';
import 'maximpage.dart';
import 'user_search.dart';

class UserHome extends StatefulWidget {
  const UserHome({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _UserHomeState();
  }
}

class _UserHomeState extends State<UserHome> {
  @override
  void initState() {
    super.initState();
    _updateGui();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 500) {
          return _buildWideContainers();
        } else {
          return _buildNormalContainer();
        }
      },
    ));
  }

  // Function to update firstAccess value in the database
  Future<void> updateFirstAccessInDatabase(String userId, bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .update({'firstAccess': value});
    } catch (e) {
      // Handle the error appropriately
      // ignore: avoid_print
      print('Errore nel primo accesso: $e');
    }
  }

  Widget _buildWideContainers() {
    GymProvider gpd = Provider.of<GymProvider>(context, listen: false);
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);

    if (upd.user.palestre.isEmpty) {
      return Center(
        child: Container(
            width: 800,
            decoration: const BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: Colors.grey, width: 2.0),
              ),
            ),
            child: Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserSearch(),
                      ),
                    );
                    _updateGui();
                  },
                  child: const Icon(Icons.add),
                ),
                body: const Center(
                    child: Text('Nessuna palestra tra i preferiti')))),
      );
    } else {
      return Center(
        child: Container(
          width: 800,
          decoration: const BoxDecoration(
            border: Border.symmetric(
              vertical: BorderSide(color: Colors.grey, width: 2.0),
            ),
          ),
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UserSearch(),
                  ),
                );
                _updateGui();
              },
              child: const Icon(Icons.add),
            ),
            body: ListView.builder(
              itemCount: upd.user.palestre.length,
              itemBuilder: (context, index) {
                String current = upd.user.palestre[index];
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('gym')
                      .doc(current)
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
                      String nome = userData['nome'] ?? 'Nome';
                      String citta = userData['citta'] ?? 'Citta';
                      String indirizzo = userData['indirizzo'] ?? 'Indirizzo';

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(
                                  nome,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$indirizzo, $citta',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Your onPressed logic for 'Richiedi Scheda'
                                        List<dynamic>? list = userData['users'];
                                        if (list != null &&
                                            list.isNotEmpty &&
                                            list.contains(upd.user.uid)) {
                                          gpd.gym.user = list;
                                          gpd.gym.nome = userData['nome'];
                                          gpd.gym.uid = snapshot.data!.id;
                                          gpd.gym.email = userData['email'];
                                          gpd.gym.indirizzo =
                                              userData['indirizzo'];
                                          gpd.gym.telefono =
                                              userData['telefono'];
                                          gpd.gym.orario = userData['orario'];
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const Requests(),
                                            ),
                                          );
                                        } else {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Attenzione'),
                                              content: const Text(
                                                  'Questa palestra non ti autorizza a compiere azioni'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('ok'),
                                                )
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Richiedi Scheda'),
                                    ),
                                    const SizedBox(
                                      height: 7,
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Your onPressed logic for 'Prenota Personal Trainer'
                                        List<dynamic>? list = userData['users'];
                                        if (list != null &&
                                            list.isNotEmpty &&
                                            list.contains(upd.user.uid)) {
                                          gpd.gym.user = list;
                                          gpd.gym.nome = userData['nome'];
                                          gpd.gym.uid = snapshot.data!.id;
                                          gpd.gym.email = userData['email'];
                                          gpd.gym.indirizzo =
                                              userData['indirizzo'];
                                          gpd.gym.telefono =
                                              userData['telefono'];
                                          gpd.gym.orario = userData['orario'];
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const Bookings(),
                                            ),
                                          );
                                        } else {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Attenzione'),
                                              content: const Text(
                                                  'Questa palestra non ti autorizza a compiere azioni'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('ok'),
                                                )
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text(
                                          'Prenota Personal Trainer'),
                                    ),
                                    const SizedBox(
                                      height: 7,
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        List<dynamic>? list = userData['users'];
                                        if (list != null &&
                                            list.isNotEmpty &&
                                            list.contains(upd.user.uid)) {
                                          gpd.gym.user = list;
                                          gpd.gym.nome = userData['nome'];
                                          gpd.gym.uid = snapshot.data!.id;
                                          gpd.gym.email = userData['email'];
                                          gpd.gym.indirizzo =
                                              userData['indirizzo'];
                                          gpd.gym.telefono =
                                              userData['telefono'];
                                          gpd.gym.orario = userData['orario'];
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const MaximPage(),
                                            ),
                                          );
                                        } else {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Attenzione'),
                                              content: const Text(
                                                  'Questa palestra non ti autorizza a compiere azioni'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('ok'),
                                                )
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Inserisci massimale'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return const Center(
                        child: Text("Dati dell'utente non trovati."),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ),
      );
    }
  }

  Widget _buildNormalContainer() {
    GymProvider gpd = Provider.of<GymProvider>(context, listen: false);
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);

    if (upd.user.palestre.isEmpty) {
      return Center(
        child: Container(
            width: 800,
            decoration: const BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: Colors.grey, width: 2.0),
              ),
            ),
            child: Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserSearch(),
                      ),
                    );
                    _updateGui();
                  },
                  child: const Icon(Icons.add),
                ),
                body: const Center(
                    child: Text('Nessuna palestra tra i preferiti')))),
      );
    } else {
      return Scaffold(
        body: ListView.builder(
          itemCount: upd.user.palestre.length,
          itemBuilder: (context, index) {
            String current = upd.user.palestre[index];
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('gym')
                  .doc(current)
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
                  String nome = userData['nome'] ?? 'Nome';
                  String citta = userData['citta'] ?? 'Citta';
                  String indirizzo = userData['indirizzo'] ?? 'Indirizzo';

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              nome,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$indirizzo, $citta',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    // Your onPressed logic for 'Richiedi Scheda'
                                    List<dynamic>? list = userData['users'];
                                    if (list != null &&
                                        list.isNotEmpty &&
                                        list.contains(upd.user.uid)) {
                                      gpd.gym.user = list;
                                      gpd.gym.nome = userData['nome'];
                                      gpd.gym.uid = snapshot.data!.id;
                                      gpd.gym.email = userData['email'];
                                      gpd.gym.indirizzo = userData['indirizzo'];
                                      gpd.gym.telefono = userData['telefono'];
                                      gpd.gym.orario = userData['orario'];
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const Requests(),
                                        ),
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Attenzione'),
                                          content: const Text(
                                              'Questa palestra non ti autorizza a compiere azioni'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('ok'),
                                            )
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Richiedi Scheda'),
                                ),
                                const SizedBox(
                                  height: 7,
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    // Your onPressed logic for 'Prenota Personal Trainer'
                                    List<dynamic>? list = userData['users'];
                                    if (list != null &&
                                        list.isNotEmpty &&
                                        list.contains(upd.user.uid)) {
                                      gpd.gym.user = list;
                                      gpd.gym.nome = userData['nome'];
                                      gpd.gym.uid = snapshot.data!.id;
                                      gpd.gym.email = userData['email'];
                                      gpd.gym.indirizzo = userData['indirizzo'];
                                      gpd.gym.telefono = userData['telefono'];
                                      gpd.gym.orario = userData['orario'];
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const Bookings(),
                                        ),
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Attenzione'),
                                          content: const Text(
                                              'Questa palestra non ti autorizza a compiere azioni'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('ok'),
                                            )
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Prenota Personal Trainer'),
                                ),
                                const SizedBox(
                                  height: 7,
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    List<dynamic>? list = userData['users'];
                                    if (list != null &&
                                        list.isNotEmpty &&
                                        list.contains(upd.user.uid)) {
                                      gpd.gym.user = list;
                                      gpd.gym.nome = userData['nome'];
                                      gpd.gym.uid = snapshot.data!.id;
                                      gpd.gym.email = userData['email'];
                                      gpd.gym.indirizzo = userData['indirizzo'];
                                      gpd.gym.telefono = userData['telefono'];
                                      gpd.gym.orario = userData['orario'];
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const MaximPage(),
                                        ),
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Attenzione'),
                                          content: const Text(
                                              'Questa palestra non ti autorizza a compiere azioni'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('ok'),
                                            )
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Inserisci massimale'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const Center(
                    child: Text("Dati dell'utente non trovati."),
                  );
                }
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const UserSearch(),
              ),
            );
            _updateGui();
          },
          child: const Icon(Icons.add),
        ),
      );
    }
  }

  void _updateGui() {
    CategoryProvider cat =
        Provider.of<CategoryProvider>(context, listen: false);
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);

    User? user = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance
        .collection(cat.category!)
        .doc(user!.uid)
        .get()
        .then(
      (userData) {
        // Continue with your existing code to fetch and display gym data
        setState(() {
          upd.user.uid = user.uid;
          upd.user.nome = userData.data()!['nome'];
          upd.user.cognome = userData.data()!['cognome'];
          upd.user.email = userData.data()!['email'];
          upd.user.palestre = userData.data()!['palestre'];
          upd.user.codice = userData.data()!['userCode'];

          // Set firstAccess in UserProvider
          upd.user.firstAccess = userData.data()!['firstAccess'] ??
              true; // Get the firstAccess field

          if (upd.user.firstAccess) {
            // Redirect to UserSearch if firstAccess is true
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Benvenuto!'),
                  content: const Text(
                    'Benvenuto, seleziona il pulsante "+" posto in basso a destra per aggiungere alla home le tue palestre preferite, dopo di che torna indietro utilizzando la freccetta e attendi che la pelstra ti dia i permessi!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // Close the dialog
                        Navigator.pop(context);

                        // Set firstAccess to false
                        upd.user.firstAccess = false;

                        // Update firstAccess value in the database
                        updateFirstAccessInDatabase(upd.user.uid, false);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            });
          }
        });
      },
    );
  }
}
