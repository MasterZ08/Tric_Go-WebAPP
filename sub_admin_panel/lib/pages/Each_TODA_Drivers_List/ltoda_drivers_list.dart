import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sub_admin_panel/methods/common_methods.dart';
import 'package:sub_admin_panel/widgets/Each_Toda_Data_List/ltoda_data_list.dart';

class LTODADriversPage extends StatefulWidget {
  static const String Id = "/LTODADriversPage";

  const LTODADriversPage({Key? key}) : super(key: key);

  @override
  State<LTODADriversPage> createState() => _LTODADriversPageState();
}

class _LTODADriversPageState extends State<LTODADriversPage> {
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
                    "LTODA Tricycle Driver List",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Expanded(
                  child: LTODADriversDataList(), // Your admin data list widget
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
