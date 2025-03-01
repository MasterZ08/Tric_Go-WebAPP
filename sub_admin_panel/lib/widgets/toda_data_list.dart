import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../dashboard/Admin Panel Permissions/Access 2.dart';
import '../methods/common_methods.dart';

class TODADataList extends StatefulWidget {
  const TODADataList({Key? key}) : super(key: key);

  @override
  State<TODADataList> createState() => _TODADataListState();
}
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

class _TODADataListState extends State<TODADataList> {
  final todaRecordsFromDatabase = FirebaseDatabase.instance.ref().child("toda");
  final driversRecordsFromDatabase = FirebaseDatabase.instance.ref().child("accounts");

  CommonMethods cMethods = CommonMethods();

  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> itemsList = [];
  List<Map<String, dynamic>> filteredItemsList = [];
  int currentPage = 0;
  final int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_searchTODA);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _searchTODA() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredItemsList = itemsList.where((item) {
        String name = item["toda_name"].toString().toLowerCase();
        return name.contains(query);
      }).toList();
      currentPage = 0; // Reset to first page on new search
    });
  }

  //Success Delete of TODA
  void showSuccessDialog(BuildContext context, User? user) {  // Pass user as a parameter
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white60.withOpacity(0.9),
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          content: Container(
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.check_circle,
                  size: 50,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Successfully Deleted",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();

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
                        'Remove a TODA',
                        name,
                        user.email ?? 'Unknown',
                        role,
                      );
                    }
                  },
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
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search by TODA Name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        // Table headers
        Row(
          children: [
            header(4, "TODA Name"),
            header(4, "Area of Service"),
            header(3, "TODA Abbreviation"),
            header(2, "Actions"),
          ],
        ),
        // TODA list
        Expanded(
          child: StreamBuilder(
            stream: todaRecordsFromDatabase.onValue,
            builder: (BuildContext context, snapshotData) {
              if (snapshotData.hasError) {
                return const Center(
                  child: Text(
                    "Error Occurred. Try Later.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.pink,
                    ),
                  ),
                );
              }

              if (snapshotData.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshotData.data == null || snapshotData.data!.snapshot.value == null) {
                return const Center(
                  child: Text(
                    "No data available",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                );
              }

              Map dataMap = snapshotData.data!.snapshot.value as Map;
              itemsList = [];
              dataMap.forEach((key, value) {
                itemsList.add({"key": key, ...value});
              });

              // Filtered list
              filteredItemsList = itemsList.where((item) {
                String query = searchController.text.toLowerCase();
                String name = item["toda_name"].toString().toLowerCase();
                return name.contains(query);
              }).toList();

              int totalPages = (filteredItemsList.length / itemsPerPage).ceil();
              int startIndex = currentPage * itemsPerPage;
              int endIndex = startIndex + itemsPerPage;
              List<Map<String, dynamic>> currentItemsList = filteredItemsList.sublist(startIndex, endIndex.clamp(0, filteredItemsList.length));

              if (currentItemsList.isEmpty) {
                return Center(
                  child: Text(
                    "No TODA Found",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: currentItemsList.length,
                      itemBuilder: ((context, index) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            data(
                              4,
                              Text(currentItemsList[index]["toda_name"].toString()),
                            ),
                            data(
                              4,
                              Text(currentItemsList[index]["area_service"].toString()),
                            ),
                            data(
                              3,
                              Text(currentItemsList[index]["toda_abbreviation"].toString()),
                            ),
                            data(
                              2,
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: Colors.white60.withOpacity(0.9),
                                        contentPadding: const EdgeInsets.all(20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        content: Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 400,
                                            maxHeight: 300,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              const Icon(
                                                Icons.warning,
                                                size: 50,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(height: 20),
                                              const Text(
                                                "Are you sure you want to delete this TODA?",
                                                style: TextStyle(
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
                                                      "No",
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
                                                      "Yes",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    onPressed: () async {
                                                      todaRecordsFromDatabase
                                                          .child(currentItemsList[index]["key"])
                                                          .remove();
                                                      Navigator.of(context).pop();
                                                      showSuccessDialog(context, FirebaseAuth.instance.currentUser);

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
                                },
                                icon: const Icon(Icons.delete),
                                label: const Text("Delete"),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  // Pagination controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: currentPage > 0
                            ? () {
                          setState(() {
                            currentPage--;
                          });
                        }
                            : null,
                        icon: Icon(Icons.arrow_back),
                      ),
                      Text('${currentPage + 1} of $totalPages'),
                      IconButton(
                        onPressed: currentPage < totalPages - 1
                            ? () {
                          setState(() {
                            currentPage++;
                          });
                        }
                            : null,
                        icon: Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
Widget header(int flex, String title) {
  return Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: Colors.blueAccent,
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

Widget data(int flex, Widget child) {
  return Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Center(child: child),
    ),
  );
}

