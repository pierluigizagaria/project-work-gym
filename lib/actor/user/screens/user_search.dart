import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/user_provider.dart';

class UserSearch extends StatefulWidget {
  const UserSearch({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _UserSearchState();
  }
}

class _UserSearchState extends State<UserSearch> {
  User? user = FirebaseAuth.instance.currentUser;
  String name = "";
  bool isIconColored = false;

  @override
  Widget build(BuildContext context) {
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);
    double screenWidth = MediaQuery.of(context).size.width;

    // Check if it's the user's first access
    if (upd.user.firstAccess) {
      // Show a popup dialog for first-time users
    }

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
                          name = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
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
                      name = val;
                    });
                  },
                ),
              ),
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

  void favGym(String id, BuildContext context) async {
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);

    final isExisting = upd.user.palestre.contains(id);

    try {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('user').doc(upd.user.uid);

      if (isExisting) {
        setState(() {
          upd.user.palestre.remove(id);
        });

        // Remove the item from the array using FieldValue.arrayRemove
        await userRef.update({
          'palestre': FieldValue.arrayRemove([id]),
        });
      } else {
        setState(() {
          upd.user.palestre.add(id);
        });

        await userRef.update({
          'palestre': FieldValue.arrayUnion([id]),
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error updating user document: $e');
    }

    // Ignore if context is not mounted
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }
  }

  Widget _buildWideContainers() {
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gym').snapshots(),
      builder: (context, snapshot) {
        return (snapshot.connectionState == ConnectionState.waiting)
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Container(
                  width: 800,
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: Colors.grey, width: 2.0),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: ((context, index) {
                      var data = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;

                      if (name.isEmpty ||
                          data['nome']
                              .toString()
                              .toLowerCase()
                              .startsWith(name.toLowerCase()) ||
                          data['citta']
                              .toString()
                              .toLowerCase()
                              .startsWith(name.toLowerCase()) ||
                          data['indirizzo']
                              .toString()
                              .toLowerCase()
                              .startsWith(name.toLowerCase())) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: double.infinity, // Max width
                                  ),
                                  child: Container(
                                    color: Colors.white, // White background
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          data['nome'],
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${data['indirizzo']}, ${data['citta']}',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: Icon(
                                      upd.user.palestre.contains(
                                              snapshot.data!.docs[index].id)
                                          ? Icons
                                              .check // Change to checkmark icon if it's a favorite
                                          : Icons
                                              .add, // Change to plus icon if it's not a favorite
                                      color: upd.user.palestre.contains(
                                              snapshot.data!.docs[index].id)
                                          ? Colors
                                              .green // Green color for the checkmark when it's a favorite
                                          : Colors
                                              .grey, // Gray color for the plus icon when it's not a favorite
                                    ),
                                    onPressed: () {
                                      // Add logic to mark the gym as favorite or not
                                      favGym(snapshot.data!.docs[index].id,
                                          context);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Container();
                    }),
                  ),
                ),
              );
      },
    );
  }

  Widget _buildNormalContainer() {
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gym').snapshots(),
      builder: (context, snapshot) {
        return (snapshot.connectionState == ConnectionState.waiting)
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: ((context, index) {
                  var data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;

                  if (name.isEmpty ||
                      data['nome']
                          .toString()
                          .toLowerCase()
                          .startsWith(name.toLowerCase()) ||
                      data['citta']
                          .toString()
                          .toLowerCase()
                          .startsWith(name.toLowerCase()) ||
                      data['indirizzo']
                          .toString()
                          .toLowerCase()
                          .startsWith(name.toLowerCase())) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: double.infinity, // Max width
                              ),
                              child: Container(
                                color: Colors.white, // White background
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      data['nome'],
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${data['indirizzo']}, ${data['citta']}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: Icon(
                                  upd.user.palestre.contains(
                                          snapshot.data!.docs[index].id)
                                      ? Icons
                                          .check // Change to checkmark icon if it's a favorite
                                      : Icons
                                          .add, // Change to plus icon if it's not a favorite
                                  color: upd.user.palestre.contains(
                                          snapshot.data!.docs[index].id)
                                      ? Colors
                                          .green // Green color for the checkmark when it's a favorite
                                      : Colors
                                          .grey, // Gray color for the plus icon when it's not a favorite
                                ),
                                onPressed: () {
                                  // Add logic to mark the gym as favorite or not
                                  favGym(
                                      snapshot.data!.docs[index].id, context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Container();
                }),
              );
      },
    );
  }
}
