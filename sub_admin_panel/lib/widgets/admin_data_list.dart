import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';


class AdminDataList extends StatefulWidget {
  const AdminDataList({Key? key}) : super(key: key);

  @override
  State<AdminDataList> createState() => _AdminDataListState();
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

ActivityLogger activityLogger = ActivityLogger(); // Initialize the ActivityLogger
class _AdminDataListState extends State<AdminDataList> {
  final driversRecordsFromDatabase = FirebaseDatabase.instance.ref().child("accounts");


  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> itemsList = [];
  List<Map<String, dynamic>> filteredItemsList = [];
  int currentPage = 0;
  final int itemsPerPage = 12;

  List<Uint8List> qrImages = []; // List to store decoded QR images

  @override
  void initState() {
    super.initState();
    searchController.addListener(_searchAdmins);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _searchAdmins() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredItemsList = itemsList.where((item) {
        String name = item["name"].toString().toLowerCase();
        return name.contains(query);
      }).toList();
      currentPage = 0; // Reset to first page on new search
    });
  }


  //success delete of admin
  void showSuccessDeleteDialog(BuildContext context) {

    User? user = FirebaseAuth.instance.currentUser;
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
                  "Deleted Successfully",
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
                        'Deleted an Admin',
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

  //success delete of admin
  void showSuccessUpdateDialog(BuildContext context) {
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
                  "Updated Successfully",
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
                  onPressed: () {
                    Navigator.of(context).pop();
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
              labelText: 'Search by Admin',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        // Table headers
        Row(
          children: [
            header(3, "Name"),
            header(3, "Email"),
            header(3, "Phone"),
            header(2, "Access"),
            header(2, "Actions"),
          ],
        ),
        // Admin list
        Expanded(
          child: StreamBuilder(
            stream: driversRecordsFromDatabase.onValue,
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

              Map dataMap = snapshotData.data!.snapshot.value as Map; // Raw data map
              itemsList = [];
              dataMap.forEach((key, value) {
                if (value["role"] == "Admin") { // Filter for sub admins
                  itemsList.add({"key": key, ...value});
                }
              });

              // Filtered list
              filteredItemsList = itemsList.where((item) {
                String query = searchController.text.toLowerCase();
                String name = item["name"].toString().toLowerCase();
                return name.contains(query);
              }).toList();
              filteredItemsList.sort((a, b) => a["name"].toString().compareTo(b["name"].toString())); // Sort filtered list


              int totalPages = (filteredItemsList.length / itemsPerPage).ceil();
              int startIndex = currentPage * itemsPerPage;
              int endIndex = startIndex + itemsPerPage;
              List<Map<String, dynamic>> currentItemsList = filteredItemsList.sublist(startIndex, endIndex.clamp(0, filteredItemsList.length));

              // Clear previous QR images
              qrImages.clear();

              currentItemsList.forEach((item) {
                try {
                  if (item["qr_image"] != null && item["qr_image"] is String) {
                    // Decode base64 QR image data to Uint8List
                    Uint8List decodedBytes = base64Decode(item["qr_image"]);
                    qrImages.add(decodedBytes);
                  } else {
                    qrImages.add(Uint8List(0)); // Add empty image if no QR code
                  }
                } catch (e) {
                  print('Error decoding QR image: $e');
                  qrImages.add(Uint8List(0)); // Add empty image if decoding fails
                }
              });

              if (currentItemsList.isEmpty) {
                return Center(
                  child: Text(
                    "No Admin Record Found",
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
                            data(3, Text(currentItemsList[index]["name"].toString())),
                            data(3, Text(currentItemsList[index]["email"].toString())),
                            data(3, Text(currentItemsList[index]["phone"].toString())),
                            data(2, Text(currentItemsList[index]["access"].toString())),
                            data(
                              2,
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                ),
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  // Assuming `currentItemsList[index]["role"]` contains the role of the admin
                                  if (currentItemsList[index]["role"] == "SuperAdmin") {
                                    // Show a dialog or message indicating that SuperAdmin cannot be deleted
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
                                              maxHeight: 200,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const <Widget>[
                                                Icon(
                                                  Icons.warning,
                                                  size: 50,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(height: 20),
                                                Text(
                                                  "Cannot delete SuperAdmin!",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.red,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                SizedBox(height: 10),
                                                Text(
                                                  "SuperAdmin accounts are protected and cannot be deleted.",
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text("OK"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    // Proceed with showing the delete confirmation dialog if not a SuperAdmin
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
                                                  "Are you sure you want to delete this ADMIN?",
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
                                                        driversRecordsFromDatabase
                                                            .child(currentItemsList[index]["key"])
                                                            .remove();
                                                        Navigator.of(context).pop();
                                                        showSuccessDeleteDialog(context);
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
                                },
                                label: const Text('Delete'),
                              ),
                            )


                        ],
                        );
                      }),
                    ),
                  ),
                  //pagination settings
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
}

