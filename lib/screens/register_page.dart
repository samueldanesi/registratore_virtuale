import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../model/utente.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController cognomeController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController partitaIvaController = TextEditingController();
  final TextEditingController codiceFiscaleController = TextEditingController();
  final TextEditingController indirizzoController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nomeController.dispose();
    cognomeController.dispose();
    telefonoController.dispose();
    partitaIvaController.dispose();
    codiceFiscaleController.dispose();
    indirizzoController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();

    // 🔍 Verifica se l'email è già registrata
    final db = await ProductDatabase.instance.database;
    final existing = await db.query(
      'utenti',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existing.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email già registrata. Prova ad accedere.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final newUser = Utente(
      email: email,
      password: passwordController.text.trim(),
      nome: nomeController.text.trim(),
      cognome: cognomeController.text.trim(),
      telefono: telefonoController.text.trim(),
      partitaIva: partitaIvaController.text.trim(),
      codiceFiscale: codiceFiscaleController.text.trim(),
      indirizzo: indirizzoController.text.trim(),
      statoAbbonamento: 'prova',
      dataIscrizione: DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );

    await ProductDatabase.instance.inserisciUtente(newUser);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrazione completata')),
    );
    Navigator.pop(context); // torna alla login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Campo obbligatorio' : null,
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Campo obbligatorio' : null,
              ),
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value!.isEmpty ? 'Campo obbligatorio' : null,
              ),
              TextFormField(
                controller: cognomeController,
                decoration: const InputDecoration(labelText: 'Cognome'),
                validator: (value) => value!.isEmpty ? 'Campo obbligatorio' : null,
              ),
              TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Telefono'),
              ),
              TextFormField(
                controller: partitaIvaController,
                decoration: const InputDecoration(labelText: 'Partita IVA'),
                validator: (value) => value!.isEmpty ? 'Campo obbligatorio' : null,
              ),
              TextFormField(
                controller: codiceFiscaleController,
                decoration: const InputDecoration(labelText: 'Codice Fiscale'),
              ),
              TextFormField(
                controller: indirizzoController,
                decoration: const InputDecoration(labelText: 'Indirizzo'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Registrati'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}