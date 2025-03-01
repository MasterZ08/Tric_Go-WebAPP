import 'package:flutter/material.dart';
import '../widgets/driver_datalist.dart';

class DriversPage extends StatelessWidget {
  static const String Id = "/DriversPage";
  final bool isLoading = true; // Simulate a loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey.shade50, Colors.blueGrey.shade100],
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: const Text(
                    "View Tric-Go Tricycle Driver List",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Expanded(
                  child: DriversDataList(), // Your admin data list widget
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
