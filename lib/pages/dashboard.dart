import 'package:sub_admin_panel/dashboard/dashboard.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget
{
  static const String Id = "\webpageDashboard";

  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:  Text(
          "WELCOME TO YOUR DASHBOARD",
          style: TextStyle(
              color: Colors.black,
              fontSize: 24
          ),
        ),
      ),
    );
  }
}
