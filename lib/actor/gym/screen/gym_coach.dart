import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:univeristy/actor/gym/screen/gym_add_coach.dart';
import 'package:univeristy/provider/gym_provider.dart';
import '../../../provider/category_provider.dart';

class GymCoach extends StatefulWidget {
  const GymCoach({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GymCoachState();
  }
}

class _GymCoachState extends State<GymCoach> {
  String _name = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    CategoryProvider cat =
        Provider.of<CategoryProvider>(context, listen: false);
    GymProvider gymProv = Provider.of<GymProvider>(context, listen: false);

    User? user = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance
        .collection(cat.category!)
        .doc(user!.uid)
        .get()
        .then(
      (userData) {
        setState(() {
          gymProv.gym.uid = user.uid;
          gymProv.gym.nome = userData.data()?['nome'];
          gymProv.gym.user = userData.data()?['users'];
          gymProv.gym.email = userData.data()?['email'];
          gymProv.gym.password = userData.data()?['password'];
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: screenWidth > 500
          ? AppBar(
              title: Center(
                child: SizedBox(
                  width: 600,
                  child: Card(
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Cerca...',
                      ),
                      onChanged: (val) {
                        setState(() {
                          _name = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
              actions: const [],
            )
          : AppBar(
              title: Card(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Cerca...',
                  ),
                  onChanged: (val) {
                    setState(() {
                      _name = val;
                    });
                  },
                ),
              ),
              actions: const [],
            ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 500) {
            return Scaffold(
              body: Center(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: Colors.grey, width: 2.0),
                    ),
                  ),
                  width: 800,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: returnCoach(),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom:
                            16, // Puoi regolare la posizione del pulsante come desideri
                        right: 16,
                        child: FloatingActionButton(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const GymAddCoach(),
                              ),
                            );
                          },
                          child: const Icon(Icons.add),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Scaffold(
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GymAddCoach(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
              body: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                        16.0, 16.0, 16.0, 8.0), // Reduced bottom padding
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align text to the left
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: returnCoach(),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget returnCoach() {
    User? user = FirebaseAuth.instance.currentUser;

    // ...

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 500) {
          return Center(
            child: SizedBox(
              width: 800,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('coach')
                    .where('palestra', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  return (snapshot.connectionState == ConnectionState.waiting)
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: ((context, index) {
                            var data = snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                            if (_name.isEmpty ||
                                data['nome']
                                    .toString()
                                    .toLowerCase()
                                    .startsWith(_name.toLowerCase()) ||
                                data['email']
                                    .toString()
                                    .toLowerCase()
                                    .startsWith(_name.toLowerCase()) ||
                                data['cognome']
                                    .toString()
                                    .toLowerCase()
                                    .startsWith(_name.toLowerCase())) {
                              return ListTile(
                                title: Text(
                                  '${data['nome']} ${data['cognome']}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  data['email'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                trailing: ElevatedButton(
                                  child: const Text('Licenzia'),
                                  onPressed: () {
                                    permissionCoach(
                                        snapshot.data!.docs[index].id,
                                        context,
                                        data['palestra']);
                                    ScaffoldMessenger.of(context)
                                        .clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Azione completata')));
                                  },
                                ),
                              );
                            }
                            return Container();
                          }),
                        );
                },
              ),
            ),
          );
        } else {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('coach')
                .where('palestra', isEqualTo: user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              return (snapshot.connectionState == ConnectionState.waiting)
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: ((context, index) {
                        var data = snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                        if (_name.isEmpty ||
                            data['nome']
                                .toString()
                                .toLowerCase()
                                .startsWith(_name.toLowerCase()) ||
                            data['email']
                                .toString()
                                .toLowerCase()
                                .startsWith(_name.toLowerCase()) ||
                            data['cognome']
                                .toString()
                                .toLowerCase()
                                .startsWith(_name.toLowerCase())) {
                          return ListTile(
                            title: Text(
                              '${data['nome']} ${data['cognome']}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              data['email'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: ElevatedButton(
                              child: const Text('Licenzia'),
                              onPressed: () {
                                permissionCoach(snapshot.data!.docs[index].id,
                                    context, data['palestra']);
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Azione completata')));
                              },
                            ),
                          );
                        }
                        return Container();
                      }),
                    );
            },
          );
        }
      },
    );
  }

  void permissionCoach(
      String coachId, BuildContext context, String permesso) async {
    String newPermission = '';

    try {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('coach').doc(coachId);
      await userRef.update({
        'palestra': newPermission,
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error updating permission: $e');
    }
  }
}
