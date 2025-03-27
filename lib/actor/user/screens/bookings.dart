import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../provider/gym_provider.dart';

final formatter = DateFormat.yMd();

class Bookings extends StatefulWidget {
  const Bookings({super.key});

  @override
  State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> {
  bool _isSending = false;
  DateTime? _selectedDate;
  String? selectedHour;
  final _form = GlobalKey<FormState>();
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
    double screenWidth = MediaQuery.of(context).size.width;
    GymProvider gpd = Provider.of<GymProvider>(context, listen: false);

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
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }

  void _presentDatePicker() async {
    final currentDate = DateTime.now();

    // Modifica il calcolo della data iniziale tenendo conto del freeDay del coach selezionato
    DateTime initialDate = currentDate.add(const Duration(days: 2));

    while (!_isSelectableDate(initialDate)) {
      initialDate = initialDate.add(const Duration(days: 1));
    }

    final lastDate =
        DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: initialDate,
      lastDate: lastDate,
      selectableDayPredicate: _isSelectableDate,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        selectedHour = null; // Reset selectedHour when the date changes
      });

      // Aggiungi un controllo qui per evitare errori quando `bookings` è null.
      if (selectedCoach != null && _selectedDate != null) {
        // Query Firestore per le prenotazioni basate sulla data e sul coach selezionati
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
    }
  }

  bool _isSelectableDate(DateTime date) {
    return date.weekday != 7 &&
        (selectedCoach != null &&
            date.weekday != int.parse(selectedCoach!['freeDay']!));
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
      int freeDay = data['freeDay'] ?? 7;
      String gymId =
          data['palestra']; // Imposta il valore predefinito a 7 (domenica)

      allowedCoaches.add({
        'coachId': coachId,
        'coachName': coachName,
        'start': start,
        'end': end,
        'freeDay': freeDay.toString(),
        'palestra': gymId
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

  Widget dropHour() {
    List<int> hours = [
      for (int i = int.parse(selectedCoach!['start']!);
          i < int.parse(selectedCoach!['end']!);
          i++)
        i
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Orario :',
            ),
            const SizedBox(
                width: 8), // Add some spacing between "Orario" and the dropdown
            DropdownButton<String>(
              value: selectedHour,
              items: hours
                  .where((hour) => bookings!.every((booking) =>
                      int.tryParse(booking.data()['inizio']) != hour))
                  .map((e) => DropdownMenuItem<String>(
                        value: e.toString(),
                        child:
                            Text('${e.toString()}:00-${(e + 1).toString()}:00'),
                      ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedHour = newValue;
                });
              },
            ),
          ],
        ),
      ],
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Errore nella prenotazione')));
        return;
      }
      await FirebaseFirestore.instance.collection('bookings').add({
        'coachId': selectedCoach!['coachId'],
        'data': formatter.format(_selectedDate!),
        'inizio': selectedHour,
        'userid': FirebaseAuth.instance.currentUser!.uid,
        'gymId': selectedCoach!['palestra']
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text('Istruttore: '),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 150, // Imposta la larghezza desiderata
                                  child: dropCoach(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text('Data: '),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedDate == null
                                        ? 'Nessuna data selezionata'
                                        : formatter.format(_selectedDate!),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _isCoachSelected
                                      ? _presentDatePicker
                                      : null,
                                  icon: const Icon(Icons.calendar_today),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_selectedDate != null && bookings != null)
                              Container(
                                margin: const EdgeInsets.only(right: 150),
                                width: 100, // Imposta la larghezza desiderata
                                child: dropHour(),
                              ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                submit();
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 143, 30),
                              ),
                              child: _isSending
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Prenota',
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.grey, thickness: 1),
                      _buildInfoRow(Icons.business, 'Nome palestra', gymName),
                      Divider(color: Colors.grey.shade300, thickness: 1),
                      _buildInfoRow(Icons.access_time, 'Orario', gymHour),
                      Divider(color: Colors.grey.shade300, thickness: 1),
                      _buildInfoRow(Icons.location_on, 'Indirizzo', gymAddress),
                      Divider(color: Colors.grey.shade300, thickness: 1),
                      _buildInfoRow(Icons.phone, 'Telefono', gymCell),
                      const SizedBox(height: 16),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Istruttore: '),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 150, // Imposta la larghezza desiderata
                        child: dropCoach(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Data: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Nessuna data selezionata'
                              : formatter.format(_selectedDate!),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        onPressed: _isCoachSelected ? _presentDatePicker : null,
                        icon: const Icon(Icons.calendar_today),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedDate != null && bookings != null)
                    Container(
                      margin: const EdgeInsets.only(right: 150),
                      width: 100, // Imposta la larghezza desiderata
                      child: dropHour(),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      submit();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: const Color.fromARGB(255, 0, 143, 30),
                    ),
                    child: _isSending
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Prenota',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey, thickness: 1),
            _buildInfoRow(Icons.business, 'Nome palestra', gymName),
            Divider(color: Colors.grey.shade300, thickness: 1),
            _buildInfoRow(Icons.access_time, 'Orario', gymHour),
            Divider(color: Colors.grey.shade300, thickness: 1),
            _buildInfoRow(Icons.location_on, 'Indirizzo', gymAddress),
            Divider(color: Colors.grey.shade300, thickness: 1),
            _buildInfoRow(Icons.phone, 'Telefono', gymCell),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
