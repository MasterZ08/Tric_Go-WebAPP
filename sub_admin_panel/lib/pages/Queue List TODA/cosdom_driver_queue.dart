import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sub_admin_panel/methods/common_methods.dart';
import 'package:sub_admin_panel/widgets/Each_Toda_Data_List/ltoda_data_list.dart';

import '../../widgets/Each_Toda_Queue_List/cosdom_queue_list.dart';
import '../../widgets/Each_Toda_Queue_List/ltoda_queue_list.dart';

class COSDOMTODADriversQueuePage extends StatefulWidget {
  static const String Id = "/CODSOMTODADriversQueuePage";

  const COSDOMTODADriversQueuePage({Key? key}) : super(key: key);

  @override
  State<COSDOMTODADriversQueuePage> createState() => _COSDOMTODADriversQueuePageState();
}

class _COSDOMTODADriversQueuePageState extends State<COSDOMTODADriversQueuePage> {
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
          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: const Text(
                    "COSDOMTODA Tricycle Driver Queueing Record",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Expanded(
                  child: COSDOMTODAQueueList(), // Your admin data list widget
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
