import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../provider/gym_provider.dart';

final formatter = DateFormat.yMd();

class Requests extends StatefulWidget {
  const Requests({super.key});

  @override
  State<Requests> createState() => _Requests();
}

class _Requests extends State<Requests> {
  String _enteredNote = '';

  bool _isSending2 = false;
  String? selectedHour;
  final _form2 = GlobalKey<FormState>();
  Map<String, String>? selectedCoach;
  Map<String, String>? selectedCoach2;
  List<Map<String, String>> allowedCoaches = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? bookings;

  @override
  void initState() {
    super.initState();
    getAllowedCoachNames();
  }

  @override
  Widget build(BuildContext context) {
    GymProvider gpd = Provider.of<GymProvider>(context, listen: false);
    double screenWidth = MediaQuery.of(context).size.width;
    String gymName = gpd.gym.nome;
    String gymHour = gpd.gym.orario ?? 'N/D';
    String gymAddress = gpd.gym.indirizzo ?? 'N/D';
    String gymCell = gpd.gym.telefono?.toString() ?? 'N/D';

    return Scaffold(
      appBar: screenWidth > 500
          ? AppBar(
              title: const Center(
                  child:
                      SizedBox(width: 800, child: Text('Dettagli Palestra'))),
              elevation: 0,
              backgroundColor: Colors.transparent,
            )
          : AppBar(
              title: const Text('Dettagli Palestra'),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 500) {
            return _buildWideContainers(gymName, gymHour, gymAddress, gymCell);
          } else {
            return _buildNormalContainer(gymName, gymHour, gymAddress, gymCell);
          }
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color.fromARGB(255, 0, 143, 30),
            size: 24,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> getAllowedCoachNames() async {
    GymProvider gpd = Provider.of<GymProvider>(context, listen: false);
    QuerySnapshot coachSnapshot = await FirebaseFirestore.instance
        .collection('coach')
        .where('palestra', isEqualTo: gpd.gym.uid)
        .get();

    allowedCoaches.clear();

    for (QueryDocumentSnapshot doc in coachSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String coachName = data['nome'] ?? 'Nome non disponibile';
      String coachId = doc.id;
      String start = data['inizio'] ?? 'Orario di inizio non disponibile';
      String end = data['fine'] ?? 'Orario di fine non disponibile';

      allowedCoaches.add({
        'coachId': coachId,
        'coachName': coachName,
        'start': start,
        'end': end,
      });
    }
    setState(() {
      allowedCoaches;
    });
  }

  Widget dropCoach2() {
    return DropdownButton<Map<String, String>>(
      value: selectedCoach2,
      items: allowedCoaches.map<DropdownMenuItem<Map<String, String>>>(
          (Map<String, String> coach) {
        return DropdownMenuItem<Map<String, String>>(
          value: coach,
          child: Text(coach['coachName'] ?? 'Nome non disponibile'),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedCoach2 = newValue;
        });
      },
    );
  }

  Widget dropHour() {
    List<int> hours = [
      for (int i = int.parse(selectedCoach!['start']!);
          i < int.parse(selectedCoach!['end']!);
          i++)
        i
    ];

    return DropdownButton<String>(
      value: selectedHour,
      items: hours
          .where((hour) => bookings!.every(
              (booking) => int.tryParse(booking.data()['inizio']) != hour))
          .map((e) => DropdownMenuItem<String>(
                value: e.toString(),
                child: Text('${e.toString()}:00-${(e + 1).toString()}:00'),
              ))
          .toList(),
      onChanged: (newValue) {
        setState(() {
          selectedHour = newValue;
        });
      },
    );
  }

  void submit2() async {
    final isValid = _form2.currentState!.validate();

    if (!isValid) {
      return;
    }

    _form2.currentState!.save();
    setState(() {
      _isSending2 = true;
    });

    try {
      if (selectedCoach2 == null) {
        _isSending2 = false;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Errore. Controlla se tutti i campi sono corretti')));
        return;
      }
      await FirebaseFirestore.instance.collection('requests').add({
        'coachId': selectedCoach2!['coachId'],
        'nota': _enteredNote,
        'userid': FirebaseAuth.instance.currentUser!.uid,
        'added': false
      });
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }

      setState(() {
        _isSending2 = false;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Richiesta scheda completata')));
        _form2.currentState!.reset();
      });
    } on FirebaseAuthException catch (error) {
      if (error.code == 'error') {}
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message ?? 'failed')));
      setState(() {
        _isSending2 = false;
      });
    }
  }

  Widget _buildWideContainers(
      String gymName, String gymHour, String gymAddress, String gymCell) {
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
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Richiedi Scheda',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Form(
                            key: _form2,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Text('Inserisci istruttore: '),
                                    dropCoach2(),
                                  ],
                                ),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Note',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  textCapitalization: TextCapitalization.none,
                                  onSaved: (value) {
                                    _enteredNote = value!;
                                  },
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                          onPressed: () {
                                            submit2();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.all(16),
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 0, 143, 30),
                                          ),
                                          child: _isSending2
                                              ? const SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                              : const Text(
                                                  'Richiedi scheda',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.business, 'Nome palestra', gymName),
                      Divider(color: Colors.grey.shade300, thickness: 1),
                      _buildInfoRow(Icons.access_time, 'Orario', gymHour),
                      Divider(color: Colors.grey.shade300, thickness: 1),
                      _buildInfoRow(Icons.location_on, 'Indirizzo', gymAddress),
                      Divider(color: Colors.grey.shade300, thickness: 1),
                      _buildInfoRow(Icons.phone, 'Telefono', gymCell),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalContainer(
      String gymName, String gymHour, String gymAddress, String gymCell) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Richiedi Scheda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Form(
                  key: _form2,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Inserisci istruttore: '),
                          dropCoach2(),
                        ],
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        onSaved: (value) {
                          _enteredNote = value!;
                        },
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                                onPressed: () {
                                  submit2();
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  backgroundColor:
                                      const Color.fromARGB(255, 0, 143, 30),
                                ),
                                child: _isSending2
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(),
                                      )
                                    : const Text(
                                        'Richiedi scheda',
                                        style: TextStyle(color: Colors.white),
                                      )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.business, 'Nome palestra', gymName),
            Divider(color: Colors.grey.shade300, thickness: 1),
            _buildInfoRow(Icons.access_time, 'Orario', gymHour),
            Divider(color: Colors.grey.shade300, thickness: 1),
            _buildInfoRow(Icons.location_on, 'Indirizzo', gymAddress),
            Divider(color: Colors.grey.shade300, thickness: 1),
            _buildInfoRow(Icons.phone, 'Telefono', gymCell),
          ],
        ),
      ),
    );
  }
}
