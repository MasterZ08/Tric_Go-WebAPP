import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../methods/common_methods.dart';

class SATODATripsDataList extends StatefulWidget {
  const SATODATripsDataList({super.key});

  @override
  State<SATODATripsDataList> createState() => _SATODATripsDataListState();
}

class _SATODATripsDataListState extends State<SATODATripsDataList> {
  final DatabaseReference _TripsLogRef = FirebaseDatabase.instance.ref().child("tripRequests");
  final completedTripsRecordsFromDatabase = FirebaseDatabase.instance.ref().child("tripRequests");

  CommonMethods cMethods = CommonMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> itemsList = [];
  List<Map<String, dynamic>> filteredItemsList = [];
  int currentPage = 0;
  final int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_searchTrips);
    _cleanupOldRecords(); // Cleanup old records on startup
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _searchTrips() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredItemsList = itemsList.where((item) {
        String driverName = item["driverName"].toString().toLowerCase();
        String userName = item["userName"].toString().toLowerCase();
        String dateTime = _formatTimestamp(item["publishDateTime"]).toLowerCase();
        String tricycleDetails = item["TricycleDetails"].toString().toLowerCase();
        return driverName.contains(query) || userName.contains(query) || dateTime.contains(query) || tricycleDetails.contains(query);
      }).toList();
      currentPage = 0; // Reset to first page on new search
    });
  }

  Future<void> _cleanupOldRecords() async {
    final now = DateTime.now();
    final fifteenDaysAgo = now.subtract(const Duration(days: 45));

    final snapshot = await _TripsLogRef.orderByChild('publishDateTime').endAt(fifteenDaysAgo.toIso8601String()).once();

    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final updates = <String, dynamic>{};
      data.forEach((key, value) {
        updates[key] = null; // Mark the node for deletion
      });

      await _TripsLogRef.update(updates);
      print('Old activity logs deleted');
    }
  }

  String _formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
    String formattedTime = DateFormat('hh:mm a').format(dateTime);
    String dayOfWeek = DateFormat('EEEE').format(dateTime);
    return '$formattedDate ($dayOfWeek) - $formattedTime';
  }

  launchGoogleMapFromSourceToDestination(pickUpLat, pickUpLng, dropoffLat, dropOffLng) async {
    String directionAPIUrl = "https://www.google.com/maps/dir/?api=1&origin=$pickUpLat,$pickUpLng&destination=$dropoffLat,$dropOffLng&dir_action=navigate";

    if (await canLaunchUrl(Uri.parse(directionAPIUrl))) {
      await launchUrl(Uri.parse(directionAPIUrl));
    } else {
      throw "Could not launch Google Maps";
    }
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
              labelText: 'Search by Rider Name, User Name, Date, Time, or Tricycle Details',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        // Table headers
        Row(
          children: [
            header(2, "User/Commuter Name"),
            header(2, "Rider Name"),
            header(2, "Tricycle Details"),
            header(2, "Time"),
            header(2, "Pick Up Location"),
            header(2, "Drop Off Location"),
            //header(2, "Fare"),
            header(2, "Ratings"), // New column for ratings
            header(2, "Ratings Comment"), // New column for ratings comment
            header(2, "Action"),
          ],
        ),
        // Trips List
        Expanded(
          child: StreamBuilder(
            stream: completedTripsRecordsFromDatabase.onValue,
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
                // Only add the trip if the driver's TODA code is "SATODA"
                if (value["toda"] == "SATODA") {
                  itemsList.add({"key": key, ...value});
                }
              });

              // Filtered list
              filteredItemsList = itemsList.where((item) {
                String query = searchController.text.toLowerCase();
                String driverName = item["driverName"].toString().toLowerCase();
                String userName = item["userName"].toString().toLowerCase();
                String dateTime = _formatTimestamp(item["publishDateTime"]).toLowerCase();
                String tricycleDetails = item["TricycleDetails"].toString().toLowerCase();
                return driverName.contains(query) || userName.contains(query) || dateTime.contains(query) || tricycleDetails.contains(query);
              }).toList();

              int totalPages = (filteredItemsList.length / itemsPerPage).ceil();
              int startIndex = currentPage * itemsPerPage;
              int endIndex = startIndex + itemsPerPage;
              List<Map<String, dynamic>> currentItemsList = filteredItemsList.sublist(startIndex, endIndex.clamp(0, filteredItemsList.length));

              if (currentItemsList.isEmpty) {
                return Center(
                  child: Text(
                    "No Trip Record Found",
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
                        if (currentItemsList[index]["status"] != null && currentItemsList[index]["status"] == "ended") {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              data(1, Text(currentItemsList[index]["userName"].toString()),),
                              data(1, Text(currentItemsList[index]["driverName"].toString()),),
                              data(1, Text(currentItemsList[index]["TricycleDetails"].toString()),),
                              data(1, Text(_formatTimestamp(currentItemsList[index]["publishDateTime"])),), // Use the formatted date
                              //data(1, Text("\₱" + currentItemsList[index]["fareAmount"].toString()),),
                              data(
                                1,
                                Tooltip(
                                  message: currentItemsList[index]["pickUpAddress"].toString(),
                                  child: Text(
                                    currentItemsList[index]["pickUpAddress"].toString(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              data(
                                1,
                                Tooltip(
                                  message: currentItemsList[index]["dropOffAddress"].toString(),
                                  child: Text(
                                    currentItemsList[index]["dropOffAddress"].toString(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              data(
                                1,
                                currentItemsList[index]["ratings"] != null
                                    ? Row(
                                  children: List.generate(
                                    int.tryParse(currentItemsList[index]["ratings"].toString()) ?? 0,
                                        (starIndex) => Icon(Icons.star, color: Colors.amber),
                                  ),
                                )
                                    : Text("N/A"),
                              ),
                              data(
                                1,
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade50, // Match the background color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0), // Match the rounded corners
                                    ),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
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
                                                Text(
                                                  'Full Comment',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black, // Matching title color
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  currentItemsList[index]["ratingsComment"] != null
                                                      ? currentItemsList[index]["ratingsComment"].toString()
                                                      : "No Comment",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black87, // Text color to match the button's text
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.grey, // Cancel button style
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(7),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        "Close",
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(context).pop(); // Close the dialog
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
                                  icon: const Icon(
                                    Icons.comment_rounded,
                                    color: Colors.black87, // Match the icon color
                                    size: 20, // Icon size
                                  ),
                                  label: const Text(
                                    "View Comment",
                                    style: TextStyle(
                                      color: Colors.black87, // Match the text color
                                    ),
                                  ),
                                ),
                              ),

                              data(
                                1,
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                  ),
                                  onPressed: () {
                                    String pickUpLat = currentItemsList[index]["pickUpLatLng"]["latitude"];
                                    String pickUpLng = currentItemsList[index]["pickUpLatLng"]["longitude"];
                                    String dropoffLat = currentItemsList[index]["dropOffLatLng"]["latitude"];
                                    String dropOffLng = currentItemsList[index]["dropOffLatLng"]["longitude"];

                                    launchGoogleMapFromSourceToDestination(
                                      pickUpLat,
                                      pickUpLng,
                                      dropoffLat,
                                      dropOffLng,
                                    );
                                  },
                                  icon: const Icon(Icons.remove_red_eye_outlined),
                                  label: const Text("View Trip Details"),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Container();
                        }
                      }),
                    ),
                  ),
                  // Pagination
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
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

Widget data(int flex, Widget content) {
  return Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Center(child: content),
    ),
  );
}

