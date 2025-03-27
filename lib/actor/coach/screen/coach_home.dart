import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../provider/category_provider.dart';
import '../../../provider/coach_provider.dart';

class CoachHome extends StatefulWidget {
  const CoachHome({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CoachHomeState();
  }
}

class _CoachHomeState extends State<CoachHome> {
  late final User user;
  late final Stream<QuerySnapshot> prenotazioniStream;
  final DateFormat dateFormatter = DateFormat('MM/dd/yyyy');
  bool hasValidPrenotazioni = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    user = FirebaseAuth.instance.currentUser!;
    prenotazioniStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('coachId', isEqualTo: user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    CoachProvider coachProv =
        Provider.of<CoachProvider>(context, listen: false);

    if (coachProv.coach.palestra!.isEmpty) {
      return const Center(child: Text('Niente da mostrare, permessi negati'));
    }

    return grantPermission();
  }

  void _fetchData() async {
    CategoryProvider cat =
        Provider.of<CategoryProvider>(context, listen: false);
    CoachProvider coachProv =
        Provider.of<CoachProvider>(context, listen: false);

    User? user = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance
        .collection(cat.category!)
        .doc(user!.uid)
        .get()
        .then(
      (userData) {
        setState(() {
          coachProv.coach.id = user.uid;
          coachProv.coach.nome = userData.data()!['nome'];
          coachProv.coach.cognome = userData.data()!['cognome'];
          coachProv.coach.email = userData.data()!['email'];
          coachProv.coach.palestra = userData.data()!['palestra'];
          coachProv.coach.permesso = userData.data()!['permesso'];
        });

        if (!context.mounted) {
          return;
        }
      },
    );
  }

  Widget grantPermission() {
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

  Future<String> getCoachName(String userid) async {
    final coachDoc =
        await FirebaseFirestore.instance.collection('user').doc(userid).get();
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

            final prenotazioni = snapshot.data!.docs.where((doc) {
              final prenotazioneData = doc.data() as Map<String, dynamic>;
              final data = prenotazioneData['data'].toString();
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
                final userid = prenotazioneData['userid'].toString();
                final data = prenotazioneData['data'].toString();
                final inizio = prenotazioneData['inizio'].toString();

                final inizioInt = int.parse(inizio);

                return FutureBuilder<String>(
                  future: getCoachName(userid),
                  builder: (context, coachNameSnapshot) {
                    if (coachNameSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (!coachNameSnapshot.hasData) {
                      return const SizedBox(); // Gestisci il caso di errore se necessario
                    }

                    final coachName = coachNameSnapshot.data!;
                    final orario = '$inizio:00-${inizioInt + 1}:00';

                    return Card(
                      child: ListTile(
                        title: Text('Utente: $coachName'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Data: $data'),
                            Text('Orario: $orario'),
                          ],
                        ),
                      ),
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

        final prenotazioni = snapshot.data!.docs.where((doc) {
          final prenotazioneData = doc.data() as Map<String, dynamic>;
          final data = prenotazioneData['data'].toString();
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
            final userid = prenotazioneData['userid'].toString();
            final data = prenotazioneData['data'].toString();
            final inizio = prenotazioneData['inizio'].toString();

            final inizioInt = int.parse(inizio);

            return FutureBuilder<String>(
              future: getCoachName(userid),
              builder: (context, coachNameSnapshot) {
                if (coachNameSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!coachNameSnapshot.hasData) {
                  return const SizedBox(); // Gestisci il caso di errore se necessario
                }

                final coachName = coachNameSnapshot.data!;
                final orario = '$inizio:00-${inizioInt + 1}:00';

                return Card(
                  child: ListTile(
                    title: Text('Utente: $coachName'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data: $data'),
                        Text('Orario: $orario'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
