import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:sub_admin_panel/authentication/authentication.dart';
import 'package:sub_admin_panel/methods/common_methods.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;

class DriversDataList extends StatefulWidget {
  const DriversDataList({super.key});

  @override
  State<DriversDataList> createState() => _DriversDataListState();
}

class _DriversDataListState extends State<DriversDataList> {
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

  final cosdomdriversRecordsFromDatabase = FirebaseDatabase.instance.ref().child("drivers");
  final todaRecordsFromDatabase = FirebaseDatabase.instance.ref().child("toda");
  final int itemsPerPage = 10;
  CommonMethods cMethods = CommonMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Initialize Firebase Auth

  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> itemsList = [];
  List<Map<String, dynamic>> filteredItemsList = [];
  int currentPage = 0;

  Map<String, String> todaCodes = {};
  List<String> todaAbbreviations = ['All'];
  String selectedToda = 'All';

  List<Uint8List> qrImages = []; // List to store decoded QR images

  @override
  void initState() {
    super.initState();
    searchController.addListener(_searchDrivers);
    fetchTodaCodes();
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
        bool matchesQuery = name.contains(query) || phone.contains(query);
        bool matchesToda = selectedToda == 'All' || item["toda"] == selectedToda;
        return matchesQuery && matchesToda;

      }).toList();
      currentPage = 0; // Reset to first page on new search
    });
  }

  Future<ui.Image> createImageFromPixels(Uint8List pixels, int width, int height) async {
    final img.Image image = img.Image.fromBytes(width, height, pixels);
    final ui.Codec codec = await ui.instantiateImageCodec(Uint8List.fromList(img.encodePng(image)));
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  // Convert image to ui.Image
  Future<ui.Image> convertImageToUiImage(img.Image image) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      Uint8List.fromList(img.encodePng(image)),
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
          (uiImage) => completer.complete(uiImage),
    );
    return completer.future;
  }

  Future<void> fetchTodaCodes() async {
    try {
      final snapshot = await todaRecordsFromDatabase.get();
      if (snapshot.exists) {
        Map dataMap = snapshot.value as Map;
        dataMap.forEach((key, value) {
          todaCodes[value["toda_abbreviation"]];
          todaAbbreviations.add(value["toda_abbreviation"]);
        });
        setState(() {}); // Update the state to refresh the dropdown
      }
    } catch (e) {
      print("Error fetching TODA codes: $e");
    }
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
        return AlertDialog(
          title: Text('Confirmation'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                action();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar and TODA Dropdown
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Search Bar
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Icon(
                Icons.list_alt_rounded,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 8),
              // TODA Dropdown
              DropdownButton<String>(
                value: selectedToda,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedToda = newValue!;
                    _searchDrivers(); // Trigger search with the new TODA filter
                  });
                },
                items: todaAbbreviations.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                dropdownColor: Colors.white,
                underline: Container(
                  height: 2,
                  color: Colors.transparent,
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),

        // Table headers
        Row(
          children: [
            header(3, "Name"),
            header(3, "Tricycle Details"),
            header(3, "Phone"),
            header(2, "TODA"),
            header(2, "Ratings"),
            header(3, "QR Code"),
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
                itemsList.add({"id": key, ...value});
              });

// Filtered list
              filteredItemsList = itemsList.where((item) {
                String query = searchController.text.toLowerCase();
                String name = item["name"].toString().toLowerCase();
                String phone = item["phone"].toString().toLowerCase();
                bool matchesQuery = name.contains(query) || phone.contains(query);
                bool matchesToda = selectedToda == 'All' || item["toda"] == selectedToda;

                return matchesQuery && matchesToda;
              }).toList();
// Sort the filtered list by name in alphabetical order
              filteredItemsList.sort((a, b) {
                return a["name"].toString().toLowerCase().compareTo(b["name"].toString().toLowerCase());
              });
              int totalPages = (filteredItemsList.length / itemsPerPage).ceil();
              int startIndex = currentPage * itemsPerPage;
              int endIndex = startIndex + itemsPerPage;
// Clamp the end index to the length of the filtered list

              List<Map<String, dynamic>> currentItemsList =
              filteredItemsList.sublist(startIndex, endIndex.clamp(0, filteredItemsList.length));

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
                            data(3, Text(currentItemsList[index]["name"].toString())),
                            data(
                            3, Text((tricycleDetails != null
                                ? (tricycleDetails["tricycleColor"] ?? '') + " - " +
                                (tricycleDetails["tricycleModel"] ?? '') + " - " +
                                (tricycleDetails["tricycleNumber"] ?? '')
                                : ''),),),
                            data(3, Text(currentItemsList[index]["phone"].toString())),
                            data(2, Text(currentItemsList[index]["toda"].toString())),
                            data(
                              2,
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
                              3,
                              qrImages[index].isEmpty
                                  ? Text('No QR Code')
                                  : GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.white, // Transparent background for the dialog
                                      child: Stack(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16.0),
                                            decoration: BoxDecoration(
                                              color: Colors.white, // White background for the container
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Scan Me',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black, // Adjust text color if needed
                                                  ),
                                                ),
                                                SizedBox(height: 20),
                                                Container(
                                                  color: Colors.white, // White background for the QR code
                                                  child: Image.memory(
                                                    qrImages[index],
                                                    width: 420, // Adjust size for larger QR code
                                                    height: 420,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: IconButton(
                                              icon: Icon(Icons.close),
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Close the dialog
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 4),
                                    //Displaying the QR CODE
                                    //Image.memory(
                                    //  qrImages[index],
                                    //  width: 40, // Adjust size for larger QR code
                                    //  height: 40,
                                    //  fit: BoxFit.contain,
                                    //),

                                    Text(
                                      'Click to Show QR Code',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
