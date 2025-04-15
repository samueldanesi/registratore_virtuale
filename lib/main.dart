import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/utente.dart';
import 'screens/login_page.dart';
import 'screens/home_screen.dart'; // ✅ HomeScreen ora importata da file separato

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);

  final prefs = await SharedPreferences.getInstance();
  final savedEmail = prefs.getString('userEmail');

  runApp(BillyApp(emailSalvata: savedEmail));
}

class BillyApp extends StatelessWidget {
  final String? emailSalvata;

  const BillyApp({super.key, required this.emailSalvata});

  @override
  Widget build(BuildContext context) {
    Widget paginaIniziale;

    if (emailSalvata == 'admin@dicotec.it') {
      final adminUser = Utente(
        email: 'admin@dicotec.it',
        password: 'admin123',
        nome: 'Admin',
        cognome: 'Dicotec',
        telefono: '',
        partitaIva: '12345678901',
        codiceFiscale: '',
        indirizzo: '',
        statoAbbonamento: 'Admin',
        dataIscrizione: '01/01/2025',
        isAdmin: true,
      );
      paginaIniziale = HomeScreen(utenteLoggato: adminUser);
    } else {
      paginaIniziale = const LoginPage();
    }

    return MaterialApp(
      title: 'Billy Clone',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Arial',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      home: paginaIniziale,
      debugShowCheckedModeBanner: false,
    );
  }
}