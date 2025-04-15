import 'package:flutter/material.dart';
import '../model/user.dart'; // <-- crea il file model User se non esiste
import '../db/database_helper.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<User> utenti = [];

  @override
  void initState() {
    super.initState();
    caricaUtenti();
  }

  Future<void> caricaUtenti() async {
    final lista = await ProductDatabase.instance.leggiTuttiUtenti();
    setState(() {
      utenti = lista;
    });
  }

  String calcolaDurata(String dataRegistrazione) {
    final registrazione = DateTime.parse(dataRegistrazione);
    final differenza = DateTime.now().difference(registrazione);
    return "${differenza.inDays} giorni";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestione Utenti")),
      body: ListView.builder(
        itemCount: utenti.length,
        itemBuilder: (context, index) {
          final user = utenti[index];
          return ListTile(
            title: Text(user.email),
            subtitle: Text(
              "Stato: ${user.abbonamento == "prova" ? "Prova" : "Annuale"} - Da: ${calcolaDurata(user.dataRegistrazione)}",
            ),
            trailing: Icon(
              user.abbonamento == "prova" ? Icons.hourglass_empty : Icons.verified,
              color: user.abbonamento == "prova" ? Colors.orange : Colors.green,
            ),
          );
        },
      ),
    );
  }
}