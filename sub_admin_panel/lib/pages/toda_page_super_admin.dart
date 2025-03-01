import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../information/add_admin.dart';
import '../information/add_toda.dart';
import '../information/add_toda_super_admin.dart';
import '../widgets/admin_data_list.dart';
import '../widgets/toda_data_list.dart';

class TODAPageSuperAdmin extends StatelessWidget {
  static const String Id = "/todaPAGESuperAdmin";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => Add_TODA_Super_Admin()),
          );
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: Text("Add New TODA"),
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
                  child: TODADataList(), // Assuming this widget lists admin data
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

