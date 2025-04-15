import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../model/utente.dart';
import 'package:intl/intl.dart';

class GestioneUtentiPage extends StatefulWidget {
  final Utente utenteLoggato;

  const GestioneUtentiPage({super.key, required this.utenteLoggato});

  @override
  State<GestioneUtentiPage> createState() => _GestioneUtentiPageState();
}

class _GestioneUtentiPageState extends State<GestioneUtentiPage> {
  List<Utente> utenti = [];

  @override
  void initState() {
    super.initState();
    _caricaUtenti();
  }

  Future<void> _caricaUtenti() async {
    // Solo admin può caricare
    if (!widget.utenteLoggato.isAdmin && widget.utenteLoggato.email != 'admin@dicotec.it') {
      return;
    }

    final lista = await ProductDatabase.instance.leggiTuttiUtenti();
    setState(() {
      utenti = lista;
    });
  }

  String _formatData(String dataString) {
    try {
      final data = DateFormat('dd/MM/yyyy').parse(dataString);
      final diff = DateTime.now().difference(data).inDays;
      return '$diff giorni fa';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.utenteLoggato.isAdmin || widget.utenteLoggato.email == 'admin@dicotec.it';

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accesso riservato')),
        body: const Center(
          child: Text('Non hai i permessi per accedere a questa sezione.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Utenti'),
        backgroundColor: Colors.indigo,
      ),
      body: utenti.isEmpty
          ? const Center(child: Text("Nessun utente registrato."))
          : ListView.builder(
              itemCount: utenti.length,
              itemBuilder: (context, index) {
                final u = utenti[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 1,
                  child: ListTile(
                    leading: Icon(
                      u.isAdmin ? Icons.shield : Icons.person,
                      color: u.isAdmin ? Colors.orange : Colors.indigo,
                    ),
                    title: Text('${u.nome} ${u.cognome}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📧 ${u.email}'),
                        Text('🧾 Abbonamento: ${u.statoAbbonamento}'),
                        Text('🗓️ Iscritto da: ${_formatData(u.dataIscrizione)}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}