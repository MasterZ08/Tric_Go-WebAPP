import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import '../authentication/authentication.dart';
import '../pages/activity_log.dart';
import '../pages/dashboard.dart';
import '../pages/drivers_page.dart';
import '../pages/Each_TODA_Trips_List/trips_page.dart';
import 'dashboard.dart';

class ActivityLogger {
  final DatabaseReference _activityLogRef = FirebaseDatabase.instance.ref().child("activity_logs");

  Future<void> logActivity(String userId, String activity, String name, String email, String role) async {
    final timestamp = DateTime.now().toIso8601String();
    final newActivity = {
      'timestamp': timestamp,
      'userId': userId,
      'activity': activity,
      'name': name,
      'email': email,
      'role': role,
    };

    await _activityLogRef.push().set(newActivity);
  }
}

ActivityLogger activityLogger = ActivityLogger(); // Initialize the ActivityLogger

class Sub_Admin_Panel extends StatefulWidget {

  const Sub_Admin_Panel({super.key});

  @override

  State<Sub_Admin_Panel> createState() => _Sub_Admin_PanelState();
}

class _Sub_Admin_PanelState extends State<Sub_Admin_Panel>


{
  Widget chosenScreen = Dashboard();

  //for landing page

  sendAdminTo(selectedPage){
    switch(selectedPage.route)
    {
      case DashboardPage.Id:
        setState(() {
          chosenScreen = DashboardPage();
        });
        break;

      case DriversPage.Id:
        setState(() {
          chosenScreen = DriversPage();
        });
        break;

      case TripsPage.Id:
        setState(() {
          chosenScreen = TripsPage();
        });
        break;

      case ActivityLog.Id:
        setState(() {
          chosenScreen = ActivityLog();
        });
        break;
    }
  }
  void _confirmSignOut(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.logout,
                  size: 50,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                Text(
                  "Are you sure you want to log out?",
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop(); // Close the dialog

                        // Sign out and navigate to the Authentication page
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => Authentication()),
                              (route) => false,
                        );

                        if (user != null) {
                          // Fetch role and name
                          final userRef = FirebaseDatabase.instance.ref().child("accounts").child(user.uid);
                          final DatabaseEvent event = await userRef.once();
                          final userData = event.snapshot.value as Map<dynamic, dynamic>?;

                          String role = 'Unknown';
                          String name = 'Unknown';

                          if (userData != null) {
                            role = userData['role']?.toString() ?? 'Unknown';
                            name = userData['name']?.toString() ?? 'Unknown';
                          }
                          await activityLogger.logActivity(
                            user.uid,
                            'Logged out',
                            name,
                            user.email ?? 'Unknown',
                            role,
                          );

                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {

    return AdminScaffold(

      appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: const Text(
            "Sub Admin Web Panel",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )
      ),
      sideBar: SideBar(
        items:  const[

          AdminMenuItem(
            title: "Drivers List",
            route:  DriversPage.Id,
            icon: CupertinoIcons.car_detailed,
          ),

          AdminMenuItem(
            title: "Trips",
            route:  TripsPage.Id,
            icon: CupertinoIcons.location_fill,
          ),

          AdminMenuItem(
            title: "Activity Log",
            route: ActivityLog.Id,
            icon: CupertinoIcons.square_list,
          ),

        ], //act like buttons on your nav
        selectedRoute: DashboardPage.Id,
        onSelected: (selectedPage){
          sendAdminTo(selectedPage);
        },
        header: Container(
          height: 52,

          width: double.infinity,
          color: Colors.blue.shade400,

        ),
        footer: Container(
          height: 52,
          width: double.infinity,
          color: Colors.blue.shade400,
          child: IconButton(
            iconSize: 72,
            icon: const Icon(Icons.logout_rounded,size: 30),
            onPressed: () {
              _confirmSignOut(context);
            },
          ),
        ),

      ), body: chosenScreen,
    );
  }
}
