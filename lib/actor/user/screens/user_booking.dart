import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PrenotazioniPage extends StatefulWidget {
  const PrenotazioniPage({Key? key}) : super(key: key);

  @override
  State<PrenotazioniPage> createState() => _PrenotazioniPageState();
}

class _PrenotazioniPageState extends State<PrenotazioniPage> {
  late final User user;
  late final Stream<QuerySnapshot> prenotazioniStream;
  final DateFormat dateFormatter = DateFormat('MM/dd/yyyy');
  bool hasValidPrenotazioni = false;
  List<DocumentSnapshot> prenotazioni = [];

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser!;
    prenotazioniStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('userid', isEqualTo: user.uid)
        .snapshots();
  }

  Future<String> getCoachName(String coachId) async {
    final coachDoc =
        await FirebaseFirestore.instance.collection('coach').doc(coachId).get();
    final coachData = coachDoc.data() as Map<String, dynamic>;
    final nome = coachData['nome'].toString();
    final cognome = coachData['cognome'].toString();
    return '$nome $cognome';
  }

  bool isDateAfterOrEqual(String date) {
    final currentDate = DateTime.now();
    final formattedCurrentDate = dateFormatter.format(currentDate);

    final parsedDate = dateFormatter.parse(date);
    final parsedCurrentDate = dateFormatter.parse(formattedCurrentDate);

    return parsedDate.isAfter(parsedCurrentDate) ||
        parsedDate.isAtSameMomentAs(parsedCurrentDate);
  }

  void removeBooking(DocumentSnapshot booking, int index) {
    // Rimuovi la prenotazione dal database
    FirebaseFirestore.instance
        .collection('bookings')
        .doc(booking.id)
        .delete()
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prenotazione rimossa'),
          action: SnackBarAction(
            label: 'Annulla rimozione',
            onPressed: () {
              // Ripristina la prenotazione nel database
              final bookingData = booking.data() as Map<String, dynamic>?;

              if (bookingData != null) {
                FirebaseFirestore.instance
                    .collection('bookings')
                    .add(bookingData);
              }

              setState(() {
                // Aggiungi nuovamente l'elemento alla lista prenotazioni
                prenotazioni.insert(index, booking);
              });
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

  Widget _buildWideContainers() {
    return Center(
      child: Container(
        width: 800,
        decoration: const BoxDecoration(
          border: Border.symmetric(
            vertical: BorderSide(color: Colors.grey, width: 2.0),
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: prenotazioniStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: hasValidPrenotazioni
                    ? const Text(
                        'Nessuna prenotazione trovata.',
                        style: TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.bold),
                      )
                    : const Text('Nessuna prenotazione valida trovata.',
                        style: TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.bold)),
              );
            }

            prenotazioni = snapshot.data!.docs.where((doc) {
              final prenotazioneData = doc.data() as Map<String, dynamic>;
              final data = prenotazioneData['data']?.toString() ?? '';
              return isDateAfterOrEqual(data);
            }).toList();

            if (prenotazioni.isEmpty) {
              hasValidPrenotazioni = false;
              return const Center(
                child: Text(
                  'Nessuna prenotazione valida trovata.',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              );
            }

            hasValidPrenotazioni = true;

            return ListView.builder(
              itemCount: prenotazioni.length,
              itemBuilder: (context, index) {
                final prenotazioneData =
                    prenotazioni[index].data() as Map<String, dynamic>;
                final coachId = prenotazioneData['coachId']?.toString() ?? '';
                final data = prenotazioneData['data']?.toString() ?? '';
                final inizio = prenotazioneData['inizio']?.toString() ?? '';
                final inizioInt = int.tryParse(inizio) ?? 0;
                final gymId = prenotazioneData['gymId'].toString();
                return FutureBuilder<String>(
                  future: getCoachName(coachId),
                  builder: (context, coachNameSnapshot) {
                    if (coachNameSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (!coachNameSnapshot.hasData) {
                      return const SizedBox();
                    }

                    final coachName = coachNameSnapshot.data!;
                    final orario = '$inizio:00-${inizioInt + 1}:00';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('coach')
                          .doc(coachId)
                          .get(),
                      builder: (context, coachSnapshot) {
                        if (coachSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (!coachSnapshot.hasData ||
                            !coachSnapshot.data!.exists) {
                          return const SizedBox();
                        }

                        final coachData =
                            coachSnapshot.data!.data() as Map<String, dynamic>;

                        // Check if 'permesso' is false
                        final palestra = coachData['palestra'].toString();

                        if (!(gymId == palestra)) {
                          return const SizedBox();
                        }

                        return Card(
                          child: Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: Text('Coach: $coachName'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Data: $data'),
                                      Text('Orario: $orario'),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  // Rimuovi l'elemento dalla lista prenotazioni
                                  removeBooking(prenotazioni[index], index);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNormalContainer() {
    return StreamBuilder<QuerySnapshot>(
      stream: prenotazioniStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: hasValidPrenotazioni
                ? const Text(
                    'Nessuna prenotazione trovata.',
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  )
                : const Text('Nessuna prenotazione valida trovata.',
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
          );
        }

        prenotazioni = snapshot.data!.docs.where((doc) {
          final prenotazioneData = doc.data() as Map<String, dynamic>;
          final data = prenotazioneData['data']?.toString() ?? '';
          return isDateAfterOrEqual(data);
        }).toList();

        if (prenotazioni.isEmpty) {
          hasValidPrenotazioni = false;
          return const Center(
            child: Text(
              'Nessuna prenotazione valida trovata.',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          );
        }

        hasValidPrenotazioni = true;

        return ListView.builder(
          itemCount: prenotazioni.length,
          itemBuilder: (context, index) {
            final prenotazioneData =
                prenotazioni[index].data() as Map<String, dynamic>;
            final coachId = prenotazioneData['coachId']?.toString() ?? '';
            final data = prenotazioneData['data']?.toString() ?? '';
            final inizio = prenotazioneData['inizio']?.toString() ?? '';
            final inizioInt = int.tryParse(inizio) ?? 0;
            final gymId = prenotazioneData['gymId'].toString();

            return FutureBuilder<String>(
              future: getCoachName(coachId),
              builder: (context, coachNameSnapshot) {
                if (coachNameSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!coachNameSnapshot.hasData) {
                  return const SizedBox();
                }

                final coachName = coachNameSnapshot.data!;
                final orario = '$inizio:00-${inizioInt + 1}:00';

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('coach')
                      .doc(coachId)
                      .get(),
                  builder: (context, coachSnapshot) {
                    if (coachSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (!coachSnapshot.hasData || !coachSnapshot.data!.exists) {
                      return const SizedBox();
                    }

                    final coachData =
                        coachSnapshot.data!.data() as Map<String, dynamic>;

                    // Check if 'permesso' is false
                    final palestra = coachData['palestra'].toString();

                    // Conditionally display the card
                    if (!(gymId == palestra)) {
                      return const SizedBox();
                    }

                    return Card(
                      child: Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: Text('Coach: $coachName'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Data: $data'),
                                  Text('Orario: $orario'),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              // Rimuovi l'elemento dalla lista prenotazioni
                              removeBooking(prenotazioni[index], index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
