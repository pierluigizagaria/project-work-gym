import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:univeristy/actor/gym/screen/gym_coach.dart';
import 'package:univeristy/actor/gym/screen/gym_home.dart';

import '../../../settings/auth.dart';
import 'coupon_validator.dart';

class GymScreenTab extends StatefulWidget {
  const GymScreenTab({super.key});

  @override
  State<GymScreenTab> createState() => _GymScreenTabTabState();
}

class _GymScreenTabTabState extends State<GymScreenTab> {
  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  Widget activePage = const GymHome();
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    switch (_selectedPageIndex) {
      case 0:
        activePage = const GymHome();
        break;
      case 1:
        activePage = const GymCoach();
        break;
      case 2:
        activePage = const Coupon();
        break;
      case 3:
        _signOut(context);
        break;
    }

    Widget titleText() {
      String title = 'Clienti';
      if (_selectedPageIndex == 0) {
        return Text(title);
      } else if (_selectedPageIndex == 1) {
        title = 'Coach';
        return Text(title);
      } else {
        title = 'Verifica Coupon';
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

  Widget _buildWideContainers() {
    return activePage;
  }

  Widget _buildNormalContainer() {
    return activePage;
  }

  Widget _navBar() {
    return NavigationBar(
      onDestinationSelected: _selectPage,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.add_box_sharp),
          label: 'Clienti',
        ),
        NavigationDestination(
          icon: Icon(Icons.add),
          label: 'Coach',
        ),
        NavigationDestination(
          icon: Icon(Icons.percent),
          label: 'Coupon',
        ),
        NavigationDestination(
          icon: Icon(Icons.logout),
          label: 'Logout',
        ),
      ],
      selectedIndex: _selectedPageIndex,
      // Colore delle icone quando non selezionate
      indicatorColor: const Color.fromARGB(
          255, 0, 143, 30), // Colore delle icone selezionate
    );
  }
}
