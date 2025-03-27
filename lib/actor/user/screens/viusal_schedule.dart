import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:univeristy/actor/user/screens/show_exercise.dart';

import 'countdown.dart';

class VisualSchedule extends StatefulWidget {
  final String scheduleId;

  const VisualSchedule({Key? key, required this.scheduleId}) : super(key: key);

  @override
  State<VisualSchedule> createState() => _VisualScheduleState();
}

class _VisualScheduleState extends State<VisualSchedule> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: screenWidth > 500
          ? AppBar(
              title: const Center(
                  child: SizedBox(width: 800, child: Text('Dettagli Scheda'))),
            )
          : AppBar(
              title: const Text('Dettagli Scheda'),
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

  Widget _buildCardForNullExercise(Map<String, dynamic> esercizio) {
    final nomeEsercizio = esercizio['nomeEsercizio'];
    final parteDelCorpo = esercizio['parteDelCorpo'];
    final numSets = esercizio['numSets'];
    final numRepetitions = esercizio['numRepetitions'];
    final recoveryTimeMinutes = esercizio['recoveryTimeMinutes'];
    final recoveryTimeSeconds = esercizio['recoveryTimeSeconds'];
    final cardioMinutes = esercizio['cardioMinutes'];

    final isCardio = cardioMinutes != null;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Esercizio: $nomeEsercizio',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Parte del Corpo: $parteDelCorpo',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  if (!isCardio)
                    Text(
                      'Numero di Set: $numSets',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  if (!isCardio)
                    Text(
                      'Numero di Ripetizioni: $numRepetitions',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  if (!isCardio)
                    Text(
                      'Recupero: $recoveryTimeMinutes m $recoveryTimeSeconds s',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  if (isCardio)
                    Text(
                      'Minuti Cardio: $cardioMinutes',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                ],
              ),
            ),
            if (!isCardio)
              Column(
                children: [
                  IconButton(
                    color: Colors.green,
                    onPressed: () {
                      final totalSeconds =
                          (recoveryTimeMinutes * 60) + recoveryTimeSeconds;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CountdownPage(
                            initialCountdownSeconds: totalSeconds,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timer),
                  ),
                  Text(
                    '$recoveryTimeMinutes m $recoveryTimeSeconds s',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 0, 143, 30),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
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
          child: Column(
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('schede')
                    .doc(widget.scheduleId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('Scheda non trovata.'));
                  }

                  final schedaData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final esercizi = schedaData['esercizi'] as List<dynamic>;

                  return SingleChildScrollView(
                    child: Column(
                      children: esercizi.map<Widget>((esercizio) {
                        if (esercizio['id'] == null) {
                          return _buildCardForNullExercise(esercizio);
                        }

                        final id = esercizio['id'];

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('esercizi')
                              .doc(id)
                              .get(),
                          builder: (context, exerciseSnapshot) {
                            if (exerciseSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (!exerciseSnapshot.hasData ||
                                !exerciseSnapshot.data!.exists) {
                              return const Center(
                                  child: Text('Esercizio non trovato.'));
                            }

                            final exerciseData = exerciseSnapshot.data!.data()
                                as Map<String, dynamic>;
                            final url = exerciseData['url'] as String;

                            final nomeEsercizio = esercizio['nomeEsercizio'];
                            final numRepetitions = esercizio['numRepetitions'];
                            final numSets = esercizio['numSets'];
                            final parteDelCorpo = esercizio['parteDelCorpo'];
                            final recoveryTimeMinutes =
                                esercizio['recoveryTimeMinutes'];
                            final recoveryTimeSeconds =
                                esercizio['recoveryTimeSeconds'];
                            final cardioMinutes = esercizio['cardioMinutes'];

                            final isCardio = cardioMinutes != null;

                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: Text(
                                        'Esercizio: $nomeEsercizio',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.black,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Parte del Corpo: $parteDelCorpo',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                          if (!isCardio)
                                            Text(
                                              'Numero di Set: $numSets',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                          if (!isCardio)
                                            Text(
                                              'Numero di Ripetizioni: $numRepetitions',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                          if (!isCardio)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Recupero: $recoveryTimeMinutes m $recoveryTimeSeconds s',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          if (isCardio)
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Minuti Cardio: $cardioMinutes',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        if (url.isNotEmpty)
                                          Column(
                                            children: [
                                              Column(
                                                children: [
                                                  IconButton(
                                                    color: Colors.green,
                                                    onPressed: () {
                                                      final totalSeconds =
                                                          (recoveryTimeMinutes *
                                                                  60) +
                                                              recoveryTimeSeconds;
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              CountdownPage(
                                                            initialCountdownSeconds:
                                                                totalSeconds,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    icon:
                                                        const Icon(Icons.timer),
                                                  ),
                                                  Text(
                                                    '$recoveryTimeMinutes m $recoveryTimeSeconds s',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color.fromARGB(
                                                          255, 0, 143, 30),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 8,
                                              ),
                                              Column(
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                ShowExerciseYT(
                                                                    url,
                                                                    nomeEsercizio)),
                                                      );
                                                    },
                                                    color: Colors.green,
                                                    icon: const Icon(
                                                        Icons.play_circle),
                                                  ),
                                                  const Text(
                                                    'Guarda tutorial',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color.fromARGB(
                                                          255, 0, 143, 30),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalContainer() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('schede')
          .doc(widget.scheduleId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Scheda non trovata.'));
        }

        final schedaData = snapshot.data!.data() as Map<String, dynamic>;
        final esercizi = schedaData['esercizi'] as List<dynamic>;

        return SingleChildScrollView(
          child: Column(
            children: esercizi.map<Widget>((esercizio) {
              if (esercizio['id'] == null) {
                return _buildCardForNullExercise(esercizio);
              }

              final id = esercizio['id'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('esercizi')
                    .doc(id)
                    .get(),
                builder: (context, exerciseSnapshot) {
                  if (exerciseSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!exerciseSnapshot.hasData ||
                      !exerciseSnapshot.data!.exists) {
                    return const Center(child: Text('Esercizio non trovato.'));
                  }

                  final exerciseData =
                      exerciseSnapshot.data!.data() as Map<String, dynamic>;
                  final url = exerciseData['url'] as String;

                  final nomeEsercizio = esercizio['nomeEsercizio'];
                  final numRepetitions = esercizio['numRepetitions'];
                  final numSets = esercizio['numSets'];
                  final parteDelCorpo = esercizio['parteDelCorpo'];
                  final recoveryTimeMinutes = esercizio['recoveryTimeMinutes'];
                  final recoveryTimeSeconds = esercizio['recoveryTimeSeconds'];
                  final cardioMinutes = esercizio['cardioMinutes'];

                  final isCardio = cardioMinutes != null;

                  return Card(
                    elevation: 4,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              'Esercizio: $nomeEsercizio',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Parte del Corpo: $parteDelCorpo',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                if (!isCardio)
                                  Text(
                                    'Numero di Set: $numSets',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                if (!isCardio)
                                  Text(
                                    'Numero di Ripetizioni: $numRepetitions',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                if (!isCardio)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Recupero: $recoveryTimeMinutes m $recoveryTimeSeconds s',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (isCardio)
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Minuti Cardio: $cardioMinutes',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              if (url.isNotEmpty)
                                Column(
                                  children: [
                                    Column(
                                      children: [
                                        IconButton(
                                          color: Colors.green,
                                          onPressed: () {
                                            final totalSeconds =
                                                (recoveryTimeMinutes * 60) +
                                                    recoveryTimeSeconds;
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CountdownPage(
                                                  initialCountdownSeconds:
                                                      totalSeconds,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.timer),
                                        ),
                                        Text(
                                          '$recoveryTimeMinutes m $recoveryTimeSeconds s',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color:
                                                Color.fromARGB(255, 0, 143, 30),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ShowExerciseYT(
                                                        url, nomeEsercizio),
                                              ),
                                            );
                                          },
                                          color: Colors.green,
                                          icon: const Icon(Icons.play_circle),
                                        ),
                                        const Text(
                                          'Guarda tutorial',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                Color.fromARGB(255, 0, 143, 30),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
