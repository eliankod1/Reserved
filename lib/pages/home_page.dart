import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_appointment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, Key? key}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text(
          widget.title,
          style: GoogleFonts.pacifico(
            fontSize: 30.0,
            color: Colors.amberAccent,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.amberAccent),
            onPressed: () {
              FirebaseAuth.instance.signOut().then((value) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false);
              });
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAppointment(),
            ),
          );
        },
        backgroundColor: Colors.amberAccent,
        child: Icon(
          Icons.add,
          color: Colors.grey[850],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .orderBy('date')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amberAccent),
            );
          }

          final now = DateTime.now();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 24.0,
                ),
                const Text(
                  "Reserved",
                  style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10.0,
                ),
                const Divider(
                  color: Colors.amberAccent,
                  thickness: 2,
                ),
                const SizedBox(
                  height: 24.0,
                ),
                Expanded(
                  child: ListView(
                    children:
                        snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data =
                          document.data() as Map<String, dynamic>;
                      DateTime appointmentDate =
                          (data['date'] as Timestamp).toDate();

                      if (appointmentDate.isBefore(now)) {
                        // Delete appointments that have passed
                        FirebaseFirestore.instance
                            .collection('appointments')
                            .doc(document.id)
                            .delete();
                        return const SizedBox
                            .shrink(); // Return an empty SizedBox
                      }

                      return Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Card(
                          color: Colors.grey[850],
                          child: ListTile(
                            title: Text(
                              '${DateFormat('MMMM d, y').format(appointmentDate)} at ${DateFormat('H:mm').format(appointmentDate)}',
                              style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 7.0),
                                Text(
                                  data['service'] +
                                      ' (' +
                                      data['userName'] +
                                      ')',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon:
                                  const Icon(Icons.delete, color: Colors.white),
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('appointments')
                                    .doc(document.id)
                                    .delete();
                              },
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
