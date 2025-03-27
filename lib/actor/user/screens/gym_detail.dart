import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../provider/gym_provider.dart';

final formatter = DateFormat.yMd();

class GymDetailPage extends StatefulWidget {
  const GymDetailPage({super.key});

  @override
  State<GymDetailPage> createState() => _GymDetailPageState();
}

class _GymDetailPageState extends State<GymDetailPage> {
  String _enteredNote = '';
  bool _isSending = false;
  bool _isSending2 = false;
  DateTime? _selectedDate;
  String? selectedHour;
  final _form = GlobalKey<FormState>();
  final _form2 = GlobalKey<FormState>();
  Map<String, String>? selectedCoach;
  Map<String, String>? selectedCoach2;
  List<Map<String, String>> allowedCoaches = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? bookings;
  bool _isCoachSelected = false;

  @override
  void initState() {
    super.initState();
    getAllowedCoachNames();
  }

  @override
  Widget build(BuildContext context) {
    GymProvider gpd = Provider.of<GymProvider>(context, listen: false);

    String gymName = gpd.gym.nome;
    String gymMail = gpd.gym.email;
    String gymHour = gpd.gym.orario ?? 'N/D';
    String gymAddress = gpd.gym.indirizzo ?? 'N/D';
    String gymCell = gpd.gym.telefono?.toString() ?? 'N/D';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettagli Palestra'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.business, 'Nome palestra', gymName),
              Divider(color: Colors.grey.shade300, thickness: 1),
              _buildInfoRow(Icons.email, 'E-Mail', gymMail),
              Divider(color: Colors.grey.shade300, thickness: 1),
              _buildInfoRow(Icons.access_time, 'Orario', gymHour),
              Divider(color: Colors.grey.shade300, thickness: 1),
              _buildInfoRow(Icons.location_on, 'Indirizzo', gymAddress),
              Divider(color: Colors.grey.shade300, thickness: 1),
              _buildInfoRow(Icons.phone, 'Telefono', gymCell),
              Divider(color: Colors.grey.shade300, thickness: 1),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prenota Personal Trainer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Form(
                        key: _form,
                        child: Column(
                          children: [
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Text('Inserisci struttore: '),
                                dropCoach(),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Giorno prenotazione: '),
                                Text(_selectedDate == null
                                    ? 'No data selected'
                                    : formatter.format(_selectedDate!)),
                                IconButton(
                                  onPressed: _isCoachSelected
                                      ? _presentDatePicker
                                      : null,
                                  icon: const Icon(Icons.calendar_month),
                                ),
                                if (bookings != null) dropHour()
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                    onPressed: () {
                                      submit();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.deepPurple,
                                    ),
                                    child: _isSending
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(),
                                          )
                                        : const Text('Submit')),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedHour = null;
                                      _selectedDate = null;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.grey,
                                  ),
                                  child: const Text('Reset'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.grey, thickness: 1),
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
                                const Text('Inserisci struttore: '),
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
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                    onPressed: () {
                                      submit2();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.deepPurple,
                                    ),
                                    child: _isSending2
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(),
                                          )
                                        : const Text('Submit')),
                                ElevatedButton(
                                  onPressed: () {
                                    _form2.currentState!.reset();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.grey,
                                  ),
                                  child: const Text('Reset'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
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
            color: Colors.deepPurple,
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

  void _presentDatePicker() async {
    final firstDate =
        DateTime.now(); // Imposta la data iniziale come la data odierna
    final lastDate = DateTime(
        DateTime.now().year + 1, DateTime.now().month, DateTime.now().day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (DateTime date) {
        if (date.weekday == 7) {
          return false;
        }
        if (date.weekday == 6) {
          return false;
        }
        return true;
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }

    bookings = (await FirebaseFirestore.instance
            .collection('bookings')
            .where('coachId', isEqualTo: selectedCoach!['coachId'])
            .where('data', isEqualTo: formatter.format(_selectedDate!))
            .get())
        .docs;
    setState(() {
      bookings;
    });
  }

  Future<void> getAllowedCoachNames() async {
    GymProvider gpd = Provider.of<GymProvider>(context, listen: false);
    QuerySnapshot coachSnapshot = await FirebaseFirestore.instance
        .collection('coach')
        .where('palestra', isEqualTo: gpd.gym.uid)
        .where('permesso', isEqualTo: true)
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

  Widget dropCoach() {
    return DropdownButton<Map<String, String>>(
      value: selectedCoach,
      items: allowedCoaches.map<DropdownMenuItem<Map<String, String>>>(
          (Map<String, String> coach) {
        return DropdownMenuItem<Map<String, String>>(
          value: coach,
          child: Text(coach['coachName'] ?? 'Nome non disponibile'),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedCoach = newValue!;
          _isCoachSelected = true;
          _selectedDate = null;
          selectedHour = null;
        });
      },
    );
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

  void submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }

    _form.currentState!.save();
    setState(() {
      _isSending = true;
    });

    try {
      if (_selectedDate == null ||
          selectedHour == null ||
          selectedCoach == null) {
        _isSending = false;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Errore')));
        return;
      }
      await FirebaseFirestore.instance.collection('bookings').add({
        'coachId': selectedCoach!['coachId'],
        'data': formatter.format(_selectedDate!),
        'inizio': selectedHour,
        'userid': FirebaseAuth.instance.currentUser!.uid,
      });
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }

      setState(() {
        _isSending = false;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prenotazione completata')));
        _form.currentState!.reset();
        selectedHour = null;
        _selectedDate = null;
      });
    } on FirebaseAuthException catch (error) {
      if (error.code == 'error') {}
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message ?? 'failed')));
      setState(() {
        _isSending = false;
      });
    }
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Errore')));
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
}
