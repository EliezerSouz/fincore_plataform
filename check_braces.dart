import 'dart:io';

void main(List<String> args) {
  final file = File(args[0]);
  final content = file.readAsStringSync();
  final lines = content.split('\n');
  
  final stack = <Map<String, dynamic>>[];
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    bool inString = false;
    for (int j = 0; j < line.length; j++) {
      final char = line[j];
      if (char == "'" || char == '"') {
        inString = !inString;
      }
      if (inString) continue;
      
      if (char == '{' || char == '[' || char == '(') {
        stack.add({'char': char, 'line': i + 1, 'col': j + 1});
      } else if (char == '}' || char == ']' || char == ')') {
        if (stack.isEmpty) {
          print('Unmatched ' + char + ' at line ' + (i + 1).toString());
          return;
        }
        final top = stack.removeLast();
        if (i + 1 >= 1765 && i + 1 <= 1773) {
           print('Line ' + (i + 1).toString() + ' (' + char + ') closed ' + top['char'].toString() + ' at line ' + top['line'].toString());
        }
        
        final topChar = top['char'];
        String expected = '';
        if (topChar == '{') expected = '}';
        if (topChar == '[') expected = ']';
        if (topChar == '(') expected = ')';
        
        if (char != expected) {
          print('Mismatched ' + char + ' at line ' + (i + 1).toString() + ', expected ' + expected + ' to match ' + topChar + ' at line ' + top["line"].toString());
          return;
        }
      }
    }
  }
}
