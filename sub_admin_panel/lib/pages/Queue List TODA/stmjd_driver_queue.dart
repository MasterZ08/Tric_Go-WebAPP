import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sub_admin_panel/methods/common_methods.dart';
import 'package:sub_admin_panel/widgets/Each_Toda_Data_List/ltoda_data_list.dart';

import '../../widgets/Each_Toda_Queue_List/ltoda_queue_list.dart';
import '../../widgets/Each_Toda_Queue_List/stmjd_queue_list.dart';

class STMJDTODADriversQueuePage extends StatefulWidget {
  static const String Id = "/LTODADriversQueuePage";

  const STMJDTODADriversQueuePage({Key? key}) : super(key: key);

  @override
  State<STMJDTODADriversQueuePage> createState() => _STMJDTODADriversQueuePageState();
}

class _STMJDTODADriversQueuePageState extends State<STMJDTODADriversQueuePage> {
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
                    "STMJDTODA Tricycle Driver Queueing Record",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Expanded(
                  child: STMJDTODAQueueList(), // Your admin data list widget
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
