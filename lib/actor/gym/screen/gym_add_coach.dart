import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/gym_provider.dart';

final _firebase = FirebaseAuth.instance;

class GymAddCoach extends StatefulWidget {
  const GymAddCoach({super.key});

  @override
  State<GymAddCoach> createState() => _GymAddCoachState();
}

class _GymAddCoachState extends State<GymAddCoach> {
  final _form = GlobalKey<FormState>();

  var _enteredAddress = '';
  var _enteredSurename = '';
  var _enteredPhoneNumber = '';
  var _enteredEmail = '';
  var _enteredName = '';
  var _enteredPassword = '';
  bool _isSending = false;
  var _initialHour = '';
  var _finalHour = '';
  int? _selectedDay; // No default value
  bool isCoachAlreadyPresent = false;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 500) {
          return Scaffold(
            appBar: screenWidth > 500
                ? AppBar(
                    title: const Center(
                      child: SizedBox(
                          width: 800, child: Text('Aggiugni un coach')),
                    ),
                    leading: Center(
                      child: SizedBox(
                        width: 800,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ))
                : AppBar(
                    title: const Text('Aggiugni un coach'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )),
            body: Center(
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
                      CheckboxListTile(
                        title: const Text('Coach già presente nel sistema'),
                        value: isCoachAlreadyPresent,
                        onChanged: (bool? newValue) {
                          setState(() {
                            isCoachAlreadyPresent = newValue ?? false;
                          });
                        },
                      ),
                      SingleChildScrollView(
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                            labelText: 'Nome'),
                                        enableSuggestions: false,
                                        validator: (value) {
                                          if (!isCoachAlreadyPresent &&
                                              (value == null ||
                                                  value.trim().length < 2)) {
                                            return 'inserisci un nome valido( min 2 caratteri)';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _enteredName = value!;
                                        },
                                        enabled: !isCoachAlreadyPresent,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextFormField(
                                        enabled: !isCoachAlreadyPresent,
                                        decoration: const InputDecoration(
                                            labelText: 'Cognome'),
                                        enableSuggestions: false,
                                        validator: (value) {
                                          if (!isCoachAlreadyPresent &&
                                              (value == null ||
                                                  value.trim().length < 2)) {
                                            return 'inserisci un cognome valido( min 2 caratteri)';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _enteredSurename = value!;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextFormField(
                                        enabled: !isCoachAlreadyPresent,
                                        decoration: const InputDecoration(
                                            labelText: 'Telefono'),
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (!isCoachAlreadyPresent &&
                                              (value == null ||
                                                  value.trim().isEmpty)) {
                                            return 'Inserisci un numero valido';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _enteredPhoneNumber = value!;
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextFormField(
                                        enabled: !isCoachAlreadyPresent,
                                        decoration: const InputDecoration(
                                            labelText: 'Indirizzo'),
                                        validator: (value) {
                                          if (!isCoachAlreadyPresent &&
                                              (value == null ||
                                                  value.trim().isEmpty)) {
                                            return 'Inserisci un indirizzo';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _enteredAddress = value!;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                            labelText: 'Email'),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Inserisci una email valida';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _enteredEmail = value!;
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextFormField(
                                        enabled: !isCoachAlreadyPresent,
                                        decoration: const InputDecoration(
                                            labelText: 'Password'),
                                        obscureText: true,
                                        validator: (value) {
                                          if (!isCoachAlreadyPresent &&
                                              (value == null ||
                                                  value.trim().isEmpty)) {
                                            return 'Inserisci una password';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _enteredPassword = value!;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 5, top: 5),
                                        child: const Text(
                                          'Orario inizio',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: Row(
                                          textBaseline: TextBaseline.alphabetic,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: TextFormField(
                                                  maxLength: 2,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                          labelText: ''),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.trim().isEmpty) {
                                                      return 'Inserisci un orario valido';
                                                    }
                                                    final int intValue =
                                                        int.tryParse(value) ??
                                                            -1;

                                                    if (intValue < 0 ||
                                                        intValue > 23) {
                                                      return 'Inserisci un orario compreso tra 0 e 23';
                                                    }
                                                    return null;
                                                  },
                                                  onSaved: (value) {
                                                    _initialHour = value!;
                                                  },
                                                ),
                                              ),
                                            ),
                                            const Text(':00'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Add a separator between the two time inputs (optional).
                                  const SizedBox(
                                      width: 16), // Adjust the width as needed.
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 5, top: 5),
                                        child: const Text(
                                          'Orario fine',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: Row(
                                          textBaseline: TextBaseline.alphabetic,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: TextFormField(
                                                  maxLength: 2,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                          labelText: ''),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.trim().isEmpty) {
                                                      return 'Inserisci un orario valido';
                                                    }
                                                    final int intValue =
                                                        int.tryParse(value) ??
                                                            -1;

                                                    if (intValue < 0 ||
                                                        intValue > 23) {
                                                      return 'Inserisci un orario compreso tra 0 e 23';
                                                    }
                                                    return null;
                                                  },
                                                  onSaved: (value) {
                                                    _finalHour = value!;
                                                  },
                                                ),
                                              ),
                                            ),
                                            const Text(':00'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Add DropdownButton for selecting the free day
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: DropdownButtonFormField<int>(
                                        value: _selectedDay,
                                        onChanged: (newValue) {
                                          setState(() {
                                            _selectedDay = newValue!;
                                          });
                                        },
                                        items: const [
                                          DropdownMenuItem<int>(
                                            value: 1,
                                            child: Text('Lunedi'),
                                          ),
                                          DropdownMenuItem<int>(
                                            value: 2,
                                            child: Text('Martedi'),
                                          ),
                                          DropdownMenuItem<int>(
                                            value: 3,
                                            child: Text('Mercoledi'),
                                          ),
                                          DropdownMenuItem<int>(
                                            value: 4,
                                            child: Text('Giovedi'),
                                          ),
                                          DropdownMenuItem<int>(
                                            value: 5,
                                            child: Text('Venerdi'),
                                          ),
                                          DropdownMenuItem<int>(
                                            value: 6,
                                            child: Text('Sabato'),
                                          ),
                                        ],
                                        decoration: const InputDecoration(
                                            labelText: 'Giorno libero'),
                                        validator: (value) {
                                          if (value == null) {
                                            return 'Inserisci un giorno libero';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _submit(
                                      isCoachAlreadyPresent,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 12),
                                    minimumSize: const Size(120, 0),
                                  ),
                                  child: _isSending
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(),
                                        )
                                      : const Text('Invia'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
                title: const Text('Aggiungi un coach'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )),
            body: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Coach già presente nel sistema'),
                  value: isCoachAlreadyPresent,
                  onChanged: (bool? newValue) {
                    setState(() {
                      isCoachAlreadyPresent = newValue ?? false;
                    });
                  },
                ),
                SingleChildScrollView(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  decoration:
                                      const InputDecoration(labelText: 'Nome'),
                                  enableSuggestions: false,
                                  validator: (value) {
                                    if (!isCoachAlreadyPresent &&
                                        (value == null ||
                                            value.trim().length < 2)) {
                                      return 'inserisci un nome valido( min 2 caratteri)';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredName = value!;
                                  },
                                  enabled: !isCoachAlreadyPresent,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  enabled: !isCoachAlreadyPresent,
                                  decoration: const InputDecoration(
                                      labelText: 'Cognome'),
                                  enableSuggestions: false,
                                  validator: (value) {
                                    if (!isCoachAlreadyPresent &&
                                        (value == null ||
                                            value.trim().length < 2)) {
                                      return 'inserisci un cognome valido( min 2 caratteri)';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredSurename = value!;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  enabled: !isCoachAlreadyPresent,
                                  decoration: const InputDecoration(
                                      labelText: 'Telefono'),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (!isCoachAlreadyPresent &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'Inserisci un numero valido';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredPhoneNumber = value!;
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  enabled: !isCoachAlreadyPresent,
                                  decoration: const InputDecoration(
                                      labelText: 'Indirizzo'),
                                  validator: (value) {
                                    if (!isCoachAlreadyPresent &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'Inserisci un indirizzo';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredAddress = value!;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  decoration:
                                      const InputDecoration(labelText: 'Email'),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Inserisci una email valida';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredEmail = value!;
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  enabled: !isCoachAlreadyPresent,
                                  decoration: const InputDecoration(
                                      labelText: 'Password'),
                                  obscureText: true,
                                  validator: (value) {
                                    if (!isCoachAlreadyPresent &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'Inserisci una password';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredPassword = value!;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.only(left: 5, top: 5),
                                  child: const Text(
                                    'Orario inizio',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Row(
                                    textBaseline: TextBaseline.alphabetic,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8.0),
                                          child: TextFormField(
                                            maxLength: 2,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                                labelText: ''),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return 'Inserisci un orario valido';
                                              }
                                              final int intValue =
                                                  int.tryParse(value) ?? -1;

                                              if (intValue < 0 ||
                                                  intValue > 23) {
                                                return 'Inserisci un orario compreso tra 0 e 23';
                                              }
                                              return null;
                                            },
                                            onSaved: (value) {
                                              _initialHour = value!;
                                            },
                                          ),
                                        ),
                                      ),
                                      const Text(':00'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Add a separator between the two time inputs (optional).
                            const SizedBox(
                                width: 16), // Adjust the width as needed.
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.only(left: 5, top: 5),
                                  child: const Text(
                                    'Orario fine',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Row(
                                    textBaseline: TextBaseline.alphabetic,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8.0),
                                          child: TextFormField(
                                            maxLength: 2,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                                labelText: ''),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return 'Inserisci un orario valido';
                                              }
                                              final int intValue =
                                                  int.tryParse(value) ?? -1;

                                              if (intValue < 0 ||
                                                  intValue > 23) {
                                                return 'Inserisci un orario compreso tra 0 e 23';
                                              }
                                              return null;
                                            },
                                            onSaved: (value) {
                                              _finalHour = value!;
                                            },
                                          ),
                                        ),
                                      ),
                                      const Text(':00'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Add DropdownButton for selecting the free day
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: DropdownButtonFormField<int>(
                                  value: _selectedDay,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedDay = newValue!;
                                    });
                                  },
                                  items: const [
                                    DropdownMenuItem<int>(
                                      value: 1,
                                      child: Text('Lunedi'),
                                    ),
                                    DropdownMenuItem<int>(
                                      value: 2,
                                      child: Text('Martedi'),
                                    ),
                                    DropdownMenuItem<int>(
                                      value: 3,
                                      child: Text('Mercoledi'),
                                    ),
                                    DropdownMenuItem<int>(
                                      value: 4,
                                      child: Text('Giovedi'),
                                    ),
                                    DropdownMenuItem<int>(
                                      value: 5,
                                      child: Text('Venerdi'),
                                    ),
                                    DropdownMenuItem<int>(
                                      value: 6,
                                      child: Text('Sabato'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                      labelText: 'Giorno libero'),
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Inserisci un giorno libero';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              _submit(
                                isCoachAlreadyPresent,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              minimumSize: const Size(120, 0),
                            ),
                            child: _isSending
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(),
                                  )
                                : const Text('Invia'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  void _submit(bool isCoachAlreadyPresent) async {
    GymProvider gymProv = Provider.of<GymProvider>(context, listen: false);

    User? user = FirebaseAuth.instance.currentUser;
    String id = user!.uid;

    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }

    _form.currentState!.save();
    setState(() {
      _isSending = true;
    });

    try {
      if (isCoachAlreadyPresent) {
        // Esegui la logica per l'aggiornamento del coach esistente
        final emailQuerySnapshot = await FirebaseFirestore.instance
            .collection('coach')
            .where('email', isEqualTo: _enteredEmail)
            .where('palestra', isEqualTo: '')
            .get();

        if (emailQuerySnapshot.docs.isNotEmpty) {
          final coachDoc = emailQuerySnapshot.docs.first;
          final coachId = coachDoc.id;

          await FirebaseFirestore.instance
              .collection('coach')
              .doc(coachId)
              .update({
            'inizio': _initialHour,
            'fine': _finalHour,
            'giornoLibero': _selectedDay,
            'palestra': id,
          });

          setState(() {
            _isSending = false;
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aggiornamento completato')));
            _form.currentState!.reset();
          });
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Impossibile continuare. Verificare e-mail inserita')));
          setState(() {
            _isSending = false;
          });
        }
      } else {
        // Esegui la logica per la creazione di un nuovo coach
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        await FirebaseFirestore.instance
            .collection('coach')
            .doc(userCredentials.user!.uid)
            .set({
          'email': _enteredEmail,
          'password': _enteredPassword,
          'nome': _enteredName,
          'cognome': _enteredSurename,
          'telefono': _enteredPhoneNumber,
          'indirizzo': _enteredAddress,
          'ruolo': 'coach',
          'permesso': true,
          'palestra': id,
          'inizio': _initialHour,
          'fine': _finalHour,
          'giornoLibero': _selectedDay,
        });

        setState(() {
          _selectedDay = null;
          _isSending = false;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registrazione completata')));
          _form.currentState!.reset();
          _firebase.signOut();
          _firebase.signInWithEmailAndPassword(
              email: gymProv.gym.email, password: gymProv.gym.password);
        });
      }
    } on FirebaseAuthException catch (error) {
      // Gestire gli errori di autenticazione
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message ?? 'Errore')));
      setState(() {
        _isSending = false;
      });
    }
  }
}
