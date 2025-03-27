import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../provider/category_provider.dart';
import '../../../provider/coach_provider.dart';
import 'coach_add_schedule.dart';

class CoachSchede extends StatefulWidget {
  const CoachSchede({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CoachSchedeState();
  }
}

class _CoachSchedeState extends State<CoachSchede> {
  late final User user;
  late final Stream<QuerySnapshot> richiesteStream;
  final DateFormat dateFormatter = DateFormat('MM/dd/yyyy');

  @override
  void initState() {
    super.initState();
    _fetchData();
    user = FirebaseAuth.instance.currentUser!;
    richiesteStream = FirebaseFirestore.instance
        .collection('requests')
        .where('added', isEqualTo: false)
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
          stream: richiesteStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final prenotazioneData =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                final docId =
                    snapshot.data!.docs[index].id; // ID del documento Firestore

                final userid = prenotazioneData['userid'].toString();
                final nota = prenotazioneData['nota'].toString();
                final added = prenotazioneData['added'] as bool;

                // Verifica se il campo 'added' è falso
                if (!added) {
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

                      return Card(
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => InserimentoScheda(
                                    userId: userid, // Passa l'ID dell'utente
                                    requestId:
                                        docId // Passa l'ID della richiesta
                                    ),
                              ),
                            );
                          },
                          title: Text('Utente: $coachName'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nota: $nota'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  // Mostra un dialogo di conferma prima di eliminare
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title:
                                            const Text("Conferma Eliminazione"),
                                        content: const Text(
                                            "Sei sicuro di voler eliminare questo elemento? "
                                            "Una volta eliminato, non sarà possibile tornare indietro."),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text("Annulla"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: const Text("Elimina"),
                                            onPressed: () async {
                                              // Elimina il documento Firestore quando l'utente conferma
                                              await FirebaseFirestore.instance
                                                  .collection('requests')
                                                  .doc(docId)
                                                  .delete();

                                              // Chiudi il dialogo
                                              // ignore: use_build_context_synchronously
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  // Se 'added' è vero, puoi ritornare un widget vuoto o qualsiasi altra cosa necessaria.
                  return const SizedBox();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNormalContainer() {
    return StreamBuilder<QuerySnapshot>(
      stream: richiesteStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final prenotazioneData =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final docId =
                snapshot.data!.docs[index].id; // ID del documento Firestore

            final userid = prenotazioneData['userid'].toString();
            final nota = prenotazioneData['nota'].toString();
            final added = prenotazioneData['added'] as bool;

            // Verifica se il campo 'added' è falso
            if (!added) {
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

                  return Card(
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => InserimentoScheda(
                                userId: userid, // Passa l'ID dell'utente
                                requestId: docId // Passa l'ID della richiesta
                                ),
                          ),
                        );
                      },
                      title: Text('Utente: $coachName'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nota: $nota'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              // Mostra un dialogo di conferma prima di eliminare
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Conferma Eliminazione"),
                                    content: const Text(
                                        "Sei sicuro di voler eliminare questo elemento? "
                                        "Una volta eliminato, non sarà possibile tornare indietro."),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text("Annulla"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text("Elimina"),
                                        onPressed: () async {
                                          // Elimina il documento Firestore quando l'utente conferma
                                          await FirebaseFirestore.instance
                                              .collection('requests')
                                              .doc(docId)
                                              .delete();

                                          // Chiudi il dialogo
                                          // ignore: use_build_context_synchronously
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else {
              // Se 'added' è vero, puoi ritornare un widget vuoto o qualsiasi altra cosa necessaria.
              return const SizedBox();
            }
          },
        );
      },
    );
  }
}
