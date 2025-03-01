import 'package:flutter/material.dart';
import '../methods/common_methods.dart';
import '../widgets/users_data_list.dart';

class UsersPage extends StatefulWidget
{
  static const String Id = "\webpageUsers";

  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  CommonMethods cMethods = CommonMethods();
//to call out the class for design
  @override
  Widget build(BuildContext context) {
    return Scaffold(

        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.center,
                child: const Text(
                  "Users List",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Row(
                children: [
                  cMethods.header(2,"User ID"),
                  cMethods.header(2,"Name"),
                  cMethods.header(2,"Email"),
                  cMethods.header(2,"Phone"),
                ],
              ),
              UsersDataList(),
            ],
          ),
        )
    );
  }
}
