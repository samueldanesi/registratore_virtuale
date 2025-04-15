import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../model/product.dart';
import 'aggiungi_prodotto.dart';

class ProdottiPage extends StatefulWidget {
  const ProdottiPage({super.key});

  @override
  State<ProdottiPage> createState() => _ProdottiPageState();
}

class _ProdottiPageState extends State<ProdottiPage> {
  List<Product> prodotti = [];

  @override
  void initState() {
    super.initState();
    _caricaProdotti();
  }

  Future<void> _caricaProdotti() async {
    final prodottiDb = await ProductDatabase.instance.readAll();
    setState(() => prodotti = prodottiDb);
  }

  void _vaiAdAggiungi() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AggiungiProdottoPage()),
    );
    _caricaProdotti();
  }

  void _modificaProdotto(Product prodotto) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AggiungiProdottoPage(prodotto: prodotto),
      ),
    );
    _caricaProdotti();
  }

  void _eliminaProdotto(int id) async {
    await ProductDatabase.instance.delete(id);
    _caricaProdotti();
  }

  @override
  Widget build(BuildContext context) {
    // Raggruppa i prodotti per categoria
    final Map<String, List<Product>> prodottiPerCategoria = {};
    for (var prodotto in prodotti) {
      final categoria = prodotto.categoria.trim().isEmpty ? 'Senza categoria' : prodotto.categoria;
      prodottiPerCategoria.putIfAbsent(categoria, () => []).add(prodotto);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Prodotti')),
      body: prodotti.isEmpty
          ? const Center(child: Text('Nessun prodotto inserito'))
          : ListView(
              children: prodottiPerCategoria.entries.map((entry) {
                final categoria = entry.key;
                final listaProdotti = entry.value;
                return ExpansionTile(
                  title: Text(
                    categoria,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  children: listaProdotti.map((prodotto) {
                    return ListTile(
                      title: Text(prodotto.nome),
                      subtitle: Text(
                        '${prodotto.descrizione} | €${prodotto.prezzo.toStringAsFixed(2)} | Aliquota: ${prodotto.iva.toStringAsFixed(0)}%',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'modifica') {
                            _modificaProdotto(prodotto);
                          } else if (value == 'elimina') {
                            _eliminaProdotto(prodotto.id!);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'modifica',
                            child: Text('Modifica'),
                          ),
                          PopupMenuItem<String>(
                            value: 'elimina',
                            child: Text('Elimina'),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _vaiAdAggiungi,
        child: const Icon(Icons.add),
      ),
    );
  }
}