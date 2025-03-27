import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../provider/gym_provider.dart';

class InsertMaxPage extends StatefulWidget {
  const InsertMaxPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _InsertMaxPageState();
  }
}

class _InsertMaxPageState extends State<InsertMaxPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? selectedExerciseId;
  double? weight;

  @override
  Widget build(BuildContext context) {
    GymProvider gpd = Provider.of<GymProvider>(context, listen: false);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 500) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Inserimento Massimale'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Center(
                  child: Container(
                    width: 800,
                    decoration: const BoxDecoration(
                      border: Border.symmetric(
                        vertical: BorderSide(color: Colors.grey, width: 2.0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('esercizi')
                              .where('pesi', isEqualTo: true)
                              .get(),
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
                                final exerciseName = exercise['nome'] as String;
                                return DropdownMenuItem(
                                  value: exerciseId,
                                  child: Text(exerciseName),
                                );
                              }).toList();

                              return DropdownButtonFormField<String>(
                                value: selectedExerciseId,
                                hint: const Text('Seleziona un esercizio'),
                                items: exerciseItems,
                                onChanged: (value) {
                                  setState(() {
                                    selectedExerciseId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Seleziona un esercizio.';
                                  }
                                  return null;
                                },
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Inserisci il peso'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci il peso.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            weight = double.parse(value!);
                          },
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();

                              // Verifica se esiste già un massimale con le stesse condizioni
                              final userId = FirebaseAuth.instance.currentUser!
                                  .uid; // Sostituisci con l'ID dell'utente loggato
                              final gymUid = gpd.gym
                                  .uid; // Sostituisci con l'ID della palestra corrente

                              final existingMaxQuery = await FirebaseFirestore
                                  .instance
                                  .collection('massimali')
                                  .where('userId', isEqualTo: userId)
                                  .where('usergym', isEqualTo: gymUid)
                                  .where('idEsercizio',
                                      isEqualTo: selectedExerciseId)
                                  .get();

                              if (existingMaxQuery.docs.isNotEmpty) {
                                // Aggiorna il peso del massimale esistente
                                final existingMaxDoc =
                                    existingMaxQuery.docs.first;
                                final existingMaxId = existingMaxDoc.id;

                                await FirebaseFirestore.instance
                                    .collection('massimali')
                                    .doc(existingMaxId)
                                    .update({
                                  'peso': weight,
                                });
                              } else {
                                // Crea un nuovo massimale
                                FirebaseFirestore.instance
                                    .collection('massimali')
                                    .add({
                                  'userId': userId,
                                  'usergym': gymUid,
                                  'idEsercizio': selectedExerciseId,
                                  'peso': weight,
                                });
                              }

                              // Torna alla pagina precedente
                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Invia'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Inserimento Massimale'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('esercizi')
                          .where('pesi', isEqualTo: true)
                          .get(),
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
                            final exerciseName = exercise['nome'] as String;
                            return DropdownMenuItem(
                              value: exerciseId,
                              child: Text(exerciseName),
                            );
                          }).toList();

                          return DropdownButtonFormField<String>(
                            value: selectedExerciseId,
                            hint: const Text('Seleziona un esercizio'),
                            items: exerciseItems,
                            onChanged: (value) {
                              setState(() {
                                selectedExerciseId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Seleziona un esercizio.';
                              }
                              return null;
                            },
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Inserisci il peso'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci il peso.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        weight = double.parse(value!);
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();

                          // Verifica se esiste già un massimale con le stesse condizioni
                          final userId = FirebaseAuth.instance.currentUser!
                              .uid; // Sostituisci con l'ID dell'utente loggato
                          final gymUid = gpd.gym
                              .uid; // Sostituisci con l'ID della palestra corrente

                          final existingMaxQuery = await FirebaseFirestore
                              .instance
                              .collection('massimali')
                              .where('userId', isEqualTo: userId)
                              .where('usergym', isEqualTo: gymUid)
                              .where('idEsercizio',
                                  isEqualTo: selectedExerciseId)
                              .get();

                          if (existingMaxQuery.docs.isNotEmpty) {
                            // Aggiorna il peso del massimale esistente
                            final existingMaxDoc = existingMaxQuery.docs.first;
                            final existingMaxId = existingMaxDoc.id;

                            await FirebaseFirestore.instance
                                .collection('massimali')
                                .doc(existingMaxId)
                                .update({
                              'peso': weight,
                            });
                          } else {
                            // Crea un nuovo massimale
                            FirebaseFirestore.instance
                                .collection('massimali')
                                .add({
                              'userId': userId,
                              'usergym': gymUid,
                              'idEsercizio': selectedExerciseId,
                              'peso': weight,
                            });
                          }

                          // Torna alla pagina precedente
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Invia'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
