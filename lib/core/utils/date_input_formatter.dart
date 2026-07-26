import 'package:flutter/services.dart';

class DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the user deleted text, we let it happen naturally
    if (newValue.text.length < oldValue.text.length) {
      String text = newValue.text;
      int selectionIndex = newValue.selection.end;
      
      // If the user deleted a slash, delete the digit before it as well
      if (oldValue.text.endsWith('/') && text.length == oldValue.text.length - 1) {
        text = text.substring(0, text.length - 1);
        selectionIndex = text.length;
      }
      
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: selectionIndex),
      );
    }

    final String newText = newValue.text;
    final int selectionEnd = newValue.selection.end;

    // Only allow digits and slashes
    final RegExp regExp = RegExp(r'^[0-9/]*$');
    if (!regExp.hasMatch(newText)) {
      return oldValue;
    }

    // Strip out all non-digit characters to format fresh
    final String cleanText = newText.replaceAll('/', '');
    
    // Limit to 8 digits (YYYYMMDD)
    if (cleanText.length > 8) {
      return oldValue;
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);
      final int nonSlashIndex = i + 1;
      
      // Add slash after Year (4 digits) and Month (2 digits)
      if (nonSlashIndex == 4 && cleanText.length > 4) {
        buffer.write('/');
      } else if (nonSlashIndex == 6 && cleanText.length > 6) {
        buffer.write('/');
      }
    }

    final String formatted = buffer.toString();
    
    // Calculate cursor position
    int cursorPosition = formatted.length;
    
    if (selectionEnd < newText.length) {
      cursorPosition = selectionEnd;
      // If we added a slash, advance cursor
      if ((selectionEnd == 4 || selectionEnd == 7) && formatted.length > selectionEnd) {
        cursorPosition += 1;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
