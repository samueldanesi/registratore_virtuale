import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../model/product.dart';
import '../utils/pdf_generator.dart';
import 'package:billy_clone/utils/pdf_generator.dart';  // Importa correttamente la funzioneclass CassaPage extends StatefulWidget {
import 'package:billy_clone/utils/pdf_generator.dart'; // Corretto!
  const CassaPage({super.key});

  @override
  State<CassaPage> createState() => _CassaPageState();
}

class _CassaPageState extends State<CassaPage> {
  List<Product> prodotti = [];
  Map<int, int> quantita = {}; // id -> quantità

  @override
  void initState() {
    super.initState();
    _caricaProdotti();
  }

  Future<void> _caricaProdotti() async {
    final prodottiDb = await ProductDatabase.instance.readAll();
    setState(() {
      prodotti = prodottiDb;
      for (var prodotto in prodottiDb) {
        quantita[prodotto.id!] = 0;
      }
    });
  }

  double get totale {
    double somma = 0;
    for (var prodotto in prodotti) {
      final qta = quantita[prodotto.id!] ?? 0;
      final prezzoIvato = prodotto.prezzo * (1 + prodotto.iva / 100);
      somma += prezzoIvato * qta;
    }
    return somma;
  }

  void _generaScontrino() {
    final selezionati = prodotti
        .where((p) => (quantita[p.id!] ?? 0) > 0)
        .map((p) => {
              'nome': p.nome,
              'quantita': quantita[p.id!]!,
              'prezzo': p.prezzo,
              'iva': p.iva,
            })
        .toList();

    generateAndSendPDF(selezionati, totale); // funzione che ti passo dopo
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cassa')),
      body: ListView.builder(
        itemCount: prodotti.length,
        itemBuilder: (context, index) {
          final prodotto = prodotti[index];
          final qta = quantita[prodotto.id!] ?? 0;
          return ListTile(
            title: Text(prodotto.nome),
            subtitle: Text(
              '€ ${prodotto.prezzo.toStringAsFixed(2)} + IVA ${prodotto.iva.toStringAsFixed(0)}%',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (qta > 0) {
                      setState(() => quantita[prodotto.id!] = qta - 1);
                    }
                  },
                ),
                Text('$qta'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() => quantita[prodotto.id!] = qta + 1);
                  },
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          onPressed: _generaScontrino,
          icon: const Icon(Icons.picture_as_pdf),
          label: Text('Genera Scontrino (€ ${totale.toStringAsFixed(2)})'),
        ),
      ),
    );
  }
}