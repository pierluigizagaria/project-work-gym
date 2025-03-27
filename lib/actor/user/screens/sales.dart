import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import 'package:firebase_auth/firebase_auth.dart';

class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: screenWidth > 500
          ? AppBar(
              title: const Text('I Tuoi Coupon'),
            )
          : AppBar(
              title: const Center(
                  child: SizedBox(width: 800, child: Text('I Tuoi Coupon'))),
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

  Widget _buildNormalContainer() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Sconti')
          .where('userId',
              isEqualTo: currentUser!.uid) // Filter by current user's ID

          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Nessun coupon disponibile.'),
          );
        }

        return ListView(
          children: snapshot.data!.docs.map((couponDoc) {
            final couponData = couponDoc.data() as Map<String, dynamic>;
            final coupon = couponData['coupon'] as String;
            final isUsed = couponData['isUsed'] as bool;

            return ListTile(
              title: Text(coupon),
              subtitle: isUsed
                  ? const Text('Coupon utilizzato')
                  : const Text('Coupon non utilizzato'),
            );
          }).toList(),
        );
      },
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
              .collection('Sconti')
              .where('userId',
                  isEqualTo: currentUser!.uid) // Filter by current user's ID

              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('Nessun coupon disponibile.'),
              );
            }

            return ListView(
              children: snapshot.data!.docs.map((couponDoc) {
                final couponData = couponDoc.data() as Map<String, dynamic>;
                final coupon = couponData['coupon'] as String;
                final isUsed = couponData['isUsed'] as bool;

                return ListTile(
                  title: Text(coupon),
                  subtitle: isUsed
                      ? const Text('Coupon utilizzato')
                      : const Text('Coupon non utilizzato'),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
