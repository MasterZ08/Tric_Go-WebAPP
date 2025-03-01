import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sub_admin_panel/widgets/admin_data_list_disabled_update_delete.dart';
import '../information/add_admin.dart';
import '../widgets/admin_data_list.dart';

class AdminPageAccess3 extends StatelessWidget {
  static const String Id = "/adminPage";
  final bool hasPermission = false; // Set this based on user permission

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: hasPermission
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => Add_Admin()),
          );
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: Text("Add Admin"),
      )
          : Tooltip(
        message: "You don't have permission for this feature",
        child: Opacity(
          opacity: 0.6,
          child: FloatingActionButton.extended(
            onPressed: null,
            backgroundColor: Colors.blueAccent,
            icon: const Icon(Icons.add),
            label: Text("Add Admin"),
          ),
        ),
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
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 18),
              Expanded(
                child: AdminDataListNoUpdateDelete(),
              ),
            ],
          ),
      ),
        ],
      ),
    );
  }
}


