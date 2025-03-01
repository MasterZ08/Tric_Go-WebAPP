import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActLogDataList extends StatefulWidget {
  const ActLogDataList({Key? key}) : super(key: key);

  @override
  State<ActLogDataList> createState() => _ActLogDataListState();
}

class _ActLogDataListState extends State<ActLogDataList> {
  final DatabaseReference _activityLogRef = FirebaseDatabase.instance.ref().child("activity_logs");
  final User? currentUser = FirebaseAuth.instance.currentUser; // Get current user
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> itemsList = [];
  List<Map<String, dynamic>> filteredItemsList = [];
  int currentPage = 0;
  final int itemsPerPage = 13; // Limit to 15 items per page

  @override
  void initState() {
    super.initState();
    searchController.addListener(_searchActivities);
    _fetchActivityLogs();
    _cleanupOldRecords(); // Cleanup old records on startup
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _searchActivities() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredItemsList = itemsList.where((item) {
        String name = item["name"].toString().toLowerCase();
        return name.contains(query);
      }).toList();
      currentPage = 0; // Reset to first page on new search
    });
  }

  Future<void> _fetchActivityLogs() async {
    if (currentUser == null) {
      // Handle the case when there's no logged-in user
      return;
    }

    _activityLogRef.orderByChild("userId").equalTo(currentUser!.uid).onValue.listen((DatabaseEvent event) {
      final dataSnapshot = event.snapshot;
      if (dataSnapshot.value != null) {
        Map<dynamic, dynamic> data = dataSnapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> tempList = [];
        data.forEach((key, value) {
          tempList.add(Map<String, dynamic>.from(value));
        });

        // Sort the list by timestamp in descending order
        tempList.sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));

        setState(() {
          itemsList = tempList;
          filteredItemsList = itemsList;
        });
      }
    });
  }

  Future<void> _cleanupOldRecords() async {
    final now = DateTime.now();
    final fifteenDaysAgo = now.subtract(const Duration(days: 30)); // Corrected duration

    final snapshot = await _activityLogRef.orderByChild('timestamp').endAt(fifteenDaysAgo.toIso8601String()).once();

    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final updates = <String, dynamic>{};
      data.forEach((key, value) {
        updates[key] = null; // Mark the node for deletion
      });

      await _activityLogRef.update(updates);
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

  @override
  Widget build(BuildContext context) {
    int startIndex = currentPage * itemsPerPage;
    int endIndex = (startIndex + itemsPerPage) < filteredItemsList.length
        ? startIndex + itemsPerPage
        : filteredItemsList.length;

    return Column(
      children: [
        // Table headers
        Row(
          children: [
            header(2, "Activity"),
            header(3, "Date and Time"),
          ],
        ),
        // Admin list
        Expanded(
          child: filteredItemsList.isEmpty
              ? const Center(
            child: Text(
              "No data available",
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
              ),
            ),
          )
              : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: endIndex - startIndex,
                  itemBuilder: (context, index) {
                    final item = filteredItemsList[startIndex + index];
                    final timestamp = item["timestamp"] ?? "";
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        data(2, Text(item["activity"].toString(), style: TextStyle(fontSize: 18))), // Increased text size
                        data(3, Text(_formatTimestamp(timestamp), style: TextStyle(fontSize: 18))), // Increased text size
                      ],
                    );
                  },
                ),
              ),
              // Pagination settings
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
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text('${currentPage + 1} of ${(filteredItemsList.length / itemsPerPage).ceil()}'),
                  IconButton(
                    onPressed: currentPage < (filteredItemsList.length / itemsPerPage).ceil() - 1
                        ? () {
                      setState(() {
                        currentPage++;
                      });
                    }
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ],
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
            color: Colors.blueAccent.withOpacity(0.7), // Adjust opacity here
            borderRadius: BorderRadius.circular(8), // Rounded corners
            border: Border.all(color: Colors.black),
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
