import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/coach_provider.dart';
import 'coach_home.dart';
import 'coach_profile.dart';
import 'coach_schede.dart';

class CoachScreenTab extends StatefulWidget {
  const CoachScreenTab({super.key});

  @override
  State<CoachScreenTab> createState() => _CoachScreenTabTabState();
}

class _CoachScreenTabTabState extends State<CoachScreenTab> {
  int _selectedPageIndex = 0;

  void _selectPaage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  Widget activePage = const CoachHome();
  @override
  Widget build(BuildContext context) {
    CoachProvider coachProv =
        Provider.of<CoachProvider>(context, listen: false);
    double screenWidth = MediaQuery.of(context).size.width;

    switch (_selectedPageIndex) {
      case 0:
        activePage = const CoachHome();
        break;
      case 1:
        activePage = const CoachSchede();
        break;
      case 2:
        activePage = const CoachProfile();
        break;
    }

    Widget titleText() {
      String title = 'Appuntamenti';
      if (_selectedPageIndex == 0) {
        return Text(title);
      } else if (_selectedPageIndex == 1) {
        title = 'Richieste';
        return Text(title);
      } else {
        title = '${coachProv.coach.nome} ${coachProv.coach.cognome}';
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
                    child: _navBar(),
                  )
                ],
              )
            : _navBar());
  }

  Widget _buildNormalContainer() {
    return activePage;
  }

  Widget _buildWideContainers() {
    return activePage;
  }

  Widget _navBar() {
    return NavigationBar(
      onDestinationSelected: _selectPaage,
      indicatorColor: const Color.fromARGB(255, 0, 143, 30),
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.home), label: 'Lista appuntamenti'),
        NavigationDestination(icon: Icon(Icons.add), label: 'Inserisci scheda'),
        NavigationDestination(icon: Icon(Icons.account_box), label: 'Profilo'),
      ],
      selectedIndex: _selectedPageIndex,
    );
  }
}
