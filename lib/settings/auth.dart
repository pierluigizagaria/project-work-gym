import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:univeristy/actor/gym/screen/gym_tab.dart';
import 'package:univeristy/provider/category_provider.dart';
import 'package:univeristy/actor/coach/screen/coach_tab.dart';
import 'package:univeristy/settings/pass_reset.dart';
import 'package:univeristy/actor/user/screens/user_tab.dart';
import 'package:intl/intl.dart';
import 'dart:math';

final _firebase = FirebaseAuth.instance;
final formatter = DateFormat.yMd();

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    super.initState();
    // Controlla lo stato di autenticazione all'avvio dell'app
    checkUserAuthentication();
  }

  final _form = GlobalKey<FormState>();
  var _isSending = false;
  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPass = '';
  var _enteredPhoneNumber = '';
  var _enteredAddress = '';
  var _enteredPlaceOfBirth = '';
  DateTime? _selectedDate;
  var _enteredName = '';
  var _enteredSurename = '';
  var _validatePass = '';
  var _friendCode = ''; // Codice Amico field
  List<String> palestre = [];
  final List<Map<String, String>> options = [
    {"cliente": "user"},
    {"istruttore": "coach"},
    {"palestra": "gym"},
  ];

  String? role;
  var boe =
      ''; // Variabile per salvare l'ID dell'utente con userCode uguale a friendCode

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }

    _form.currentState!.save();
    setState(() {
      _isSending = true;
    });

    try {
      if (_isLogin) {
        // ignore: unused_local_variable
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPass);
        _check();
      } else {
        if (_enteredPass == _validatePass && _selectedDate != null) {
          // ignore: unused_local_variable
          final userCredentials =
              await _firebase.createUserWithEmailAndPassword(
                  email: _enteredEmail, password: _enteredPass);

          // Generate a random alphanumeric UserCode (8 characters)
          final random = Random();
          const codeLength = 8;
          const codeChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
          final userCode = String.fromCharCodes(Iterable.generate(codeLength,
              (_) => codeChars.codeUnitAt(random.nextInt(codeChars.length))));

          String capitalize(String input) {
            return input
                .split(' ')
                .map((word) => word.isEmpty
                    ? ''
                    : word[0].toUpperCase() + word.substring(1).toLowerCase())
                .join(' ');
          }

          // Format user input data with proper capitalization
          final userDocData = {
            'email': _enteredEmail,
            'password': _enteredPass,
            'nome': capitalize(_enteredName),
            'cognome': capitalize(_enteredSurename),
            'palestre': palestre,
            'telefono': _enteredPhoneNumber,
            'data_nascita': formatter.format(_selectedDate!),
            'luogo_nascita': capitalize(_enteredPlaceOfBirth),
            'indirizzo': capitalize(_enteredAddress),
            'role': 'user',
            'userCode': userCode,
            'firstAccess': true
          };

          // Aggiungi il campo "Codice Amico" solo se è stato inserito dall'utente
          if (_friendCode.isNotEmpty) {
            userDocData['friendCode'] = _friendCode;
          }

          await FirebaseFirestore.instance
              .collection('user')
              .doc(userCredentials.user!.uid)
              .set(userDocData);

          if (_friendCode.isNotEmpty) {
            final friendUserQuery = await FirebaseFirestore.instance
                .collection('user')
                .where('userCode', isEqualTo: _friendCode)
                .get();

            if (friendUserQuery.docs.isNotEmpty) {
              final friendUserId = friendUserQuery.docs[0].id;
              boe =
                  friendUserId; // Salviamo l'ID dell'utente con userCode uguale a friendCode in boe

              final randomCoupon = generateRandomCoupon();

              final couponData = {
                'userId': userCredentials.user!.uid,
                'coupon': randomCoupon,
                'isUsed': false,
              };

              final randomCoupon2 = generateRandomCoupon();

              final couponData2 = {
                'userId': friendUserId,
                'coupon': randomCoupon2,
                'isUsed': false,
              };

              // Crea il documento nella raccolta "Sconti" per l'utente appena registrato
              await FirebaseFirestore.instance
                  .collection('Sconti')
                  .doc()
                  .set(couponData);

              // Crea il documento nella raccolta "Sconti" anche per l'utente con lo stesso "userCode"
              await FirebaseFirestore.instance
                  .collection('Sconti')
                  .doc()
                  .set(couponData2);
            }
          }

          setState(() {
            _selectedDate = null;
            _isLogin = true;
            _isSending = false;
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registrazione completata')));
          });
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Completa correttamente tutto il form. Ricontrolla le password'),
          ));
          setState(() {
            _isSending = false;
          });
        }
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email già registrata') {}
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Autenticazione fallita')));
      setState(() {
        _isSending = false;
      });
    }
  }

  void _check() {
    CategoryProvider cat =
        Provider.of<CategoryProvider>(context, listen: false);
    if (cat.category == null) {
      setState(() {
        _isSending = false;
      });

      return;
    }
    User user = FirebaseAuth.instance.currentUser!;
    FirebaseFirestore.instance
        .collection(cat.category!)
        .doc(user.uid)
        .get()
        .then(
      (userData) {
        if (userData.exists) {
          if (userData.data()!['role'] == "user") {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const UserScreenTab()));
          } else if (userData.data()!['role'] == "coach") {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const CoachScreenTab()));
          } else if (userData.data()!['role'] == "gym") {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const GymScreenTab()));
          }
        } else {
          if (!(_enteredEmail == '' && _enteredPass == '')) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Nessun utente trovato in questa categoria. Assicurati di essere nella categoria giusta')));
          }

          setState(() {
            _isSending = false;
          });
        }
      },
    );
  }

  void _presentDatePicker() async {
    final firstDate = DateTime(1930, 01, 01);
    final lastDate = DateTime(2010, 12, 31);
    final pickedDate = await showDatePicker(
        context: context,
        initialDate: lastDate,
        firstDate: firstDate,
        lastDate: lastDate);
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  String generateRandomCoupon() {
    final random = Random();
    const codeLength = 8;
    const codeChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(Iterable.generate(codeLength,
        (_) => codeChars.codeUnitAt(random.nextInt(codeChars.length))));
  }

  Widget _register() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length < 2) {
                    return 'Inserisci un nome valido (minimo 2 caratteri)';
                  }
                  return null;
                },
                decoration: const InputDecoration(labelText: 'Nome'),
                enableSuggestions: false,
                onSaved: (value) {
                  _enteredName = value!;
                },
              ),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Expanded(
              child: TextFormField(
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length < 2) {
                    return 'Inserisci un cognome valido (minimo 2 caratteri)';
                  }
                  return null;
                },
                decoration: const InputDecoration(labelText: 'Cognome'),
                enableSuggestions: false,
                onSaved: (value) {
                  _enteredSurename = value!;
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Telefono',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci un numero valido(10 cifre)';
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredPhoneNumber = value!;
                },
              ),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Indirizzo',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci un indirizzo valido';
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredAddress = value!;
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Luogo di nascita',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci un luogo di nascita valido';
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredPlaceOfBirth = value!;
                },
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(
                    height: 5,
                  ),
                  const Text('Data di nascita'),
                  Text(_selectedDate == null
                      ? 'Nessuna data selezionata'
                      : formatter.format(_selectedDate!)),
                  const SizedBox(
                    height: 5,
                  ),
                  IconButton(
                      onPressed: _presentDatePicker,
                      icon: const Icon(Icons.calendar_month)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void checkUserAuthentication() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // L'utente è già autenticato, puoi accedere ai suoi dati o navigare alla schermata successiva
      _check();
    } else {
      // L'utente non è ancora autenticato, devi mostrare la schermata di login o registrazione
      const AuthScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth > 500) {
              return _buildWideContainers();
            } else {
              return _buildNormalContainer();
            }
          },
        ),
      ),
    );
  }

  Widget _buildNormalContainer() {
    CategoryProvider cat =
        Provider.of<CategoryProvider>(context, listen: false);

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
              child: Container(
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('lib/assets/images/logo.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(
                  20.0), // Imposta il raggio per gli angoli smussati
            ),
            width: 150, // Larghezza desiderata
            height: 150, // Altezza desiderata
          )),
          Card(
            margin: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isLogin) _register(),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Indirizzo mail',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Inserisci una e-mail valida';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredEmail = value!;
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().length < 6) {
                            return 'Almeno 6 caratteri';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredPass = value!;
                        },
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      if (_isLogin)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PasswordResetPage()),
                            );
                          },
                          child: const Text('Password dimenticata?'),
                        ),
                      if (!_isLogin)
                        TextFormField(
                          validator: (value) {
                            if (value == null || value.trim().length < 6) {
                              return 'Almeno 6 caratteri';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                              labelText: 'Conferma Password'),
                          obscureText: true,
                          onSaved: (value) {
                            _validatePass = value!;
                          },
                        ),

                      // Codice Amico TextFormField
                      if (!_isLogin)
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Codice Amico',
                          ),
                          onSaved: (value) {
                            _friendCode = value ?? '';
                          },
                        ),

                      const SizedBox(
                        height: 12,
                      ),
                      if (_isLogin)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Inserisci categoria:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 17)),
                            const SizedBox(
                              width: 10,
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 228, 226, 226)),
                              child: DropdownButton<String>(
                                dropdownColor: Colors.white,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors
                                      .green, // Colore dell'icona di freccia
                                ),
                                isDense: true,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Arial',
                                ),
                                items:
                                    options.map((Map<String, String> option) {
                                  return DropdownMenuItem<String>(
                                    value: option.values
                                        .first, // Usa il valore della mappa come valore dell'opzione
                                    child: Text(option.keys
                                        .first), // Usa la chiave della mappa come etichetta visibile
                                  );
                                }).toList(),
                                onChanged: (newValueSelected) {
                                  setState(() {
                                    cat.category = newValueSelected;
                                    role = newValueSelected;
                                  });
                                },
                                value: cat.category,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(
                        height: 12,
                      ),
                      ElevatedButton(
                        onPressed: _isSending ? null : _submit,
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer),
                        child: _isSending
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(),
                              )
                            : Text(_isLogin ? 'Login' : 'Registrati'),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextButton(
                        onPressed: _isSending
                            ? null
                            : () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                        child: Text(
                          _isLogin ? 'Crea un account' : 'Ho già un account',
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideContainers() {
    CategoryProvider cat =
        Provider.of<CategoryProvider>(context, listen: false);

    return SingleChildScrollView(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
                child: Container(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('lib/assets/images/logo.png'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(
                    20.0), // Imposta il raggio per gli angoli smussati
              ),
              width: 180, // Larghezza desiderata
              height: 180, // Altezza desiderata
            )),
            Card(
              margin: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isLogin) _register(),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Indirizzo mail',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty ||
                                !value.contains('@')) {
                              return 'Inserisci una e-mail valida';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredEmail = value!;
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().length < 6) {
                              return 'Almeno 6 caratteri';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredPass = value!;
                          },
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        if (_isLogin)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const PasswordResetPage()),
                              );
                            },
                            child: const Text('Password dimenticata?'),
                          ),
                        if (!_isLogin)
                          TextFormField(
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Almeno 6 caratteri';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                                labelText: 'Conferma Password'),
                            obscureText: true,
                            onSaved: (value) {
                              _validatePass = value!;
                            },
                          ),

                        // Codice Amico TextFormField
                        if (!_isLogin)
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Codice Amico',
                            ),
                            onSaved: (value) {
                              _friendCode = value ?? '';
                            },
                          ),

                        const SizedBox(
                          height: 12,
                        ),
                        if (_isLogin)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Stai accedendo come:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)),
                              const SizedBox(
                                width: 10,
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 228, 226, 226)),
                                child: DropdownButton<String>(
                                  dropdownColor: Colors.white,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors
                                        .green, // Colore dell'icona di freccia
                                  ),
                                  isDense: true,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    fontFamily: 'Arial',
                                  ),
                                  items:
                                      options.map((Map<String, String> option) {
                                    return DropdownMenuItem<String>(
                                      value: option.values
                                          .first, // Usa il valore della mappa come valore dell'opzione
                                      child: Text(option.keys
                                          .first), // Usa la chiave della mappa come etichetta visibile
                                    );
                                  }).toList(),
                                  onChanged: (newValueSelected) {
                                    setState(() {
                                      cat.category = newValueSelected;
                                      role = newValueSelected;
                                    });
                                  },
                                  value: cat.category,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(
                          height: 12,
                        ),
                        ElevatedButton(
                          onPressed: _isSending ? null : _submit,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer),
                          child: _isSending
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(),
                                )
                              : Text(_isLogin ? 'Login' : 'Registrati'),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        TextButton(
                          onPressed: _isSending
                              ? null
                              : () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                          child: Text(
                            _isLogin ? 'Crea un account' : 'Ho già un account',
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
