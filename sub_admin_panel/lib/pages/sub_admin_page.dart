import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sub_admin_panel/information/add_sub_admin_super_admin.dart';
import '../information/add_sub_admin.dart'; // Adjust import path as necessary
import '../methods/common_methods.dart';
import '../widgets/sub_admin_data_list.dart';

class SubAdminPage extends StatefulWidget {
  static const String Id = "\webpageSubAdmin";

  const SubAdminPage({Key? key}) : super(key: key);

  @override
  State<SubAdminPage> createState() => _SubAdminPageState();
}

class _SubAdminPageState extends State<SubAdminPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => Add_Sub_Admin_Super_Admin()),
          );
        },
        backgroundColor: Colors.blueAccent, // Match the button color from Add_Sub_Admin
        icon: const Icon(Icons.add),
        label: Text("Add Sub Admin"),
      ),
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
                  "Manage Sub Admins",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SubAdminDataList(), // Assuming this widget lists sub-admin data
              ),

            ],
          ),
      ),
        ],
      ),
    );
  }
}
