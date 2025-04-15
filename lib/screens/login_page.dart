import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../model/utente.dart';
import '../main.dart';
import 'register_page.dart';
import 'home_screen.dart';
import '../db/database_helper.dart'; // ✅ necessario per controllare il database

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _loginOrRegister() async {
    if (_formKey.currentState!.validate()) {
      final email = emailController.text.trim();
      final password = passwordController.text;

      // ✅ LOGIN ADMIN
      if (email == 'admin@dicotec.it' && password == 'dicotec2024') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);

        final adminUser = Utente(
          email: 'admin@dicotec.it',
          password: 'admin123',
          nome: 'Admin',
          cognome: 'Dicotec',
          telefono: '',
          partitaIva: '12345678901',
          codiceFiscale: '',
          indirizzo: '',
          statoAbbonamento: 'admin',
          dataIscrizione: '01/01/2025',
          isAdmin: true,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(utenteLoggato: adminUser),
          ),
        );
        return;
      }

      // ✅ LOGIN UTENTE NORMALE REGISTRATO
      final db = await ProductDatabase.instance.database;
      final result = await db.query(
        'utenti',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      if (result.isNotEmpty) {
        final user = Utente.fromMap(result.first);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', user.email);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(utenteLoggato: user),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenziali non valide'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                'Accedi o Registrati',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Inserisci la tua email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Inserisci la password' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _loginOrRegister,
                      child: const Text(
                        'Accedi / Registrati',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      child: const Text(
                        "Non hai un account? Registrati",
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final utenteDemo = Utente(
                          email: 'demo@demo.it',
                          password: '',
                          nome: 'Demo',
                          cognome: 'Utente',
                          telefono: '',
                          partitaIva: '00000000000',
                          codiceFiscale: '',
                          indirizzo: '',
                          statoAbbonamento: 'demo',
                          dataIscrizione: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                          isAdmin: false,
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(utenteLoggato: utenteDemo),
                          ),
                        );
                      },
                      child: const Text(
                        'Accedi in modalità Demo',
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Column(
                children: [
                  Text(
                    'Powered by Dicotec',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Versione 0407',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}