import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sub_admin_panel/widgets/admin_datalist_admin_level.dart';
import '../information/add_admin.dart';
import '../information/add_admin_admin_level.dart';
import '../widgets/admin_data_list.dart';

class AdminPageAccess2 extends StatelessWidget {
  static const String Id = "/adminPage";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => Add_Admin_Admin_Level()),
          );
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: Text("Add Admin"),
      ),
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
                  "Manage Admins",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Text color matching button
                  ),
                ),
              ),
              SizedBox(height: 18),
              Expanded(
                child: AdminDataListAdminLevel(), // Assuming this widget lists admin data
              ),
            ],
          ),
      ),
        ],
      ),
    );
  }
}
