import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../provider/gym_provider.dart';
import 'insert_max_page.dart';

class MaximPage extends StatefulWidget {
  const MaximPage({Key? key}) : super(key: key);

  @override
  State<MaximPage> createState() => _MaximPageState();
}

class _MaximPageState extends State<MaximPage> {
  String? selectedExerciseId = 'QicRyyA03fBCT84xvSoe';

  @override
  Widget build(BuildContext context) {
    GymProvider gpd = Provider.of<GymProvider>(context, listen: false);
    final userId = FirebaseAuth
        .instance.currentUser!.uid; // Sostituisci con l'ID dell'utente loggato
    final gymUid = gpd.gym.uid; // Sostituisci con l'ID della palestra corrente
    double screenWidth = MediaQuery.of(context).size.width;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: screenWidth > 500
            ? AppBar(
                title: const Text('Massimali'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'I Tuoi Massimali'),
                    Tab(text: 'Classifica'),
                  ],
                ),
              )
            : AppBar(
                title: const Text('Massimali'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'I Tuoi Massimali'),
                    Tab(text: 'Classifica'),
                  ],
                ),
              ),
        body: LayoutBuilder(
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
                  child: TabBarView(
                    children: [
                      // Contenuto della prima scheda (I Tuoi Massimali)
                      Column(
                        children: [
                          const SizedBox(
                            height: 7,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Naviga alla pagina "InsertMaxPage" quando il bottone viene premuto
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const InsertMaxPage(),
                                ),
                              );
                            },
                            child: const Text('Inserisci Massimale'),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('massimali')
                                  .where('userId', isEqualTo: userId)
                                  .where('usergym', isEqualTo: gymUid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Errore: ${snapshot.error}');
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return const Text(
                                      'Non ci sono massimali inseriti.');
                                } else {
                                  final massimali = snapshot.data!.docs;
                                  return ListView.builder(
                                    itemCount: massimali.length,
                                    itemBuilder: (context, index) {
                                      final massimale = massimali[index];
                                      final idEsercizio =
                                          massimale['idEsercizio'];
                                      final peso = massimale['peso'];

                                      return FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('esercizi')
                                            .doc(idEsercizio)
                                            .get(),
                                        builder: (context, esercizioSnapshot) {
                                          if (esercizioSnapshot
                                                  .connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          } else if (esercizioSnapshot
                                              .hasError) {
                                            return Text(
                                                'Errore: ${esercizioSnapshot.error}');
                                          } else if (!esercizioSnapshot
                                              .hasData) {
                                            return const Text(
                                                'Esercizio non trovato.');
                                          } else {
                                            final esercizio =
                                                esercizioSnapshot.data!;
                                            final nomeEsercizio =
                                                esercizio['nome'];
                                            final categoriaEsercizio =
                                                esercizio['categoria'];

                                            return ListTile(
                                              title: Text(
                                                  '$nomeEsercizio - $categoriaEsercizio'),
                                              subtitle:
                                                  Text('Peso: $peso' 'kg'),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      Column(
                        children: [
                          Row(
                            children: [
                              const Text('Classifica per:'),
                              const SizedBox(width: 8.0),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('esercizi')
                                    .where('pesi', isEqualTo: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text('Errore: ${snapshot.error}');
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const Text(
                                        'Nessun esercizio disponibile per i pesi.');
                                  } else {
                                    final exercises = snapshot.data!.docs;
                                    final exerciseItems =
                                        exercises.map((exercise) {
                                      final exerciseId = exercise.id;
                                      final exerciseName =
                                          exercise['nome'] as String;
                                      return DropdownMenuItem(
                                        value: exerciseId,
                                        child: Text(exerciseName),
                                      );
                                    }).toList();

                                    return DropdownButton<String>(
                                      value: selectedExerciseId,
                                      hint:
                                          const Text('Seleziona un esercizio'),
                                      items: exerciseItems,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedExerciseId = value;
                                        });
                                      },
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('massimali')
                                  .where('usergym', isEqualTo: gymUid)
                                  .where('idEsercizio',
                                      isEqualTo: selectedExerciseId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Errore: ${snapshot.error}');
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return const Text(
                                      'Nessuna classifica disponibile.');
                                } else {
                                  final classifica = snapshot.data!.docs;
                                  classifica.sort((a, b) => ((b['peso'] as int)
                                      .compareTo(a['peso'] as int)));
                                  return ListView.builder(
                                    itemCount: classifica.length,
                                    itemBuilder: (context, index) {
                                      final userId =
                                          classifica[index]['userId'];
                                      final peso = classifica[index]['peso'];
                                      String positionText =
                                          (index + 1).toString();

                                      if (index == 0) {
                                        positionText = '🥇 $positionText';
                                      } else if (index == 1) {
                                        positionText = '🥈 $positionText';
                                      } else if (index == 2) {
                                        positionText = '🥉 $positionText';
                                      }

                                      return FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('user')
                                            .doc(userId)
                                            .get(),
                                        builder: (context, userSnapshot) {
                                          if (userSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          } else if (userSnapshot.hasError) {
                                            return Text(
                                                'Errore: ${userSnapshot.error}');
                                          } else {
                                            final userData = userSnapshot.data!
                                                .data() as Map<String, dynamic>;
                                            final userName =
                                                userData['nome'] as String;
                                            final userSurname =
                                                userData['cognome'] as String;

                                            return ListTile(
                                              title: Text(
                                                  '$positionText - $userName $userSurname'),
                                              subtitle: Text('Peso: $peso'),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return TabBarView(
                children: [
                  // Contenuto della prima scheda (I Tuoi Massimali)
                  Column(
                    children: [
                      const SizedBox(
                        height: 7,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Naviga alla pagina "InsertMaxPage" quando il bottone viene premuto
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const InsertMaxPage(),
                            ),
                          );
                        },
                        child: const Text('Inserisci Massimale'),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('massimali')
                              .where('userId', isEqualTo: userId)
                              .where('usergym', isEqualTo: gymUid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Errore: ${snapshot.error}');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Text(
                                  'Non ci sono massimali inseriti.');
                            } else {
                              final massimali = snapshot.data!.docs;
                              return ListView.builder(
                                itemCount: massimali.length,
                                itemBuilder: (context, index) {
                                  final massimale = massimali[index];
                                  final idEsercizio = massimale['idEsercizio'];
                                  final peso = massimale['peso'];

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('esercizi')
                                        .doc(idEsercizio)
                                        .get(),
                                    builder: (context, esercizioSnapshot) {
                                      if (esercizioSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      } else if (esercizioSnapshot.hasError) {
                                        return Text(
                                            'Errore: ${esercizioSnapshot.error}');
                                      } else if (!esercizioSnapshot.hasData) {
                                        return const Text(
                                            'Esercizio non trovato.');
                                      } else {
                                        final esercizio =
                                            esercizioSnapshot.data!;
                                        final nomeEsercizio = esercizio['nome'];
                                        final categoriaEsercizio =
                                            esercizio['categoria'];

                                        return ListTile(
                                          title: Text(
                                              '$nomeEsercizio - $categoriaEsercizio'),
                                          subtitle: Text('Peso: $peso' 'kg'),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      Row(
                        children: [
                          const Text('Classifica per:'),
                          const SizedBox(width: 8.0),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('esercizi')
                                .where('pesi', isEqualTo: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Errore: ${snapshot.error}');
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Text(
                                    'Nessun esercizio disponibile per i pesi.');
                              } else {
                                final exercises = snapshot.data!.docs;
                                final exerciseItems = exercises.map((exercise) {
                                  final exerciseId = exercise.id;
                                  final exerciseName =
                                      exercise['nome'] as String;
                                  return DropdownMenuItem(
                                    value: exerciseId,
                                    child: Text(exerciseName),
                                  );
                                }).toList();

                                return DropdownButton<String>(
                                  value: selectedExerciseId,
                                  hint: const Text('Seleziona un esercizio'),
                                  items: exerciseItems,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedExerciseId = value;
                                    });
                                  },
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('massimali')
                              .where('usergym', isEqualTo: gymUid)
                              .where('idEsercizio',
                                  isEqualTo: selectedExerciseId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Errore: ${snapshot.error}');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Text(
                                  'Nessuna classifica disponibile.');
                            } else {
                              final classifica = snapshot.data!.docs;
                              classifica.sort((a, b) => ((b['peso'] as int)
                                  .compareTo(a['peso'] as int)));
                              return ListView.builder(
                                itemCount: classifica.length,
                                itemBuilder: (context, index) {
                                  final userId = classifica[index]['userId'];
                                  final peso = classifica[index]['peso'];
                                  String positionText = (index + 1).toString();

                                  if (index == 0) {
                                    positionText = '🥇 $positionText';
                                  } else if (index == 1) {
                                    positionText = '🥈 $positionText';
                                  } else if (index == 2) {
                                    positionText = '🥉 $positionText';
                                  }

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('user')
                                        .doc(userId)
                                        .get(),
                                    builder: (context, userSnapshot) {
                                      if (userSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      } else if (userSnapshot.hasError) {
                                        return Text(
                                            'Errore: ${userSnapshot.error}');
                                      } else {
                                        final userData = userSnapshot.data!
                                            .data() as Map<String, dynamic>;
                                        final userName =
                                            userData['nome'] as String;
                                        final userSurname =
                                            userData['cognome'] as String;

                                        return ListTile(
                                          title: Text(
                                              '$positionText - $userName $userSurname'),
                                          subtitle: Text('Peso: $peso'),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
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
