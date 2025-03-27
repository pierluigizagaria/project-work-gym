import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:univeristy/actor/user/screens/viusal_schedule.dart';

class VisualizzaSchede extends StatefulWidget {
  const VisualizzaSchede({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VisualizzaSchedeState();
  }
}

class _VisualizzaSchedeState extends State<VisualizzaSchede> {
  User? _currentUser; // Utente corrente

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
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
          stream: FirebaseFirestore.instance
              .collection('schede')
              .where('userId', isEqualTo: _currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('Nessuna scheda disponibile.'),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final scheda = snapshot.data!.docs[index];
                final schedaId = scheda.id;
                final coachId = scheda['coachId'];
                final data = scheda['data'];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    onTap: () {
                      // Naviga alla pagina VisualSchedule con l'ID della scheda come parametro
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              VisualSchedule(scheduleId: schedaId),
                        ),
                      );
                    },
                    title: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('coach')
                          .doc(coachId)
                          .get(),
                      builder: (context, coachSnapshot) {
                        if (!coachSnapshot.hasData) {
                          return const Text('Caricamento...');
                        }

                        final coachData =
                            coachSnapshot.data!.data() as Map<String, dynamic>;
                        final coachName = coachData['nome'];
                        final coachSurname = coachData['cognome'];

                        return Text(
                          'Istruttore: $coachName $coachSurname',
                        );
                      },
                    ),
                    subtitle: Text('Data della Scheda: $data'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // Mostra un dialogo di conferma prima di eliminare
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Conferma Eliminazione"),
                              content: const Text(
                                  "Sei sicuro di voler eliminare questa scheda? "
                                  "Una volta eliminata, non sarà possibile tornare indietro."),
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
                                    // Elimina la scheda quando l'utente conferma
                                    await FirebaseFirestore.instance
                                        .collection('schede')
                                        .doc(schedaId)
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
                  ),
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
      stream: FirebaseFirestore.instance
          .collection('schede')
          .where('userId', isEqualTo: _currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Nessuna scheda disponibile.'),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final scheda = snapshot.data!.docs[index];
            final schedaId = scheda.id;
            final coachId = scheda['coachId'];
            final data = scheda['data'];

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                onTap: () {
                  // Naviga alla pagina VisualSchedule con l'ID della scheda come parametro
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          VisualSchedule(scheduleId: schedaId),
                    ),
                  );
                },
                title: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('coach')
                      .doc(coachId)
                      .get(),
                  builder: (context, coachSnapshot) {
                    if (!coachSnapshot.hasData) {
                      return const Text('Caricamento...');
                    }

                    final coachData =
                        coachSnapshot.data!.data() as Map<String, dynamic>;
                    final coachName = coachData['nome'];
                    final coachSurname = coachData['cognome'];

                    return Text(
                      'Istruttore: $coachName $coachSurname',
                    );
                  },
                ),
                subtitle: Text('Data della Scheda: $data'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Mostra un dialogo di conferma prima di eliminare
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Conferma Eliminazione"),
                          content: const Text(
                              "Sei sicuro di voler eliminare questa scheda? "
                              "Una volta eliminata, non sarà possibile tornare indietro."),
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
                                // Elimina la scheda quando l'utente conferma
                                await FirebaseFirestore.instance
                                    .collection('schede')
                                    .doc(schedaId)
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
              ),
            );
          },
        );
      },
    );
  }
}
