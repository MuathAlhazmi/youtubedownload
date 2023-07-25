import 'package:flash/flash.dart';
import 'package:flutter/material.dart';

void showTopSnackBar(BuildContext context, String message) {
  showFlash(
    context: context,
    duration: const Duration(
        seconds: 3), // Set the duration you want the snackbar to be visible
    builder: (context, controller) {
      return SafeArea(
        child: FlashBar(
          padding: EdgeInsets.all(5),
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          position: FlashPosition.top,
          controller: controller,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          content: Center(
            child: Container(
              height: 50,
              child: Center(
                child: Text(
                  message,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
