import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:univeristy/data/schedule.dart';

import '../../../models/exercise.dart';

class InserimentoScheda extends StatefulWidget {
  const InserimentoScheda(
      {Key? key, required this.userId, required this.requestId})
      : super(key: key);

  final String userId;
  final String requestId;

  @override
  State<StatefulWidget> createState() {
    return _InserimentoSchedaState();
  }
}

class _InserimentoSchedaState extends State<InserimentoScheda> {
  @override
  void initState() {
    super.initState();
    getAllowedCoachNames();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  BodyPart selectedBodyPart = BodyPart.gambe;
  TextEditingController exerciseNameController = TextEditingController();
  TextEditingController numSetsController = TextEditingController();
  TextEditingController numRepetitionsController = TextEditingController();
  TextEditingController cardioMinutesController = TextEditingController();
  TextEditingController recoveryMinutesController = TextEditingController();
  TextEditingController recoverySecondsController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  List<Map<String, dynamic>> exercises = [];
  int exerciseCounter = 0;

  bool isSaving = false;
  bool isCardio = false;
  bool manuallyEnterExerciseName = false;
  String manualExerciseName = '';

  Future<void> saveSchedaToFirestore() async {
    setState(() {
      isSaving = true;
    });

    try {
      CollectionReference schedeCollection =
          FirebaseFirestore.instance.collection('schede');

      CollectionReference requestsCollection =
          FirebaseFirestore.instance.collection('requests');

      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      await schedeCollection.add({
        'coachId': FirebaseAuth.instance.currentUser?.uid,
        'userId': widget.userId,
        'data': formattedDate,
        'esercizi': exercises,
      });

      await requestsCollection.doc(widget.requestId).update({'added': true});

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheda aggiunta'),
        ),
      );

      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    } catch (error) {
      // ignore: avoid_print
      print('Errore durante il salvataggio: $error');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  void generateAndInsertBeginnerScheda() {
    beginnerExercises;

    setState(() {
      exercises.addAll(beginnerExercises);
      exerciseCounter += beginnerExercises.length;
    });
  }

  void saveManualExercise() {
    if (manualExerciseName.isNotEmpty) {
      setState(() {
        exercises.add({
          'parteDelCorpo': selectedBodyPart.toString().substring(9),
          'nomeEsercizio': manualExerciseName,
          'id': null,
          'numSets': int.tryParse(numSetsController.text) ?? 0,
          'numRepetitions': int.tryParse(numRepetitionsController.text) ?? 0,
          'recoveryTimeMinutes':
              int.tryParse(recoveryMinutesController.text) ?? 0,
          'recoveryTimeSeconds':
              int.tryParse(recoverySecondsController.text) ?? 0,
          'cardioMinutes':
              isCardio ? int.tryParse(cardioMinutesController.text) ?? 0 : null,
          'note': noteController.text,
        });

        exerciseCounter++;
        exerciseNameController.clear();
        numSetsController.clear();
        numRepetitionsController.clear();
        recoveryMinutesController.clear();
        recoverySecondsController.clear();
        cardioMinutesController.clear();
        noteController.clear();
        isCardio = false;
        manuallyEnterExerciseName = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: screenWidth > 500
          ? AppBar(
              title: const Center(
                  child:
                      SizedBox(width: 800, child: Text('Inserimento Scheda'))),
            )
          : AppBar(
              title: const Text('Inserimento Scheda'),
            ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 500) {
            return _buildWideContainers();
          } else {
            return _buildNormalContainer();
          }
        },
      ),
    );
  }

  Map<String, String>? selectedExercise;
  List<Map<String, String>> allowedExercise = [];

  Future<void> getAllowedCoachNames() async {
    QuerySnapshot coachSnapshot =
        await FirebaseFirestore.instance.collection('esercizi').get();

    allowedExercise.clear();

    for (QueryDocumentSnapshot doc in coachSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String exerciseName = data['nome'] ?? 'Nome non disponibile';
      String exerciseCategory =
          data['categoria'] ?? 'Categoria non disponibile';
      String exerciseId = doc.id;

      allowedExercise.add({
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'exerciseCategory': exerciseCategory
      });
    }
    setState(() {
      allowedExercise;
    });
  }

  Widget dropExercise(String filterCategory) {
    final filteredExercises = allowedExercise
        .where((exercise) => exercise['exerciseCategory'] == filterCategory)
        .toList();

    return DropdownButton<Map<String, String>>(
      value: selectedExercise,
      items: filteredExercises.map<DropdownMenuItem<Map<String, String>>>(
        (Map<String, String> exercise) {
          return DropdownMenuItem<Map<String, String>>(
            value: exercise,
            child: Text(exercise['exerciseName'] ?? 'Nome non disponibile'),
          );
        },
      ).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedExercise = newValue!;
        });
      },
    );
  }

  Widget _buildWideContainers() {
    return Center(
      child: Container(
        width: 800,
        decoration: const BoxDecoration(
          border: Border.symmetric(
            vertical: BorderSide(color: Colors.grey, width: 2.0),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: DropdownButton<BodyPart>(
                                  value: selectedBodyPart,
                                  onChanged: (newValue) {
                                    setState(() {
                                      selectedBodyPart = newValue!;
                                      if (selectedBodyPart == BodyPart.cardio) {
                                        isCardio = true;
                                        numSetsController.text = '1';
                                        numRepetitionsController.text = '1';
                                        cardioMinutesController.text = '';
                                      } else {
                                        isCardio = false;
                                      }

                                      selectedExercise =
                                          null; // Resetta il secondo dropdown
                                    });
                                  },
                                  items: BodyPart.values.map((bodyPart) {
                                    return DropdownMenuItem<BodyPart>(
                                      value: bodyPart,
                                      child: Text(bodyPart == BodyPart.cardio
                                          ? 'cardio'
                                          : bodyPart.toString().substring(9)),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: manuallyEnterExerciseName
                                    ? TextFormField(
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Inserisci il nome dell\'esercizio',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            manualExerciseName = value;
                                          });
                                        },
                                      )
                                    : dropExercise(
                                        selectedBodyPart
                                            .toString()
                                            .substring(9),
                                      ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: manuallyEnterExerciseName,
                                onChanged: (value) {
                                  setState(() {
                                    manuallyEnterExerciseName = value!;
                                    if (manuallyEnterExerciseName) {
                                      selectedExercise = null;
                                    }
                                  });
                                },
                              ),
                              const Text('Inserisci nome manualmente'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Numero di serie (1-10)',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: numSetsController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    return null;

                                    // ... Validazione ...
                                  },
                                  enabled: !isCardio,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Numero di ripetizioni (1-20)',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: numRepetitionsController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    return null;

                                    // ... Validazione ...
                                  },
                                  enabled: !isCardio,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Minuti di recupero (0-60)',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: recoveryMinutesController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    return null;

                                    // ... Validazione ...
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Secondi di recupero (0-59)',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: recoverySecondsController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    return null;

                                    // ... Validazione ...
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Visibility(
                                  visible: isCardio,
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Minuti di cardio (5-30)',
                                      border: OutlineInputBorder(),
                                    ),
                                    controller: cardioMinutesController,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      return null;

                                      // ... Validazione ...
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          if (manuallyEnterExerciseName) {
                                            // Salva l'esercizio inserito manualmente
                                            saveManualExercise();
                                          } else {
                                            // Salva l'esercizio selezionato dal dropdown
                                            if (selectedExercise != null) {
                                              setState(() {
                                                exercises.add({
                                                  'parteDelCorpo':
                                                      selectedBodyPart
                                                          .toString()
                                                          .substring(9),
                                                  'nomeEsercizio':
                                                      selectedExercise![
                                                          'exerciseName'],
                                                  'id': selectedExercise![
                                                      'exerciseId'],
                                                  'numSets': int.tryParse(
                                                          numSetsController
                                                              .text) ??
                                                      0,
                                                  'numRepetitions': int.tryParse(
                                                          numRepetitionsController
                                                              .text) ??
                                                      0,
                                                  'recoveryTimeMinutes':
                                                      int.tryParse(
                                                              recoveryMinutesController
                                                                  .text) ??
                                                          0,
                                                  'recoveryTimeSeconds':
                                                      int.tryParse(
                                                              recoverySecondsController
                                                                  .text) ??
                                                          0,
                                                  'cardioMinutes': isCardio
                                                      ? int.tryParse(
                                                              cardioMinutesController
                                                                  .text) ??
                                                          0
                                                      : null,
                                                  'note': noteController.text,
                                                });

                                                exerciseCounter++;
                                                exerciseNameController.clear();
                                                numSetsController.clear();
                                                numRepetitionsController
                                                    .clear();
                                                recoveryMinutesController
                                                    .clear();
                                                recoverySecondsController
                                                    .clear();
                                                cardioMinutesController.clear();
                                                noteController.clear();
                                                isCardio = false;
                                              });
                                            }
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.deepPurple[400],
                                ),
                                child: const Text('Aggiungi Esercizio'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const Divider(
                            color: Colors.grey,
                            thickness: 1,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () {
                                        generateAndInsertBeginnerScheda();
                                      },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Scheda Principiante'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Esercizi inseriti: $exerciseCounter'),
                          if (isSaving) const CircularProgressIndicator(),
                          if (exerciseCounter > 0)
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: exercises.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  elevation: 2,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text(
                                      'Nome: ${exercises[index]['nomeEsercizio']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Parte del corpo: ${exercises[index]['parteDelCorpo']}',
                                        ),
                                        if (exercises[index]['cardioMinutes'] !=
                                            null)
                                          Text(
                                            'Minuti di cardio: ${exercises[index]['cardioMinutes']}',
                                          ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          exercises.removeAt(index);
                                          exerciseCounter--;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                  'Esercizio rimosso'),
                                              action: SnackBarAction(
                                                label: 'Annulla',
                                                onPressed: () {
                                                  setState(() {
                                                    exercises.insert(index, {
                                                      'parteDelCorpo':
                                                          exercises[index]
                                                              ['parteDelCorpo'],
                                                      'nomeEsercizio':
                                                          exercises[index]
                                                              ['nomeEsercizio'],
                                                      'numSets':
                                                          exercises[index]
                                                              ['numSets'],
                                                      'numRepetitions':
                                                          exercises[index][
                                                              'numRepetitions'],
                                                      'recoveryTimeMinutes':
                                                          exercises[index][
                                                              'recoveryTimeMinutes'],
                                                      'recoveryTimeSeconds':
                                                          exercises[index][
                                                              'recoveryTimeSeconds'],
                                                      'cardioMinutes':
                                                          exercises[index]
                                                              ['cardioMinutes'],
                                                      'note': exercises[index]
                                                          ['note'],
                                                    });
                                                    exerciseCounter++;
                                                  });
                                                },
                                              ),
                                            ),
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (exerciseCounter > 0)
                                ElevatedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          await saveSchedaToFirestore();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.deepPurple[900],
                                  ),
                                  child: const Text('Salva Scheda'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalContainer() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButton<BodyPart>(
                        value: selectedBodyPart,
                        onChanged: (newValue) {
                          setState(() {
                            selectedBodyPart = newValue!;
                            if (selectedBodyPart == BodyPart.cardio) {
                              isCardio = true;
                              numSetsController.text = '1';
                              numRepetitionsController.text = '1';
                              cardioMinutesController.text = '';
                            } else {
                              isCardio = false;
                            }

                            selectedExercise =
                                null; // Resetta il secondo dropdown
                          });
                        },
                        items: BodyPart.values.map((bodyPart) {
                          return DropdownMenuItem<BodyPart>(
                            value: bodyPart,
                            child: Text(bodyPart == BodyPart.cardio
                                ? 'cardio'
                                : bodyPart.toString().substring(9)),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: manuallyEnterExerciseName
                          ? TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Inserisci il nome dell\'esercizio',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  manualExerciseName = value;
                                });
                              },
                            )
                          : dropExercise(
                              selectedBodyPart.toString().substring(9),
                            ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: manuallyEnterExerciseName,
                      onChanged: (value) {
                        setState(() {
                          manuallyEnterExerciseName = value!;
                          if (manuallyEnterExerciseName) {
                            selectedExercise = null;
                          }
                        });
                      },
                    ),
                    const Text('Inserisci nome manualmente'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Numero di serie (1-10)',
                          border: OutlineInputBorder(),
                        ),
                        controller: numSetsController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          return null;

                          // ... Validazione ...
                        },
                        enabled: !isCardio,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Numero di ripetizioni (1-20)',
                          border: OutlineInputBorder(),
                        ),
                        controller: numRepetitionsController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          return null;

                          // ... Validazione ...
                        },
                        enabled: !isCardio,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Minuti di recupero (0-60)',
                          border: OutlineInputBorder(),
                        ),
                        controller: recoveryMinutesController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          return null;

                          // ... Validazione ...
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Secondi di recupero (0-59)',
                          border: OutlineInputBorder(),
                        ),
                        controller: recoverySecondsController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          return null;

                          // ... Validazione ...
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Visibility(
                        visible: isCardio,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Minuti di cardio (5-30)',
                            border: OutlineInputBorder(),
                          ),
                          controller: cardioMinutesController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            return null;

                            // ... Validazione ...
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                if (manuallyEnterExerciseName) {
                                  // Salva l'esercizio inserito manualmente
                                  saveManualExercise();
                                } else {
                                  // Salva l'esercizio selezionato dal dropdown
                                  if (selectedExercise != null) {
                                    setState(() {
                                      exercises.add({
                                        'parteDelCorpo': selectedBodyPart
                                            .toString()
                                            .substring(9),
                                        'nomeEsercizio':
                                            selectedExercise!['exerciseName'],
                                        'id': selectedExercise!['exerciseId'],
                                        'numSets': int.tryParse(
                                                numSetsController.text) ??
                                            0,
                                        'numRepetitions': int.tryParse(
                                                numRepetitionsController
                                                    .text) ??
                                            0,
                                        'recoveryTimeMinutes': int.tryParse(
                                                recoveryMinutesController
                                                    .text) ??
                                            0,
                                        'recoveryTimeSeconds': int.tryParse(
                                                recoverySecondsController
                                                    .text) ??
                                            0,
                                        'cardioMinutes': isCardio
                                            ? int.tryParse(
                                                    cardioMinutesController
                                                        .text) ??
                                                0
                                            : null,
                                        'note': noteController.text,
                                      });

                                      exerciseCounter++;
                                      exerciseNameController.clear();
                                      numSetsController.clear();
                                      numRepetitionsController.clear();
                                      recoveryMinutesController.clear();
                                      recoverySecondsController.clear();
                                      cardioMinutesController.clear();
                                      noteController.clear();
                                      isCardio = false;
                                    });
                                  }
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.deepPurple[400],
                      ),
                      child: const Text('Aggiungi Esercizio'),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () {
                              generateAndInsertBeginnerScheda();
                            },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Scheda Principiante'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Esercizi inseriti: $exerciseCounter'),
                if (isSaving) const CircularProgressIndicator(),
                if (exerciseCounter > 0)
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            'Nome: ${exercises[index]['nomeEsercizio']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parte del corpo: ${exercises[index]['parteDelCorpo']}',
                              ),
                              if (exercises[index]['cardioMinutes'] != null)
                                Text(
                                  'Minuti di cardio: ${exercises[index]['cardioMinutes']}',
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                exercises.removeAt(index);
                                exerciseCounter--;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Esercizio rimosso'),
                                    action: SnackBarAction(
                                      label: 'Annulla',
                                      onPressed: () {
                                        setState(() {
                                          exercises.insert(index, {
                                            'parteDelCorpo': exercises[index]
                                                ['parteDelCorpo'],
                                            'nomeEsercizio': exercises[index]
                                                ['nomeEsercizio'],
                                            'numSets': exercises[index]
                                                ['numSets'],
                                            'numRepetitions': exercises[index]
                                                ['numRepetitions'],
                                            'recoveryTimeMinutes':
                                                exercises[index]
                                                    ['recoveryTimeMinutes'],
                                            'recoveryTimeSeconds':
                                                exercises[index]
                                                    ['recoveryTimeSeconds'],
                                            'cardioMinutes': exercises[index]
                                                ['cardioMinutes'],
                                            'note': exercises[index]['note'],
                                          });
                                          exerciseCounter++;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (exerciseCounter > 0)
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                await saveSchedaToFirestore();
                              },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepPurple[900],
                        ),
                        child: const Text('Salva Scheda'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
