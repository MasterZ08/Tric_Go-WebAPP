import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class SubAdminDataListNoUpdateDelete extends StatefulWidget {
  const SubAdminDataListNoUpdateDelete({Key? key}) : super(key: key);

  @override
  State<SubAdminDataListNoUpdateDelete> createState() => _SubAdminDataListNoUpdateDeleteState();
}

class _SubAdminDataListNoUpdateDeleteState extends State<SubAdminDataListNoUpdateDelete> {
  final driversRecordsFromDatabase = FirebaseDatabase.instance.ref().child("accounts");

  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> itemsList = [];
  List<Map<String, dynamic>> filteredItemsList = [];
  int currentPage = 0;
  final int itemsPerPage = 12;
  bool canEditAndDelete = false; // Set this based on user permission

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
              labelText: 'Search by Sub Admin',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        // Table headers
        Row(
          children: [
            header(4, "Name"),
            header(4, "Email"),
            header(4, "Phone"),
            header(4, "Toda"),
            header(3, "Actions"),
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

              if (snapshotData.data == null ||
                  snapshotData.data!.snapshot.value == null) {
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
                if (value["role"] == "Sub-Admin") { // Filter for sub admins
                  itemsList.add({"key": key, ...value});
                }
              });

              // Sort itemsList alphabetically
              itemsList.sort((a, b) => a["name"].toString().compareTo(b["name"].toString()));

              // Filtered list based on search
              filteredItemsList = itemsList.where((item) {
                String query = searchController.text.toLowerCase();
                String name = item["name"].toString().toLowerCase();
                return name.contains(query);
              }).toList();


              filteredItemsList.sort((a, b) => a["name"].toString().compareTo(b["name"].toString())); // Sort filtered list

              int totalPages = (filteredItemsList.length / itemsPerPage).ceil();
              int startIndex = currentPage * itemsPerPage;
              int endIndex = startIndex + itemsPerPage; // Calculate current page range
              List<Map<String, dynamic>> currentItemsList = filteredItemsList
                  .sublist(startIndex, endIndex.clamp(0, filteredItemsList.length)); // Paginated items

              if (currentItemsList.isEmpty) {
                return Center(
                  child: Text(
                    "No Sub Admin Record Found",
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
                            data(4, Text(currentItemsList[index]["name"].toString())),
                            data(4, Text(currentItemsList[index]["email"].toString())),
                            data(4, Text(currentItemsList[index]["phone"].toString())),
                            data(4, Text(currentItemsList[index]["toda"].toString())),
                            data(
                              3,
                                Tooltip(
                                  message: canEditAndDelete
                                      ? ""
                                      : "You don't have permission for this feature",
                                  child: Opacity(
                                    opacity: canEditAndDelete ? 1.0 : 0.6,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade100,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5.0),
                                        ),
                                      ),
                                      icon: const Icon(Icons.delete),
                                      onPressed: canEditAndDelete
                                          ? () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              backgroundColor: Colors.blueGrey[50],
                                              title: Row(
                                                children: const [
                                                  Icon(Icons.delete, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete Sub Admin'),
                                                ],
                                              ),
                                              content: const Text('Are you sure you want to delete this sub-admin?'),
                                              actions: [
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.greenAccent.shade200,
                                                  ),
                                                  onPressed: () async {
                                                    DatabaseReference ref = FirebaseDatabase
                                                        .instance
                                                        .ref()
                                                        .child("sub-admin/${currentItemsList[index]["key"]}");
                                                    await ref.remove();
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Yes'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.redAccent.shade200,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('No'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                          : null, // Disable the button by setting onPressed to null
                                      label: const Text('Delete'),
                                    ),
                                  ),
                                )

                            ),
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
