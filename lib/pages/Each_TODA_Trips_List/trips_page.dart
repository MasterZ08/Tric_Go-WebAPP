import 'package:flutter/material.dart';
import 'package:sub_admin_panel/widgets/Each_Toda_Trips_Lists/trips_data_list.dart';
import '../../methods/common_methods.dart';

class TripsPage extends StatefulWidget {
  static const String Id = "\webpageTrips";

  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  CommonMethods cMethods = CommonMethods();

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: const Text(
                    "View Trips",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                // Displaying data with search bar and pagination
                Expanded(
                  child: TripsDataList(),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }
}
