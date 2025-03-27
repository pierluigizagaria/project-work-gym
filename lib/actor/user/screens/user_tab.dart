import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:univeristy/actor/user/screens/user_booking.dart';
import 'package:univeristy/actor/user/screens/user_home.dart';
import 'package:univeristy/actor/user/screens/user_profile.dart';
import 'package:univeristy/actor/user/screens/user_schedule.dart';

import '../../../provider/category_provider.dart';
import '../../../provider/user_provider.dart';

class UserScreenTab extends StatefulWidget {
  const UserScreenTab({super.key});

  @override
  State<UserScreenTab> createState() => _UserScreenTabTabState();
}

class _UserScreenTabTabState extends State<UserScreenTab> {
  @override
  void initState() {
    CategoryProvider cat =
        Provider.of<CategoryProvider>(context, listen: false);
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);

    User? user = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance
        .collection(cat.category!)
        .doc(user!.uid)
        .get()
        .then(
      (userData) {
        // Continue with your existing code to fetch and display gym data
        setState(() {
          upd.user.uid = user.uid;
          upd.user.nome = userData.data()!['nome'];
          upd.user.cognome = userData.data()!['cognome'];
          upd.user.email = userData.data()!['email'];
          upd.user.palestre = userData.data()!['palestre'];
          upd.user.codice = userData.data()!['userCode'];
          upd.user.imageURL = userData.data()!['imageURL'];
          // Set firstAccess in UserProvider
          upd.user.firstAccess = userData.data()!['firstAccess'] ??
              true; // Get the firstAccess field
        });
      },
    );

    super.initState();
  }

  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  Widget activePage = const UserHome();
  @override
  Widget build(BuildContext context) {
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);
    double screenWidth = MediaQuery.of(context).size.width;

    switch (_selectedPageIndex) {
      case 0:
        activePage = const UserHome();
        break;
      case 1:
        activePage = const VisualizzaSchede();
        break;
      case 2:
        activePage = const PrenotazioniPage();
        break;
      case 3:
        activePage = const UserProfile();
        break;
    }

    Widget titleText() {
      String title = 'Le mie palestre';
      if (_selectedPageIndex == 0) {
        return Text(title);
      } else if (_selectedPageIndex == 1) {
        title = 'Schede';
        return Text(title);
      } else if (_selectedPageIndex == 2) {
        title = 'Prenotazioni';
        return Text(title);
      } else {
        title = '${upd.user.nome} ${upd.user.cognome}';
        return Text(title);
      }
    }

    return Scaffold(
        appBar: screenWidth > 500
            ? AppBar(
                title: Center(child: SizedBox(width: 800, child: titleText())),
              )
            : AppBar(
                title: titleText(),
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
        bottomNavigationBar: screenWidth > 500
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: min(800, screenWidth)),
                      child: _navBar()),
                ],
              )
            : _navBar());
  }

  Widget _buildWideContainers() {
    return activePage;
  }

  Widget _buildNormalContainer() {
    return activePage;
  }

  Widget _navBar() {
    UserProvider upd = Provider.of<UserProvider>(context, listen: false);
    return NavigationBar(
      onDestinationSelected: _selectPage,
      selectedIndex: _selectedPageIndex,
      // Set the color for unselected items
      indicatorColor: const Color.fromARGB(
          255, 0, 143, 30), // Set the color for selected items
      destinations: [
        const NavigationDestination(icon: Icon(Icons.home), label: 'Palestre'),
        const NavigationDestination(
            icon: Icon(Icons.sports_gymnastics), label: 'Schede'),
        const NavigationDestination(
            icon: Icon(Icons.calendar_month), label: 'Preontazioni'),
        NavigationDestination(
            icon: upd.user.imageURL != null
                ? CircleAvatar(
                    maxRadius: 16,
                    backgroundImage: NetworkImage(upd.user.imageURL!))
                : const Icon(Icons.account_box),
            label: 'Profilo'),
      ],
    );
  }
}
