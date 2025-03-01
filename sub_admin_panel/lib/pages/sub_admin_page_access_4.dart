import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sub_admin_panel/widgets/sub_admin_data_list_disabled_update_delete.dart';
import '../information/add_sub_admin.dart'; // Adjust import path as necessary
import '../widgets/sub_admin_data_list.dart';

class SubAdminPageAccess4 extends StatefulWidget {
  static const String Id = "/webpageSubAdmin";

  const SubAdminPageAccess4({Key? key}) : super(key: key);

  @override
  State<SubAdminPageAccess4> createState() => _SubAdminPageAccess4State();
}

class _SubAdminPageAccess4State extends State<SubAdminPageAccess4> {
  final bool hasPermission = false; // Change this based on user permission

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: hasPermission
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => Add_Sub_Admin()),
          );
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: Text("Add Sub Admin"),
      )
          : Tooltip(
        message: "You don't have permission for this feature",
        child: Opacity(
          opacity: 0.4,
          child: FloatingActionButton.extended(
            onPressed: null,
            backgroundColor: Colors.blueAccent,
            icon: const Icon(Icons.add),
            label: Text("Add Sub Admin"),
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
                child: SubAdminDataListNoUpdateDelete(), // Assuming this widget lists sub-admin data
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}
