import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../model/scontrino.dart';
import '../model/utente.dart';

class VenditePage extends StatefulWidget {
  final Utente utente;
  const VenditePage({super.key, required this.utente});

  @override
  State<VenditePage> createState() => _VenditePageState();
}

class _VenditePageState extends State<VenditePage> {
  List<Scontrino> _scontrini = [];

  @override
  void initState() {
    super.initState();
    caricaScontrini();
  }

  Future<void> caricaScontrini() async {
    final lista = await ProductDatabase.instance.leggiTuttiScontrini();
    setState(() {
      _scontrini = lista;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('📄 Vendite'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo,
      ),
      body: _scontrini.isEmpty
          ? const Center(child: Text('Nessuno scontrino emesso'))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _scontrini.length,
              itemBuilder: (context, index) {
                final s = _scontrini[index];
                final dataOra = DateFormat('dd/MM/yyyy HH:mm')
                    .parse('${s.data} ${s.ora}');
                final dataFormattata =
                    DateFormat('dd/MM/yyyy - HH:mm').format(dataOra);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.indigo),
                    title: Text('Scontrino del $dataFormattata'),
                    subtitle:
                        Text('Totale: € ${s.totale.toStringAsFixed(2)}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _mostraDettagli(context, s),
                  ),
                );
              },
            ),
    );
  }

  void _mostraDettagli(BuildContext context, Scontrino scontrino) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('🧾 Scontrino del ${scontrino.data} - ${scontrino.ora}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...scontrino.prodotti.map((p) => Text(
                  '- ${p['nome']} x${p['quantita']} | € ${p['prezzo']} | IVA ${p['iva']}%',
                )),
            const Divider(),
            Text('Totale: € ${scontrino.totale.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          )
        ],
      ),
    );
  }
}