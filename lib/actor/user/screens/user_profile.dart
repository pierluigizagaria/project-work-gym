import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:univeristy/actor/user/screens/sales.dart';

import '../../../provider/user_provider.dart';
import 'load_image.dart';
import 'user_data.dart';

import '../../../provider/category_provider.dart';
import '../../../settings/auth.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      String userId = user!.uid;

      return Scaffold(
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth > 500) {
              return _buildWideContainers(userId);
            } else {
              return _buildNormalContainer(userId);
            }
          },
        ),
      );
    } else {
      return const Center(
        child: Text(
            'Utente non autenticato. Effettua il login per visualizzare i dati.'),
      );
    }
  }

  void _signOut(BuildContext context) {
    FirebaseAuth.instance.signOut().then((_) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const AuthScreen()));
    }).catchError((error) {
      if (error.code == 'email-already-in-use') {}
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Error')),
      );
    });
  }

  Widget _buildProfileListItem(
      IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _showInviteFriendDialog(BuildContext context, String userCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Codice Amico'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Il tuo codice amico:'),
              const SizedBox(height: 8),
              Text(
                userCode,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fai registrare un amico con il tuo codice e riceverai uno sconto.'
                'Troverai lo sconto nella sezione "Sconti". Valida lo sconto alla tua palestra affiliata. N.B. Ongi palestra decide come applicare lo sconto',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: userCode));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Codice copiato negli appunti.'),
                  ),
                );
              },
              child: const Text('Copia Codice'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  void _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedImage == null) {
      return;
    }

    // ignore: use_build_context_synchronously
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImageUploadPage()),
    );

    await uploadImageToStorage(pickedImage); // Continue uploading the image
  }

  uploadImageToStorage(XFile pickedFile) async {
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);

    if (!kIsWeb) return;
    Reference reference =
        FirebaseStorage.instance.ref().child('images/${user!.uid}');

    // Show a progress indicator on the ImageUploadPage
    try {
      UploadTask uploadTask = reference.putData(
        await pickedFile.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        // You can update the progress here if needed
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        // ignore: avoid_print
        print('Caricamento immagine: $progress');
      });

      // Wait for the upload to complete
      await uploadTask;

      // Once upload is complete, get the download URL
      String imgurl = await reference.getDownloadURL();

      DocumentReference documento =
          FirebaseFirestore.instance.collection('user').doc(user!.uid);

      // Add the new imageURL field to the document
      await documento.update({
        'imageURL': imgurl,
      });

      setState(() {
        upd.user.imageURL = imgurl;
      });

      // Navigate back to the previous page
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (error) {
      // Handle any errors that may occur during the upload
      // ignore: avoid_print
      print('Errore nel caricamento immagine: $error');
      // You can show an error message here if needed
    }
  }

  Widget _buildNormalContainer(String userId) {
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);
    CategoryProvider cat =
        Provider.of<CategoryProvider>(context, listen: false);
    return SingleChildScrollView(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(cat.category!)
            .doc(userId)
            .snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Errore durante il recupero dei dati'),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            Map<String, dynamic> userData =
                snapshot.data!.data() as Map<String, dynamic>;
            String displayName = userData['nome'] ?? 'Nome Utente';
            String surname = userData['cognome'] ?? 'Cognome';

            // Ottieni le iniziali del nome e cognome
            // ignore: unused_local_variable
            String initials = (displayName.isNotEmpty ? displayName[0] : '') +
                (surname.isNotEmpty ? surname[0] : '');

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SizedBox(
                      height: 115,
                      width: 115,
                      child: Stack(
                        clipBehavior: Clip.none,
                        fit: StackFit.expand,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.green,
                            foregroundImage: upd.user.imageURL != null
                                ? NetworkImage(upd.user.imageURL!)
                                : null,
                          ),
                          Positioned(
                              bottom: 0,
                              right: -25,
                              child: RawMaterialButton(
                                onPressed: () {
                                  _pickImage();
                                },
                                elevation: 2.0,
                                fillColor: const Color(0xFFF5F6F9),
                                padding: const EdgeInsets.all(15.0),
                                shape: const CircleBorder(),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),

                  // Informazioni utente

                  Divider(color: Colors.grey.shade300, thickness: 1),

                  // Voci separate
                  _buildProfileListItem(Icons.person, 'I miei dati', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyDataScreen()));
                  }),
                  Divider(color: Colors.grey.shade300, thickness: 1),

                  _buildProfileListItem(Icons.percent_outlined, 'Sconti', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CouponPage()));
                  }),
                  Divider(color: Colors.grey.shade300, thickness: 1),

                  // Voce "Invita un amico"
                  _buildProfileListItem(Icons.person_add, 'Invita un amico',
                      () {
                    final user = FirebaseAuth.instance.currentUser;

                    if (user != null) {
                      String userId = user.uid;
                      FirebaseFirestore.instance
                          .collection(cat.category!)
                          .doc(userId)
                          .get()
                          .then((upd) {
                        String userCode =
                            upd.data()?['userCode'] ?? 'Nessun codice';
                        _showInviteFriendDialog(context, userCode);
                      });
                    }
                  }),

                  Divider(color: Colors.grey.shade300, thickness: 1),

                  // Voce "Esci"
                  _buildProfileListItem(Icons.logout, 'Esci', () {
                    _signOut(context); // Azione da eseguire al tocco di "Esci"
                  }),

                  Divider(color: Colors.grey.shade300, thickness: 1),
                ],
              ),
            );
          } else {
            return const Center(
              child: Text('Dati dell\'utente non trovati.'),
            );
          }
        },
      ),
    );
  }

  Widget _buildWideContainers(String userId) {
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);
    CategoryProvider cat =
        Provider.of<CategoryProvider>(context, listen: false);
    return Center(
      child: Container(
        decoration: const BoxDecoration(
          border: Border.symmetric(
            vertical: BorderSide(color: Colors.grey, width: 2.0),
          ),
        ),
        width: 800,
        child: Center(
          child: SingleChildScrollView(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(cat.category!)
                  .doc(userId)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Errore durante il recupero dei dati'),
                  );
                }

                if (snapshot.hasData && snapshot.data != null) {
                  Map<String, dynamic> userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  String displayName = userData['nome'] ?? 'Nome Utente';
                  String surname = userData['cognome'] ?? 'Cognome';

                  // Ottieni le iniziali del nome e cognome
                  // ignore: unused_local_variable
                  String initials =
                      (displayName.isNotEmpty ? displayName[0] : '') +
                          (surname.isNotEmpty ? surname[0] : '');

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: SizedBox(
                            height: 115,
                            width: 115,
                            child: Stack(
                              clipBehavior: Clip.none,
                              fit: StackFit.expand,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.green,
                                  foregroundImage: upd.user.imageURL != null
                                      ? NetworkImage(upd.user.imageURL!)
                                      : null,
                                ),
                                Positioned(
                                    bottom: 0,
                                    right: -25,
                                    child: RawMaterialButton(
                                      onPressed: () {
                                        _pickImage();
                                      },
                                      elevation: 2.0,
                                      fillColor: const Color(0xFFF5F6F9),
                                      padding: const EdgeInsets.all(15.0),
                                      shape: const CircleBorder(),
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),

                        // Informazioni utente

                        Divider(color: Colors.grey.shade300, thickness: 1),

                        // Voci separate
                        _buildProfileListItem(Icons.person, 'I miei dati', () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MyDataScreen()));
                        }),

                        Divider(color: Colors.grey.shade300, thickness: 1),

                        _buildProfileListItem(Icons.percent_outlined, 'Sconti',
                            () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CouponPage()));
                        }),
                        Divider(color: Colors.grey.shade300, thickness: 1),

                        // Voce "Invita un amico"
                        _buildProfileListItem(
                            Icons.person_add, 'Invita un amico', () {
                          final user = FirebaseAuth.instance.currentUser;

                          if (user != null) {
                            String userId = user.uid;
                            FirebaseFirestore.instance
                                .collection(cat.category!)
                                .doc(userId)
                                .get()
                                .then((upd) {
                              String userCode =
                                  upd.data()?['userCode'] ?? 'Nessun codice';
                              _showInviteFriendDialog(context, userCode);
                            });
                          }
                        }),

                        Divider(color: Colors.grey.shade300, thickness: 1),

                        // Voce "Esci"
                        _buildProfileListItem(Icons.logout, 'Esci', () {
                          _signOut(
                              context); // Azione da eseguire al tocco di "Esci"
                        }),

                        Divider(color: Colors.grey.shade300, thickness: 1),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                    child: Text('Dati dell\'utente non trovati.'),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
