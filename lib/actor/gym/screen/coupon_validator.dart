import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Coupon extends StatefulWidget {
  const Coupon({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CouponState();
  }
}

class _CouponState extends State<Coupon> {
  final TextEditingController _couponController = TextEditingController();
  final CollectionReference _scontiCollection =
      FirebaseFirestore.instance.collection('Sconti');

  Future<void> _verifyCoupon() async {
    final couponCode = _couponController.text;

    if (couponCode.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Inserisci un codice coupon valido.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    final querySnapshot =
        await _scontiCollection.where('coupon', isEqualTo: couponCode).get();

    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      await _scontiCollection.doc(docId).delete();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).clearSnackBars();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Coupon Valido')));
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).clearSnackBars();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Coupon Invalido')));
    }

    _couponController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 500) {
            return Center(
              child: Container(
                width: 800,
                decoration: const BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text(
                            'Inserisci il codice coupon:',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextField(
                              controller: _couponController,
                              decoration: const InputDecoration(
                                hintText: 'Codice coupon',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _verifyCoupon,
                            child: const Text('Verifica'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Inserisci il codice coupon:',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _couponController,
                        decoration: const InputDecoration(
                          hintText: 'Codice coupon',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _verifyCoupon,
                      child: const Text('Verifica'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
