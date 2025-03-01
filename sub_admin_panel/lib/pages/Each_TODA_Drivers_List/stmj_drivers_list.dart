import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sub_admin_panel/methods/common_methods.dart';
import 'package:sub_admin_panel/widgets/Each_Toda_Data_List/stmj_data_list.dart';

class STMJDDriversPage extends StatefulWidget {
  static const String Id = "/STMJDDriversPage";

  const STMJDDriversPage({Key? key}) : super(key: key);

  @override
  State<STMJDDriversPage> createState() => _STMJDDriversPageState();
}

class _STMJDDriversPageState extends State<STMJDDriversPage> {
  CommonMethods cMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Stack(
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
                    "SANTOMAJOTODA Tricycle Driver List",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Expanded(
                  child: STMJDDriversDataList(), // Your admin data list widget
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
