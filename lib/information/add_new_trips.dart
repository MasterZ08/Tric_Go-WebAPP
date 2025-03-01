import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../methods/common_methods.dart';
import '../widgets/loading_dialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController tricycleModelTextEditingController = TextEditingController();
  TextEditingController tricycleColorTextEditingController = TextEditingController();
  TextEditingController tricycleNumberTextEditingController = TextEditingController();
  bool _obscureText = true;
  bool _termsChecked = false; // Track if terms are checked
  CommonMethods cMethods = CommonMethods();
  XFile? imageFile;
  String urlOfUploadedImage = "";
  String? selectedToda;
  String? selectedCoding;
  String? selectedTodaCode;
  List<String> todaItems = []; // Initial TODA items
  final _formKey = GlobalKey<FormState>();

  String qrData = ""; // Holds QR code data
  Uint8List? qrImageData; // Holds QR code image data


  @override
  void initState() {
    super.initState();
  }





  final ScrollController _scrollController = ScrollController();

  checkIfNetworkIsAvailable() {

    if (imageFile != null && _termsChecked) {
      signUpFormValidation();
    } else {
    }
  }

  signUpFormValidation() {
    if (userNameTextEditingController.text.trim().length < 5) {
      cMethods.displaySnackBar("UserName must be 5 or more characters.", context);
    } else if (!RegExp(r'^09\d{9}$').hasMatch(phoneTextEditingController.text.trim())) {
      cMethods.displaySnackBar("Phone number must be 11 digits and start with 09.", context);
    } else if (!emailTextEditingController.text.contains("@")) {
      cMethods.displaySnackBar("Please write a valid email.", context);
    }else {
      // Generate QR code
   //CHECK MO ITO LATER ON

    }
  }



  registerNewDriver() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Registering account..."),
    );

    try {
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      );

      await userCredential.user!.sendEmailVerification();
      await registerUserDetails(userCredential.user!);

      Navigator.pop(context); // Remove the loading dialog

      // Show the success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.check_circle_outline,
                    size: 50,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Registration Successful",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Verification email sent. Please Verify your email.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      Navigator.pop(context);
      cMethods.displaySnackBar(error.toString(), context);
    }
  }

  registerUserDetails(User user) async {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("users").child(user.uid);




    Map driverDataMap = {

      "name": userNameTextEditingController.text.trim(),
      "email": emailTextEditingController.text.trim(),
      "phone": phoneTextEditingController.text.trim(),
      "id": user.uid,

    };

    await usersRef.set(driverDataMap);


    // Generate QR code for the new admin
    String qrData = "${driverDataMap['name']}, ${driverDataMap['phone']}, ${driverDataMap['email']}, ${driverDataMap['toda']}";
    Uint8List? qrImageBytes = await generateQRCodeImage(qrData);

    if (qrImageBytes != null) {
      String base64QrImage = base64Encode(qrImageBytes);
      // Save base64 QR code image to Firebase under admin's data
      DatabaseReference qrImageRef = FirebaseDatabase.instance.ref().child("users").child(user.uid).child("qr_image");
      qrImageRef.set(base64QrImage);
    }

  }

  Future<Uint8List?> generateQRCodeImage(String data) async {
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
    );

    final picData = await qrPainter.toImageData(200);
    return picData?.buffer.asUint8List();
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blueAccent.withOpacity(0.5),
              Colors.lightBlueAccent.withOpacity(0.5),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glass-like container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          TextField(
                            controller: userNameTextEditingController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "UserName",
                              labelStyle: TextStyle(color: Colors.white),
                              hintText: "Enter your UserName",
                              hintStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: phoneTextEditingController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Phone Number 09XXXXXXXXX",
                              labelStyle: TextStyle(color: Colors.white),
                              hintText: "Enter your Phone Number",
                              hintStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: emailTextEditingController,
                            obscureText: false,
                            decoration: InputDecoration(
                              labelText: "Email",
                              labelStyle: TextStyle(color: Colors.white),
                              hintText: "Enter your Email",
                              hintStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed:  checkIfNetworkIsAvailable : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 80,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20), // Less rounded corners
                                side: BorderSide(color: Colors.black, width: 1), // Thin black border
                              ),
                            ),
                            child: Text('Sign Up'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
