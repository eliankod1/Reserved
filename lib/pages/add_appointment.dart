import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAppointment extends StatefulWidget {
  const AddAppointment({super.key});

  @override
  _AddAppointmentState createState() => _AddAppointmentState();
}

class _AddAppointmentState extends State<AddAppointment> {
  DateTime currentMonth = DateTime.now();
  List<DateTime> availableDays = [];

  @override
  void initState() {
    super.initState();
    availableDays = getDaysInMonth(currentMonth);
  }

  DateTime selectedDate = DateTime.now();

  //usluge + trajanje u minutama
  Map<String, int> servicesDuration = {
    'Basic Haircut': 30,
    'Shave': 20,
    'Beard Trim': 15,
    'Hair Coloring': 60,
    'Hair Treatment': 45,
    'Buzz Cut': 15,
    'Fades': 40,
    'Face Cleanup': 30,
    'Head Massage': 20,
    'Hair Styling': 25
  };

  String selectedService = "Basic Haircut";
  int selectedDuration = 30;
  List<DateTime> bookedStartTimes = [];

  late QuerySnapshot snapshot;

  Future<void> fetchBookedAppointmentsForDate(DateTime date) async {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .get();

    setState(() {
      bookedStartTimes =
          snapshot.docs.map<DateTime>((doc) => doc['date'].toDate()).toList();
    });
  }

  List<String> generateTimes() {
    List<String> times = [];
    for (int i = 8; i < 20; i++) {
      for (int j = 0; j < 60; j += 30) {
        times.add(
            "${i.toString().padLeft(2, '0')}:${j.toString().padLeft(2, '0')}");
      }
    }
    return times;
  }

  bool checkIfTimeIsBooked(String time) {
    DateTime startTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(time.split(":")[0]),
        int.parse(time.split(":")[1]));

    DateTime endTime = startTime.add(Duration(minutes: selectedDuration));

    for (DateTime bookedTime in bookedStartTimes) {
      DateTime endOfBookedTime = DateTime.now();
      for (var doc in snapshot.docs) {
        if (bookedTime == doc['date'].toDate()) {
          endOfBookedTime = bookedTime.add(Duration(minutes: doc['duration']));
          break;
        }
      }
      // Check if the start or end of the new appointment falls within a booked time
      if ((startTime.isAfter(bookedTime) &&
              startTime.isBefore(endOfBookedTime)) ||
          (endTime.isAfter(bookedTime) && endTime.isBefore(endOfBookedTime)) ||
          (startTime.isBefore(bookedTime) &&
              endTime.isAfter(endOfBookedTime)) ||
          (startTime == bookedTime)) {
        return true;
      }
    }

    return false;
  }

  String getFormattedDateTime(DateTime dateTime) {
    var dateFormatter = DateFormat(
        'MMMM d, y'); // Full month name, day with ordinal suffix and year
    var timeFormatter = DateFormat('H:mm'); // 24-hour format
    String formattedDate = dateFormatter.format(dateTime);
    String formattedTime = timeFormatter.format(dateTime);
    return '$formattedDate at $formattedTime'; // e.g. "August 14, 2023 at 19:30"
  }

  void addAppointment(
      String service, DateTime date, int selectedDuration) async {
    final user = FirebaseAuth.instance.currentUser!;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    String userName =
        (userDoc.data() as Map<String, dynamic>)['name'] ?? 'unknown';

    FirebaseFirestore.instance.collection('appointments').add({
      'service': service,
      'date': date,
      'userID': FirebaseAuth.instance.currentUser!.uid,
      'duration': selectedDuration,
      'userName': userName,
    });
  }

  Future<bool> isAvailable(DateTime startTime, int duration) async {
    DateTime endTime = startTime.add(Duration(minutes: duration));

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('date', isGreaterThanOrEqualTo: startTime)
        .where('date', isLessThan: endTime)
        .get();

    if (snapshot.docs.isNotEmpty) {
      //overlap
      return false;
    }

    return true;
  }

  DateTime firstDateOfMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  List<DateTime> getDaysInMonth(DateTime date) {
    DateTime lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
    List<DateTime> days = [];

    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      DateTime currentDay = DateTime(date.year, date.month, i);
      if (currentDay.weekday != 7 && currentDay.isAfter(DateTime.now())) {
        days.add(currentDay);
      }
    }

    return days;
  }

  void changeMonth(int monthsToAdd) {
    setState(() {
      firstDateOfMonth = firstDateOfMonth.add(Duration(days: monthsToAdd * 30));
      selectedDate = firstDateOfMonth;
      fetchBookedAppointmentsForDate(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Add Appointment',
          style: TextStyle(color: Colors.amberAccent),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Select a Service',
                style: TextStyle(color: Colors.amberAccent[100])),
            const SizedBox(height: 10.0),
            const Divider(
              color: Colors.amberAccent,
              thickness: 2,
            ),
            const SizedBox(height: 10.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: servicesDuration.keys.map((service) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          selectedService = service;
                          selectedDuration = servicesDuration[service]!;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: selectedService == service
                              ? Colors.blue
                              : Colors.amberAccent,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(service),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10.0),
            const Divider(
              color: Colors.amberAccent,
              thickness: 2,
            ),
            const SizedBox(height: 10.0),
            Text('Select a Date',
                style: TextStyle(color: Colors.amberAccent[100])),
            const SizedBox(height: 10.0),
            const Divider(
              color: Colors.amberAccent,
              thickness: 2,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: firstDateOfMonth.isAfter(DateTime(
                          DateTime.now().year, DateTime.now().month, 1))
                      ? () => changeMonth(-1)
                      : null,
                  icon: const Icon(Icons.arrow_left),
                  color: Colors.amberAccent,
                ),
                Text(
                  DateFormat('MMMM y').format(firstDateOfMonth),
                  style:
                      TextStyle(color: Colors.amberAccent[100], fontSize: 18),
                ),
                IconButton(
                  onPressed: () => changeMonth(1),
                  icon: const Icon(Icons.arrow_right),
                  color: Colors.amberAccent,
                ),
              ],
            ),
            const SizedBox(
              height: 10.0,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: getDaysInMonth(firstDateOfMonth).map((date) {
                  // Extracting the day of the week as an abbreviation.
                  String dayOfWeek =
                      DateFormat('EEE').format(date).toUpperCase();

                  // Extracting the day of the month.
                  String dayOfMonth = DateFormat('d').format(date);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: OutlinedButton(
                      onPressed: () async {
                        selectedDate = date;
                        await fetchBookedAppointmentsForDate(selectedDate);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(5.0),
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: selectedDate.day == date.day &&
                                  selectedDate.month == date.month &&
                                  selectedDate.year == date.year
                              ? Colors.green
                              : Colors.amberAccent,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(dayOfMonth),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Text(dayOfWeek),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10.0),
            const Divider(
              color: Colors.amberAccent,
              thickness: 2,
            ),
            const SizedBox(height: 10.0),
            Text('Select a Time',
                style: TextStyle(color: Colors.amberAccent[100])),
            const SizedBox(height: 10.0),
            const Divider(
              color: Colors.amberAccent,
              thickness: 2,
            ),
            const SizedBox(height: 10.0),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: generateTimes().length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 24.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 2.0,
              ),
              itemBuilder: (context, index) {
                String time = generateTimes()[index];
                bool isBooked = checkIfTimeIsBooked(time);
                DateTime timeAsDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  int.parse(time.split(":")[0]),
                  int.parse(time.split(":")[1]),
                );

                return OutlinedButton(
                  onPressed: !isBooked
                      ? () {
                          setState(() {
                            selectedDate = timeAsDateTime;
                          });
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: (selectedDate.hour == timeAsDateTime.hour &&
                              selectedDate.minute == timeAsDateTime.minute)
                          ? Colors.blue
                          : (isBooked ? Colors.black : Colors.amberAccent),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: Text(time),
                );
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                if (await isAvailable(selectedDate, selectedDuration)) {
                  addAppointment(
                      selectedService, selectedDate.toUtc(), selectedDuration);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("This time slot is already booked")));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[850],
                foregroundColor: Colors.amberAccent,
              ),
              child: const Text('Book an appointment'),
            ),
          ],
        ),
      ),
    );
  }
}
