
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';



class AppDatePicker{

  Future<DateTime?> datePicker(
      BuildContext context,
      DateTime? initialDatee,
      ) async {
    final initialDate = initialDatee ?? DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      // barrierColor: AppColors.lightSkinColor2,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
             // primary:LightColorsPalate.primaryColor, // Selected day background color
              onPrimary: Colors.white, // Selected day text color
              onSurface: Colors.black, // Default text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
      firstDate: DateTime(DateTime.now().year - 100),
      lastDate: DateTime(DateTime.now().year + 5),
    ).whenComplete(() {


    });

    if (newDate == null) {
      return null;
    } else {
      return newDate;
    }
  }

}
