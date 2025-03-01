import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:sub_admin_panel/authentication/authentication.dart';
import 'package:sub_admin_panel/methods/common_methods.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class LTODADriversDataList extends StatefulWidget {
  const LTODADriversDataList({super.key});

  @override
  State<LTODADriversDataList> createState() => _LTODADriversDataListState();
}

class _LTODADriversDataListState extends State<LTODADriversDataList> {
  // Function to get the description based on the rating
  String _getRatingDescription(double rating) {
    if (rating == 1)
    {
      return "Bad Service";
    }   else if (rating == 2) {
      return "Good Service";
    }   else if (rating == 3) {
      return "Average Service";
    }   else if (rating == 4) {
      return "Excellent Service";
    }   else if (rating == 5) {
      return "Best Service";
    }   else {
      return "No Ratings";
    }
  }

  String _formatEarnings(dynamic earnings) {
    double earningsValue;

    if (earnings is double) {
      earningsValue = earnings;
    } else if (earnings is int) {
      earningsValue = earnings.toDouble();
    } else if (earnings is String) {
      earningsValue = double.tryParse(earnings) ?? 0.0;
    } else {
      earningsValue = 0.0; // Default value if the type is unexpected
    }

    return earningsValue.toStringAsFixed(2);
  }

  final cosdomdriversRecordsFromDatabase = FirebaseDatabase.instance.ref().child("drivers");
  final tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests");
  CommonMethods cMethods = CommonMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Initialize Firebase Auth

  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> itemsList = [];
  List<Map<String, dynamic>> filteredItemsList = [];
  int currentPage = 0;
  final int itemsPerPage = 10;
  List<dynamic> tripHistory = []; // To store the fetched trip history

  @override
  void initState() {
    super.initState();
    searchController.addListener(_searchDrivers);

  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _searchDrivers() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredItemsList = itemsList.where((item) {
        String name = item["name"].toString().toLowerCase();
        String phone = item["phone"].toString().toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
      currentPage = 0; // Reset to first page on new search
    });
  }

  Future<void> blockUserAndLogout(String driverId, BuildContext context) async {
    try {
      // Update the user's blockStatus in Firebase
      await FirebaseDatabase.instance.ref().child("drivers").child(driverId).update({
        "blockStatus": "yes",
      });

      // Get the current logged-in user's ID
      User? currentUser = _auth.currentUser;
      String? currentUserId = currentUser?.uid;

      // Check if the current user is the one being blocked
      if (currentUserId == driverId) {
        // Log out the current user
        await _auth.signOut();

        // Navigate to the login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Authentication(), // Replace with your login screen widget
          ),
        );
      }
    } catch (e) {
      print("Error blocking user and logging out: $e");
    }
  }

  Future<void> confirmAction(String message, Function action) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close the dialog
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Matching rounded corners
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(
              maxWidth: 400, // Adjust the width of the dialog box
              maxHeight: 300, // Adjust the height of the dialog box
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Confirmation",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Matching title style
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black, // Matching content style
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey, // Matching cancel button style
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent, // Matching confirm button style
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        "Confirm",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        action();
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
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search',
              border: OutlineInputBorder(),
            ),
          ),
        ),

        // Table headers
        Row(
          children: [
            header(2, "Name"),
            header(2, "Tricycle Details"),
            header(2, "Day of Coding"),
            header(2, "Phone"),
            header(2, "Total Earnings"),
            header(2, "Rating"),
            header(2, "Action"),
          ],
        ),

        // Driver List
        Expanded(
          child: StreamBuilder(
            stream: cosdomdriversRecordsFromDatabase.onValue,
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

              Map dataMap = snapshotData.data!.snapshot.value as Map;
              itemsList = [];
              dataMap.forEach((key, value) {
                if (value['toda'] == 'LTODA') {
                  itemsList.add({"id": key, ...value});
                }
              });

              // Filtered list
              filteredItemsList = itemsList.where((item) {
                String query = searchController.text.toLowerCase();
                String name = item["name"].toString().toLowerCase();
                String phone = item["phone"].toString().toLowerCase();
                return name.contains(query) || phone.contains(query);
              }).toList();

              int totalPages = (filteredItemsList.length / itemsPerPage).ceil();
              int startIndex = currentPage * itemsPerPage;
              int endIndex = startIndex + itemsPerPage;
              List<Map<String, dynamic>> currentItemsList =
              filteredItemsList.sublist(startIndex, endIndex.clamp(0, filteredItemsList.length));

              if (currentItemsList.isEmpty) {
                return Center(
                  child: Text(
                    "No Driver Found",
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
                        var tricycleDetails = currentItemsList[index]["tricycle_details"];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            data(1, Text(currentItemsList[index]["name"].toString()),),
                            data(1, Text(
                              (tricycleDetails != null
                                  ? (tricycleDetails["tricycleColor"] ?? '') + " - " +
                                  (tricycleDetails["tricycleModel"] ?? '') + " - " +
                                  (tricycleDetails["tricycleNumber"] ?? '')
                                  : ''),),),
                            data(1, Text(currentItemsList[index]["coding"].toString()),),
                            data(1, Text(currentItemsList[index]["phone"].toString()),),

                            data(
                                1,
                                currentItemsList[index]["earnings"] != null
                                    ? Text(
                                  "₱${_formatEarnings(currentItemsList[index]["earnings"])}",
                                  style: TextStyle(fontSize: 14.0), // Adjust style as needed
                                )
                                    : Text(
                                  "₱0.00",
                                  style: TextStyle(fontSize: 14.0, color: Colors.black), // Placeholder style
                                )
                            ),

                            data(
                                1,
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Display stars based on the average rating
                                      if (currentItemsList[index]["ratings"] != null &&
                                          currentItemsList[index]["ratings"]["average"] != null)
                                        Tooltip(
                                          message: _getRatingDescription(currentItemsList[index]["ratings"]["average"]),
                                          child: Row(
                                            children: [
                                              // Generate stars based on the rating
                                              ...List.generate(
                                                5,
                                                    (starIndex) => Icon(
                                                  starIndex < currentItemsList[index]["ratings"]["average"]
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 18.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Text(
                                          "No Ratings",
                                          style: TextStyle(fontSize: 14.0),
                                        ),
                                    ],
                                  ),
                                )
                            ),
                            data(
                              1,
                              currentItemsList[index]["blockStatus"] == "no"
                                  ? ElevatedButton.icon(
                                onPressed: () async {
                                  await confirmAction(
                                    "Are you sure you want to block this driver?",
                                        () async {
                                      await blockUserAndLogout(currentItemsList[index]["id"], context);
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7), // Matching rounded corners
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.block_rounded,
                                  color: Colors.black, // Matching icon color
                                  size: 20, // Adjust the icon size if needed
                                ),
                                label: const Text(
                                  "Block",
                                  style: TextStyle(
                                    color: Colors.black, // Matching text color
                                    fontWeight: FontWeight.bold, // Matching text style
                                  ),
                                ),
                              )
                                  : ElevatedButton.icon(
                                onPressed: () async {
                                  await confirmAction(
                                    "Are you sure you want to approve this driver?",
                                        () async {
                                      await FirebaseDatabase.instance
                                          .ref()
                                          .child("drivers")
                                          .child(currentItemsList[index]["id"])
                                          .update({
                                        "blockStatus": "no",
                                      });
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent, // Matching color to the "Approve" button
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7), // Matching rounded corners
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.black, // Matching icon color
                                  size: 20, // Adjust the icon size if needed
                                ),
                                label: const Text(
                                  "Approve",
                                  style: TextStyle(
                                    color: Colors.black, // Matching text color
                                    fontWeight: FontWeight.bold, // Matching text style
                                  ),
                                ),
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
