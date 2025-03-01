import 'package:flutter/material.dart';
import 'package:sub_admin_panel/widgets/Each_Toda_Trips_Lists/trips_data_list.dart';
import '../../methods/common_methods.dart';
import '../../widgets/Each_Toda_Trips_Lists/ltoda_trips_data_list.dart';

class LTODATripsPage extends StatefulWidget {
  static const String Id = "/LTODATripsPage";

  const LTODATripsPage({super.key});

  @override
  State<LTODATripsPage> createState() => _LTODATripsPageState();
}

class _LTODATripsPageState extends State<LTODATripsPage> {
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
                    child:
                    Stack(
                      children: [
                        Center(
                          child: const Text(
                            "View Trips",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.info_outline),
                            iconSize: 20,
                            color: Colors.black,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    contentPadding: const EdgeInsets.all(20),
                                    content: Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 400,
                                        maxHeight: 300,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Center(
                                            child: const Text(
                                              'Information',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Center(
                                            child: const Text(
                                              'Trip Records will automatically be deleted after 45 days.',
                                              style: TextStyle(
                                                fontSize: 16,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Align(
                                            alignment: Alignment.bottomCenter,
                                            child: TextButton(
                                              style: TextButton.styleFrom(
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
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        )
                      ],
                    )
                ),
                const SizedBox(
                  height: 18,
                ),
                // Displaying data with search bar and pagination
                Expanded(
                  child: LTODATripsDataList(),
                ),
              ],
            ),
          ),
        ],
      )

    );
  }
}
