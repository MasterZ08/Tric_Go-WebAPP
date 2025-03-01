import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadPage extends StatelessWidget {
  // Replace with the actual URL of your APK file
  final String apkDownloadLink = "https://example.com/path-to-your-app.apk";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Download Our APK"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Click the button below to download the APK",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (await canLaunch(apkDownloadLink)) {
                  await launch(apkDownloadLink);
                } else {
                  throw 'Could not launch $apkDownloadLink';
                }
              },
              child: Text("Download APK"),
            ),
          ],
        ),
      ),
    );
  }
}
