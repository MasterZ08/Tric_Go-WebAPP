
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import '../widgets/act_log_current_user.dart';

class Profile_Overview extends StatefulWidget {
  const Profile_Overview({super.key});
  static const String Id = "/webpageMyQRCode";

  @override
  State<Profile_Overview> createState() => _Profile_OverviewState();
}

class _Profile_OverviewState extends State<Profile_Overview> {

  String _oldPassword = '';
  String _newPassword = '';
  String _reEnterNewPassword = '';

  bool obscurePassword = true;
  bool hasMinLength = false;
  bool hasUpperCase = false;
  bool hasSpecialChar = false;
  bool passwordsMatch = false;
  bool _isPasswordCorrect = true;
  bool isFormValid = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.reference();
  //update
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _reEnterNewPasswordController;
  late TextEditingController _nameController;

  User? _user;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _reEnterNewPasswordController = TextEditingController();
    _fetchUserData();

  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _reEnterNewPasswordController.dispose();
    _nameController.dispose();
    super.dispose();

  }

  Future<void> _fetchUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      final uid = _user!.uid;
      final userDataSnapshot = await _databaseReference.child('accounts').child(uid).once();

      if (userDataSnapshot.snapshot.value != null) {
        setState(() {
          _userData = Map<String, dynamic>.from(userDataSnapshot.snapshot.value as Map);
        });
      }
    }
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog<void>(
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
                  Icons.error_outline,
                  size: 50,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
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
                  Icons.check_circle,
                  size: 50,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Password updated successfully!',
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
                    setState(() {
                      _oldPasswordController.clear();
                      _newPasswordController.clear();
                      _reEnterNewPasswordController.clear();
                      _oldPassword = '';
                      _newPassword = '';
                      _reEnterNewPassword = '';
                      _isPasswordCorrect = true;
                      hasMinLength = false;
                      hasUpperCase = false;
                      hasSpecialChar = false;
                      passwordsMatch = false;
                      isFormValid = false;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changePassword() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && _oldPassword.isNotEmpty && _newPassword.isNotEmpty &&
          _reEnterNewPassword.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
            email: user.email!, password: _oldPassword);

        try {
          await user.reauthenticateWithCredential(credential);
          if (_newPassword == _reEnterNewPassword && hasMinLength &&
              hasUpperCase && hasSpecialChar) {
            await user.updatePassword(_newPassword);
            await _showSuccessDialog();
          } else {
            await _showErrorDialog(
                'New passwords do not match or do not meet requirements');
          }
        } catch (e) {
          setState(() {
            _isPasswordCorrect = false;
          });
          await _showErrorDialog('You inputted a wrong old password');
        }
      } else {
        await _showErrorDialog('Please fill all the fields');
      }
    } catch (e) {
      await _showErrorDialog('Error updating password: $e');
    }
  }

  void validatePassword(String value) {
    setState(() {
      hasMinLength = value.length >= 8 && value.length <= 20;
      hasUpperCase = value.contains(RegExp(r'[A-Z]'));
      hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_]'));
      isFormValid =
          hasMinLength && hasUpperCase && hasSpecialChar && passwordsMatch;
    });
  }

  void checkPasswordsMatch(String value) {
    setState(() {
      passwordsMatch = _newPassword == value;
      isFormValid =
          hasMinLength && hasUpperCase && hasSpecialChar && passwordsMatch;
    });
  }

  void showSuccessUpdateDialog(BuildContext context, VoidCallback refreshPage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Update Successful!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  refreshPage(); // Call the refresh function
                },
                child: const Text('OK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Define the method to refresh the page
  void refreshPage() {
    setState(() {
      // Your logic to refresh the page
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            Container(
                color: Colors.blueAccent,
                child: TabBar(
                  tabs: [
                    Tab(
                      child: Text(
                        "Profile Details",
                        style: TextStyle(fontSize: 16.0), // Adjust font size as needed
                      ),
                    ),
                    Tab(
                      child: Text(
                        "Change Password",
                        style: TextStyle(fontSize: 16.0), // Adjust font size as needed
                      ),
                    ),
                    Tab(
                      child: Text(
                        "User System Log",
                        style: TextStyle(fontSize: 16.0), // Adjust font size as needed
                      ),
                    ),

                  ],
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                )
            ),
            Expanded(
              child: TabBarView(
                children: [
                  //User Details
                  SingleChildScrollView(
                      child: Center(
                          child: _userData == null
                              ? const CircularProgressIndicator()
                              : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // User Details Section
                                Container(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // User Details Section
                                        Container(
                                          child: Column(
                                            children: [
                                              Container(
                                                margin: EdgeInsets.symmetric(
                                                    vertical: 4),
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.grey,
                                                      width: 1),
                                                  borderRadius: BorderRadius
                                                      .circular(8),
                                                  color: Colors.white,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller: TextEditingController(text: 'Name: ${_userData!['name'] ?? 'N/A'}'),
                                                        style: const TextStyle(fontSize: 18, color: Colors.black),
                                                        enabled: false, // Makes the TextField non-editable
                                                        decoration: const InputDecoration(
                                                          border: InputBorder.none,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                                      onPressed: () {
                                                        // Open the update dialog
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            // Create a TextEditingController for the name field
                                                            final nameTextEditingController = TextEditingController(
                                                              text: _userData!['name'],
                                                            );

                                                            return Dialog(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(20),
                                                              ),
                                                              child: Container(
                                                                padding: const EdgeInsets.all(20),
                                                                constraints: const BoxConstraints(
                                                                  maxWidth: 400, // Adjust the width of the dialog box
                                                                  maxHeight: 300, // Adjust the height of the dialog box
                                                                ),
                                                                child: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    const SizedBox(height: 20),
                                                                    Row(
                                                                      children: const [
                                                                        Icon(Icons.edit, color: Colors.black54, size: 20),
                                                                        SizedBox(width: 8),
                                                                        Text(
                                                                          'Update Name',
                                                                          style: TextStyle(
                                                                            fontSize: 20,
                                                                            fontWeight: FontWeight.bold,
                                                                            color: Colors.black,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(height: 20),
                                                                    TextFormField(
                                                                      controller: nameTextEditingController,
                                                                      keyboardType: TextInputType.text,
                                                                      decoration: InputDecoration(
                                                                        labelText: "Name",
                                                                        border: OutlineInputBorder(
                                                                          borderRadius: BorderRadius.circular(10),
                                                                        ),
                                                                      ),
                                                                      style: const TextStyle(
                                                                        color: Colors.black,
                                                                        fontSize: 18,
                                                                      ),
                                                                      onChanged: (text) {
                                                                        // Update the name in _userData
                                                                        _userData!['name'] = text;
                                                                      },
                                                                    ),
                                                                    const SizedBox(height: 20),
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                      children: [
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor: Colors.greenAccent,
                                                                            shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(7),
                                                                            ),
                                                                          ),
                                                                          onPressed: () async {
                                                                            if (_user != null && _userData != null) {
                                                                              await _databaseReference
                                                                                  .child('accounts')
                                                                                  .child(_user!.uid)
                                                                                  .update({
                                                                                "name": _userData!["name"],
                                                                              });
                                                                              Navigator.of(context).pop();
                                                                              showSuccessUpdateDialog(context, refreshPage);
                                                                            }
                                                                          },
                                                                          child: const Text('Save'),
                                                                        ),
                                                                        const SizedBox(width: 8),
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor: Colors.redAccent,
                                                                            shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(7),
                                                                            ),
                                                                          ),
                                                                          onPressed: () {
                                                                            Navigator.of(context).pop();
                                                                          },
                                                                          child: const Text('Cancel'),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),


                                                  ],
                                                )

                                              ),
                                              Container(
                                                margin: EdgeInsets.symmetric(
                                                    vertical: 4),
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.grey,
                                                      width: 1),
                                                  borderRadius: BorderRadius
                                                      .circular(8),
                                                  color: Colors.white,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller: TextEditingController(text: 'Phone: ${_userData!['phone'] ?? 'N/A'}'),
                                                        style: TextStyle(fontSize: 18, color: Colors.black), // Changed text color to black
                                                        enabled: false, // Makes the TextField non-editable
                                                        decoration: InputDecoration(
                                                          border: InputBorder.none,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                                      onPressed: () {
                                                        // Open the update dialog
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            // Create a TextEditingController for the phone number field
                                                            final phoneTextEditingController = TextEditingController(
                                                              text: _userData!['phone'],
                                                            );

                                                            return Dialog(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(20),
                                                              ),
                                                              child: Container(
                                                                padding: const EdgeInsets.all(20),
                                                                constraints: const BoxConstraints(
                                                                  maxWidth: 400, // Adjust the width of the dialog box
                                                                  maxHeight: 300, // Adjust the height of the dialog box
                                                                ),
                                                                child: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    const SizedBox(height: 20),
                                                                    Row(
                                                                      children: const [
                                                                        Icon(Icons.edit, color: Colors.black54, size: 20),
                                                                        SizedBox(width: 8),
                                                                        Text(
                                                                          'Update Phone Number',
                                                                          style: TextStyle(
                                                                            fontSize: 20,
                                                                            fontWeight: FontWeight.bold,
                                                                            color: Colors.black,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(height: 20),
                                                                    TextFormField(
                                                                      controller: phoneTextEditingController,
                                                                      keyboardType: TextInputType.phone,
                                                                      inputFormatters: [
                                                                        FilteringTextInputFormatter.digitsOnly,
                                                                        LengthLimitingTextInputFormatter(11),
                                                                      ],
                                                                      decoration: InputDecoration(
                                                                        labelText: "Phone Number (09XXXXXXXXX)",
                                                                        border: OutlineInputBorder(
                                                                          borderRadius: BorderRadius.circular(10),
                                                                        ),
                                                                      ),
                                                                      style: const TextStyle(
                                                                        color: Colors.black,
                                                                        fontSize: 18,
                                                                      ),
                                                                      onChanged: (value) {
                                                                        // Update the phone number in _userData
                                                                        _userData!['phone'] = value;
                                                                      },
                                                                    ),
                                                                    const SizedBox(height: 20),
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                      children: [
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor: Colors.greenAccent,
                                                                            shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(7),
                                                                            ),
                                                                          ),
                                                                          onPressed: () async {
                                                                            final phoneNumber = phoneTextEditingController.text.trim();
                                                                            // Validate the phone number
                                                                            if (RegExp(r'^09\d{9}$').hasMatch(phoneNumber)) {
                                                                              if (_user != null && _userData != null) {
                                                                                await _databaseReference
                                                                                    .child('accounts')
                                                                                    .child(_user!.uid)
                                                                                    .update({
                                                                                  "phone": phoneNumber,
                                                                                });
                                                                                Navigator.of(context).pop();
                                                                                showSuccessUpdateDialog(context, refreshPage);
                                                                              }
                                                                            } else {
                                                                              // Show an error message if the phone number is invalid
                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                                const SnackBar(
                                                                                  content: Text(
                                                                                    "Phone number must be a valid 11-digit Philippine number starting with 09.",
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            }
                                                                          },
                                                                          child: const Text('Save'),
                                                                        ),
                                                                        const SizedBox(width: 8),
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor: Colors.redAccent,
                                                                            shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(7),
                                                                            ),
                                                                          ),
                                                                          onPressed: () {
                                                                            Navigator.of(context).pop();
                                                                          },
                                                                          child: const Text('Cancel'),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),

                                                  ],
                                                ),
                                              ),
                                              // Email box
                                              Container(
                                                margin: EdgeInsets.symmetric(
                                                    vertical: 4),
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.grey,
                                                      width: 1),
                                                  borderRadius: BorderRadius
                                                      .circular(8),
                                                  color: Colors.white,
                                                ),
                                                child: TextField(
                                                  controller: TextEditingController(
                                                      text: 'Email: ${_userData!['email'] ??
                                                          'N/A'}'),
                                                  style: TextStyle(fontSize: 18,
                                                      color: Colors.black),
                                                  enabled: false,
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              // TODA bbox
                                              Container(
                                                margin: EdgeInsets.symmetric(
                                                    vertical: 4),
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.grey,
                                                      width: 1),
                                                  borderRadius: BorderRadius
                                                      .circular(8),
                                                  color: Colors.white,
                                                ),
                                                child: TextField(
                                                  controller: TextEditingController(
                                                      text: 'TODA: ${_userData!['toda'] ??
                                                          'N/A'}'),
                                                  style: TextStyle(fontSize: 18,
                                                      color: Colors.black),
                                                  enabled: false,
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                              ]
                          )
                      )
                  ),
                  // Password Change Tab
                  SingleChildScrollView(
                    child:
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title for Password Change Section
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Old Password Field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: TextField(
                              controller: _oldPasswordController,
                              obscureText: obscurePassword,
                              onChanged: (value) {
                                setState(() {
                                  _oldPassword = value;
                                  _isPasswordCorrect =
                                  true; // Reset error state
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Old Password',
                                errorText: _isPasswordCorrect
                                    ? null
                                    : 'Incorrect old password',
                                border: OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword ? Icons.visibility : Icons
                                        .visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          // New Password Field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: TextField(
                              controller: _newPasswordController,
                              obscureText: obscurePassword,
                              onChanged: (value) {
                                setState(() {
                                  _newPassword = value;
                                  validatePassword(value);
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                border: OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword ? Icons.visibility : Icons
                                        .visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Password Validation
                          Row(
                            children: [
                              Icon(
                                hasMinLength ? Icons.check : Icons.close,
                                color: hasMinLength ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              const Text('8-20 characters'),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                hasUpperCase ? Icons.check : Icons.close,
                                color: hasUpperCase ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              const Text('At least one uppercase letter'),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                hasSpecialChar ? Icons.check : Icons.close,
                                color: hasSpecialChar ? Colors.green : Colors
                                    .red,
                              ),
                              const SizedBox(width: 8),
                              const Text('At least one special character ex. !@#%^&*(),.?":{}|<>_'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Re-enter New Password Field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: TextField(
                              controller: _reEnterNewPasswordController,
                              obscureText: obscurePassword,
                              onChanged: (value) {
                                setState(() {
                                  _reEnterNewPassword = value;
                                  checkPasswordsMatch(value);
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Re-enter New Password',
                                border: OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword ? Icons.visibility : Icons
                                        .visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                passwordsMatch ? Icons.check : Icons.close,
                                color: passwordsMatch ? Colors.green : Colors
                                    .red,
                              ),
                              const SizedBox(width: 8),
                              const Text('Passwords match'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Change Password Button
                          ElevatedButton(
                            onPressed: isFormValid ? _changePassword : null,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: isFormValid
                                  ? Colors.lightBlue
                                  : Colors.grey,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 5,
                              textStyle: TextStyle(fontSize: 18),
                              minimumSize: Size(200, 50),
                            ),
                            child: Text("Change Password"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  //User Act Log
                  SingleChildScrollView(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height, // Adjust height as needed
                      child: Container(
                        color: Colors.grey.shade100,
                        child: ActLogDataList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  }

