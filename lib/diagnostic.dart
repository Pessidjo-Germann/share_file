// Fichier de diagnostic pour identifier le problème de Context
import 'package:flutter/material.dart';

void checkContextType() {
  // Test pour voir quel est le type de Context disponible
  print('Checking context types...');
}

class DiagnosticWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Diagnostic: BuildContext works here'),
      ),
    );
  }
}
