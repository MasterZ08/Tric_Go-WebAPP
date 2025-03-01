import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../methods/common_methods.dart';

class TripsDataList extends StatefulWidget {
  const TripsDataList({super.key});

  @override
  State<TripsDataList> createState() => _TripsDataListState();
}

class _TripsDataListState extends State<TripsDataList> {
  final completedTripsRecordsFromDatabase = FirebaseDatabase.instance.ref().child("tripRequests");

  CommonMethods cMethods = CommonMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> itemsList = [];
  List<Map<String, dynamic>> filteredItemsList = [];
  int currentPage = 0;
  final int itemsPerPage = 12;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_searchTrips);
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
        String dateTime = item["publishDateTime"].toString().toLowerCase();
        String tricycleDetails = item["TricycleDetails"].toString().toLowerCase();
        return driverName.contains(query) || userName.contains(query) || dateTime.contains(query) || tricycleDetails.contains(query);
      }).toList();
      currentPage = 0; // Reset to first page on new search
    });
  }

  launchGoogleMapFromSourceToDestination(pickUpLat, pickUpLng, dropoffLat, dropOffLng) async {
    String directionAPIUrl = "https://www.google.com/maps/dir/?api=1&origin=$pickUpLat,$pickUpLng&destination=$dropoffLat,$dropOffLng&dir_action=navigate";

    if (await canLaunchUrl(Uri.parse(directionAPIUrl))) {
      await launchUrl(Uri.parse(directionAPIUrl));
    } else {
      throw "Could not launch google map";
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
              labelText: 'Search by Rider Name, User Name, Date, Time, or Tricycle Details', // Updated label
              border: OutlineInputBorder(),
            ),
          ),
        ),
        // Table headers
        Row(
          children: [
            cMethods.header(2, "Trip ID"),
            cMethods.header(2, "User/Commuter Name"),
            cMethods.header(2, "Rider Name"),
            cMethods.header(2, "Tricycle Details"),
            cMethods.header(2, "Time"),
            cMethods.header(2, "Fare"),
            cMethods.header(2, "Action"),
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
                String dateTime = item["publishDateTime"].toString().toLowerCase();
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
                              cMethods.data(
                                1,
                                Text(currentItemsList[index]["tripID"].toString()),
                              ),
                              cMethods.data(
                                1,
                                Text(currentItemsList[index]["userName"].toString()),
                              ),
                              cMethods.data(
                                1,
                                Text(currentItemsList[index]["driverName"].toString()),
                              ),
                              cMethods.data(
                                1,
                                Text(currentItemsList[index]["TricycleDetails"].toString()),
                              ),
                              cMethods.data(
                                1,
                                Text(currentItemsList[index]["publishDateTime"].toString()),
                              ),
                              cMethods.data(
                                1,
                                Text("\₱" + currentItemsList[index]["fareAmount"].toString()),
                              ),
                              cMethods.data(
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
                  // Pagination controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: currentPage > 0
                            ? () {
                          setState(() {
                            currentPage--;
                          });
                        }
                            : null,
                      ),
                      Text('Page ${currentPage + 1} of $totalPages'),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: currentPage < totalPages - 1
                            ? () {
                          setState(() {
                            currentPage++;
                          });
                        }
                            : null,
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
