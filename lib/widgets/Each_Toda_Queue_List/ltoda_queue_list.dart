import 'package:flutter/cupertino.dart';
import 'package:sub_admin_panel/authentication/authentication.dart';
import 'package:sub_admin_panel/methods/common_methods.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:intl/intl.dart';

class LTODAQueueList extends StatefulWidget {
  const LTODAQueueList({super.key});

  @override
  State<LTODAQueueList> createState() => _LTODAQueueListState();
}
class _LTODAQueueListState extends State<LTODAQueueList> {

  final cosdomdriversRecordsFromDatabase = FirebaseDatabase.instance.ref().child("drivers");
  final tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests");
  CommonMethods cMethods = CommonMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Initialize Firebase Auth

  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> itemsList = [];
  List<Map<String, dynamic>> filteredItemsList = [];
  int currentPage = 0;
  final int itemsPerPage = 10;

// Helper function to calculate the day of the year
  int getDayOfYear(DateTime date) {
    DateTime startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

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

  void showQueueDialog(BuildContext context, Map<String, String> queuedTimestamps) {
    // Helper function to format the time and day
    String formatTimeAndDay(DateTime dateTime) {
      String formattedTime = DateFormat('hh:mm a').format(dateTime); // Format as Hour:Minute AM/PM
      String dayOfWeek = DateFormat('EEEE').format(dateTime); // Day of the week
      return 'Time: $formattedTime ($dayOfWeek)';
    }

    // Parse the current date and set it as the initial date
    DateTime selectedDate = DateTime.now();
    DateTime today = DateTime.now();
    TextEditingController dateController = TextEditingController();

    // Update the date in the controller when the selected date changes
    void updateDateController() {
      dateController.text = DateFormat('MMMM-dd-yyyy').format(selectedDate); // Month-Day-Year
    }

    // Function to display the dialog with the queue list
    void showQueueList() {
      // Filter entries for the selected date
      String selectedDayKey = DateFormat('yyyy-MM-dd').format(selectedDate); // YYYY-MM-DD for matching keys
      List<String> queueEntries = queuedTimestamps.entries
          .where((entry) => entry.value.startsWith(selectedDayKey))
          .map((entry) {
        DateTime queueDateTime = DateTime.parse(entry.value);
        return formatTimeAndDay(queueDateTime); // Only time and day
      }).toList();

      // Show the dialog
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
                maxWidth: 500,
                maxHeight: 800,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Date search bar
                  TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Select Date",
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: today,
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        selectedDate = pickedDate;
                        updateDateController();
                        Navigator.pop(context);
                        showQueueList();
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Queue list title with date
                  Text(
                    "Queue List for ${dateController.text.isEmpty ? 'Selected Date' : dateController.text}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Queue count display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Total: ${queueEntries.length}",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Queue entries list or "No Queue Recorded" message
                  if (queueEntries.isEmpty)
                    Text(
                      "No Queue Recorded",
                      style: TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: queueEntries.length,
                        itemBuilder: (context, index) => Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(fontSize: 16, color: Colors.black),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ListTile(
                                title: Text(queueEntries[index]),
                              ),
                            ),
                          ],
                        ),
                        separatorBuilder: (context, index) => Divider(color: Colors.grey[300]),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Navigation arrows with "Previous Day," "Next Day," and "Jump to Present" buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Day Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey, // Light blue background
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          selectedDate = selectedDate.subtract(Duration(days: 1));
                          updateDateController();
                          Navigator.pop(context);
                          showQueueList();
                        },
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back, color: Colors.black),
                            const SizedBox(width: 5),
                            Text("Previous Day", style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),

                      // Jump to Present Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300], // Light gray background
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: selectedDate != today
                            ? () {
                          selectedDate = today;
                          updateDateController();
                          Navigator.pop(context);
                          showQueueList();
                        }
                            : null,
                        child: Text("Jump to Present", style: TextStyle(color: Colors.black)),
                      ),

                      // Next Day Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey, // Light blue background
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: selectedDate.isBefore(today)
                            ? () {
                          selectedDate = selectedDate.add(Duration(days: 1));
                          updateDateController();
                          Navigator.pop(context);
                          showQueueList();
                        }
                            : null,
                        child: Row(
                          children: [
                            Text("Next Day", style: TextStyle(color: Colors.black)),
                            const SizedBox(width: 5),
                            Icon(Icons.arrow_forward, color: Colors.black),
                          ],
                        ),
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

    showQueueList();
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
            header(2, "Total Queue in Line"),
            header(2, "Actions"),
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
                            data(
                              1,
                              Text(
                                currentItemsList[index]["queueCount"] != null
                                    ? currentItemsList[index]["queueCount"].toString()
                                    : "No Queue Recorded",
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
                                  // Cast the LinkedMap to a Map<String, String>
                                  Map<String, String> queuedTimestamps = Map<String, String>.from(currentItemsList[index]["queuedTimestamps"]);
                                  showQueueDialog(context, queuedTimestamps);
                                },
                                icon: const Icon(Icons.queue),
                                label: const Text('Show Queue Record'),
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
