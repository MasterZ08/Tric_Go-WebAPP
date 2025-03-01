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

  // Terms and Conditions text
  String termsAndConditions = '''
1. Introduction
Welcome to [Tric GO]. By using our services, you agree to these Terms and Conditions. If you do not agree, please do not use our Services.

2. Eligibility
You must be at least 18 years old to use our Services. By using our Services, you confirm that you meet this requirement.

3. User Accounts
To use our Services, you need to create an account. Ensure the information you provide is accurate and up-to-date. You are responsible for the security of your account and all activities that occur under your account.

4. Safety
We prioritize the safety of our users. We conduct background checks on drivers and regular vehicle inspections. However, we do not guarantee the safety or reliability of any driver or vehicle. Always take precautions when using our Services.

5. User Conduct
You agree to:
- Treat drivers and other users with respect.
- Not use our Services for any illegal activities.
- Comply with all applicable laws and regulations.

6. Limitation of Liability
[Tric GO] is not liable for any indirect, incidental, or consequential damages arising from your use of our Services. Your use of our Services is at your own risk.

7. Indemnification
You agree to indemnify and hold [Tric GO] harmless from any claims arising out of your use of our Services, violation of these Terms, or infringement of any rights of another party.

8. Privacy
Your privacy is important to us. Please review our Privacy Policy to understand how we collect and use your information.

9. Changes to Terms
We may update these Terms from time to time. We will notify you of any changes. Your continued use of our Services after such updates means you accept the new Terms.

10. Contact Us
For any questions about these Terms, please contact us at [zivenpaule@gmail.com].
''';
  @override
  void initState() {
    super.initState();
    fetchTodaItems();
  }

  Future<void> fetchTodaItems() async {
    DatabaseReference todaRef = FirebaseDatabase.instance.ref().child("toda");
    todaRef.onValue.listen((event) {
      List<String> fetchedItems = [];
      Map data = event.snapshot.value as Map;
      data.forEach((key, value) {
        fetchedItems.add(value['toda_abbreviation']);
      });
      setState(() {
        todaItems = fetchedItems;
      });
    });
  }

  void _fetchTodaCode(String selectedToda) async {
    DatabaseReference todaRef = FirebaseDatabase.instance.ref().child('toda');
    DataSnapshot snapshot = await todaRef.orderByChild('toda_abbreviation').equalTo(selectedToda).get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> todas = snapshot.value as Map<dynamic, dynamic>;
      todas.forEach((key, value) {
        setState(() {
          selectedTodaCode = value['toda_code']; // Assuming 'toda_code' is the field name
        });
      });
    }
  }

  final ScrollController _scrollController = ScrollController();

  checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context);

    if (imageFile != null && _termsChecked) {
      signUpFormValidation();
    } else {
      cMethods.displaySnackBar("Please choose an Image and accept Terms and Conditions", context);
    }
  }

  signUpFormValidation() {
    if (userNameTextEditingController.text.trim().length < 5) {
      cMethods.displaySnackBar("UserName must be 5 or more characters.", context);
    } else if (!RegExp(r'^09\d{9}$').hasMatch(phoneTextEditingController.text.trim())) {
      cMethods.displaySnackBar("Phone number must be 11 digits and start with 09.", context);
    } else if (!emailTextEditingController.text.contains("@")) {
      cMethods.displaySnackBar("Please write a valid email.", context);
    } else if (passwordTextEditingController.text.trim().length < 6) {
      cMethods.displaySnackBar("Password must be 6 or more characters.", context);
    } else if (tricycleModelTextEditingController.text.trim().isEmpty) {
      cMethods.displaySnackBar("Please Write your Tricycle Model.", context);
    } else if (tricycleColorTextEditingController.text.trim().isEmpty) {
      cMethods.displaySnackBar("Please Write your Tricycle Color.", context);
    } else if (tricycleNumberTextEditingController.text.trim().isEmpty) {
      cMethods.displaySnackBar("Please Write your Tricycle Number.", context);
    } else if (selectedToda == null) {
      cMethods.displaySnackBar("Please select a TODA.", context);
    }else if (selectedCoding == null) {
      cMethods.displaySnackBar("Please select a Day of your Coding.", context);
      //if walang piniling day
    } else {
      // Generate QR code
      generateAndDisplayQRCode(); //CHECK MO ITO LATER ON
      uploadImageToStorage();
    }
  }

  void generateAndDisplayQRCode() async {
    String qrDataText =
        "Name: ${userNameTextEditingController.text.trim()}\n" +
            "Phone: ${phoneTextEditingController.text.trim()}\n" +
            "Email: ${phoneTextEditingController.text.trim()}\n" +
            "TODA: $selectedToda";

    setState(() {
      qrData = qrDataText;
    });

    final Uint8List? imageData = await generateQRCodeImage(qrDataText);
    setState(() {
      qrImageData = imageData;

    });

  }

  uploadImageToStorage() async {
    String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceImage = FirebaseStorage.instance
        .ref()
        .child("Images")
        .child(imageIDName);

    UploadTask uploadTask = referenceImage.putFile(File(imageFile!.path));
    TaskSnapshot snapshot = await uploadTask;
    urlOfUploadedImage = await snapshot.ref.getDownloadURL();

    setState(() {
      urlOfUploadedImage;
    });

    registerNewDriver();
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
    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("drivers").child(user.uid);


    Map driverTricycleInfo = {
      "tricycleColor": tricycleColorTextEditingController.text.trim(),
      "tricycleModel": tricycleModelTextEditingController.text.trim(),
      "tricycleNumber": tricycleNumberTextEditingController.text.trim(),
    };

    Map driverDataMap = {
      "photo": urlOfUploadedImage,
      "tricycle_details": driverTricycleInfo,
      "name": userNameTextEditingController.text.trim(),
      "email": emailTextEditingController.text.trim(),
      "phone": phoneTextEditingController.text.trim(),
      "id": user.uid,
      "blockStatus": "no",
      "toda": selectedToda,
      "coding": selectedCoding,
      'toda_code': selectedTodaCode,
    };

    await usersRef.set(driverDataMap);


    // Generate QR code for the new admin
    String qrData = "${driverDataMap['name']}, ${driverDataMap['phone']}, ${driverDataMap['email']}, ${driverDataMap['toda']}";
    Uint8List? qrImageBytes = await generateQRCodeImage(qrData);

    if (qrImageBytes != null) {
      String base64QrImage = base64Encode(qrImageBytes);
      // Save base64 QR code image to Firebase under admin's data
      DatabaseReference qrImageRef = FirebaseDatabase.instance.ref().child("drivers").child(user.uid).child("qr_image");
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


  chooseImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageFile = pickedFile;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.article_outlined,
                  size: 50,
                  color: Colors.blue, // Adjust the icon color to your preference
                ),
                const SizedBox(height: 10),
                const Text(
                  "Terms and Conditions",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  termsAndConditions,
                  style: const TextStyle(fontSize: 14.0),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Background color for the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    _scrollController.addListener(() {
      // Remove this listener, so it doesn't close the dialog on scroll
      // if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      //   Navigator.of(context).pop();
      //  }
    });
  }


  // Function to add TODA to Firebase and local list
  void addTodaToFirebaseAndList(String newToda) {
    // Add TODA to Firebase Realtime Database
    DatabaseReference todaRef = FirebaseDatabase.instance.ref().child("toda");
    todaRef.push().set({
      "name": newToda,
    }).then((_) {
      // Update local list
      setState(() {
        todaItems.add(newToda);
        selectedToda = newToda; // Select newly added TODA
      });
    }).catchError((error) {
      cMethods.displaySnackBar("Failed to add TODA: $error", context);
    });
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
                const SizedBox(height: 40),
                imageFile == null
                    ? const CircleAvatar(
                  radius: 86,
                  backgroundImage: AssetImage("assets/images/avatarman.png"),
                )
                    : Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                    image: DecorationImage(
                      fit: BoxFit.contain, // Change to BoxFit.contain to avoid zooming in
                      image: FileImage(
                        File(imageFile!.path),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                GestureDetector(
                  onTap: chooseImageFromGallery,
                  child: const Text(
                    "Select Image",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

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
                          const SizedBox(height: 22),
                          TextField(
                            controller: passwordTextEditingController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(color: Colors.white),
                              hintText: "Enter your Password",
                              hintStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: _togglePasswordVisibility,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: tricycleModelTextEditingController,
                            obscureText: false,
                            decoration: InputDecoration(
                              labelText: "Tricycle Model",
                              labelStyle: TextStyle(color: Colors.white),
                              hintText: "Enter your Tricycle Model",
                              hintStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: tricycleColorTextEditingController,
                            obscureText: false,
                            decoration: InputDecoration(
                              labelText: "Tricycle Color",
                              labelStyle: TextStyle(color: Colors.white),
                              hintText: "Enter your Tricycle Color",
                              hintStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: tricycleNumberTextEditingController,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Tricycle Number",
                              labelStyle: TextStyle(color: Colors.white),
                              hintText: "Enter your Tricycle Number",
                              hintStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Select TODA',
                              labelStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            value: selectedToda,
                            items: todaItems.map((String item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(item, style: TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedToda = newValue;
                              });
                              if (newValue != null) {
                                _fetchTodaCode(newValue); // Fetch the TODA code when a TODA is selected
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: selectedCoding,
                            items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
                                .map((String coding) => DropdownMenuItem<String>(
                              value: coding,
                              child: Text(coding, style: TextStyle(color: Colors.white)),
                            ))
                                .toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCoding = newValue;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "Day of Coding",
                              labelStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Checkbox(
                                value: _termsChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _termsChecked = value!;
                                    if (_termsChecked) {
                                      _showTermsDialog(); // Show terms dialog when checked
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showTermsDialog,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'I have read and agree to the',
                                        style: TextStyle(
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Text(
                                        'Terms and Conditions',
                                        style: TextStyle(
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!_termsChecked)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Please read the Terms and Conditions before proceeding.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _termsChecked ? checkIfNetworkIsAvailable : null,
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
