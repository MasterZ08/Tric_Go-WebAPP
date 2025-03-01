import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CommonMethods {
  Widget header(int headerFlexValue, String headerTitle) {
    return Expanded(
      flex: headerFlexValue,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          color: Colors.blueAccent,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),

          child: Text(
            textAlign: TextAlign.center,
            headerTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,

            ),
          ),
        ),
      ),
    );
  }

  Widget data(int dataFlexValue, Widget widget) {
    return Expanded(
      flex: dataFlexValue,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: widget,
        ),
      ),
    );
  }

  checkConnectivity(BuildContext context) async
  {
    var connectionResult = await Connectivity().checkConnectivity();

    if(connectionResult != ConnectivityResult.mobile && connectionResult != ConnectivityResult.wifi)
    {
      if(!context.mounted) return;
      displaySnackBar("your Internet is not Available. Check your connection. Try Again.", context);
    }
  }

  displaySnackBar(String messageText, BuildContext context)
  {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

