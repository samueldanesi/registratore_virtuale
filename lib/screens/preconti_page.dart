import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../model/scontrino.dart';

class PrecontiPage extends StatefulWidget {
  final Function(Scontrino) onRiprendiPreconto;
  const PrecontiPage({Key? key, required this.onRiprendiPreconto}) : super(key: key);

  @override
  State<PrecontiPage> createState() => _PrecontiPageState();
}

class _PrecontiPageState extends State<PrecontiPage> {
  List<Scontrino> preconti = [];

  @override
  void initState() {
    super.initState();
    caricaPreconti();
  }

  Future<void> caricaPreconti() async {
    final tutti = await ProductDatabase.instance.leggiTuttiPreconti();
    setState(() => preconti = tutti);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preconti')),
      body: preconti.isEmpty
          ? const Center(child: Text('Nessun preconto salvato.'))
          : ListView.builder(
              itemCount: preconti.length,
              itemBuilder: (context, index) {
                final p = preconti[index];
                final nome = p.nome ?? 'Senza nome';
                return ListTile(
                  title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Data: ${p.data} - Ora: ${p.ora} | Totale: €${p.totale.toStringAsFixed(2)}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    widget.onRiprendiPreconto(p);
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}