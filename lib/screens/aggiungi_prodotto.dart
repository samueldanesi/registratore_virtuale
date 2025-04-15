import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../model/product.dart';
import '../utils/aliquote_manager.dart';

class AggiungiProdottoPage extends StatefulWidget {
  final Product? prodotto;

  const AggiungiProdottoPage({super.key, this.prodotto});

  @override
  State<AggiungiProdottoPage> createState() => _AggiungiProdottoPageState();
}

class _AggiungiProdottoPageState extends State<AggiungiProdottoPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _prezzoController = TextEditingController();
  final TextEditingController _descrizioneController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();

  double? _ivaSelezionata;
  List<double> _aliquoteIVA = [];

  @override
  void initState() {
    super.initState();
    if (widget.prodotto != null) {
      _nomeController.text = widget.prodotto!.nome;
      _prezzoController.text = widget.prodotto!.prezzo.toString();
      _descrizioneController.text = widget.prodotto!.descrizione;
      _categoriaController.text = widget.prodotto!.categoria;
      _ivaSelezionata = widget.prodotto!.iva;
    }

    _caricaAliquote();
  }

  void _caricaAliquote() async {
    final list = await AliquoteManager.getAliquote();
    setState(() {
      _aliquoteIVA = list;
    });
  }

  Future<void> _salvaProdotto() async {
    if (_ivaSelezionata == null || _categoriaController.text.trim().isEmpty) return;

    final nuovoProdotto = Product(
      id: widget.prodotto?.id,
      nome: _nomeController.text,
      prezzo: double.tryParse(_prezzoController.text) ?? 0.0,
      descrizione: _descrizioneController.text,
      iva: _ivaSelezionata!,
      categoria: _categoriaController.text.trim(),
    );

    if (widget.prodotto == null) {
      await ProductDatabase.instance.create(nuovoProdotto);
    } else {
      await ProductDatabase.instance.update(nuovoProdotto);
    }

    Navigator.pop(context);
  }

  void _mostraDialogoAliquota() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuova Aliquota'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Inserisci valore %'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0 && val <= 100) {
                await AliquoteManager.addAliquota(val);
                Navigator.pop(context);
                _caricaAliquote(); // aggiorna la lista
              }
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aggiungi Prodotto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _prezzoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prezzo'),
            ),
            TextField(
              controller: _descrizioneController,
              decoration: const InputDecoration(labelText: 'Descrizione'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _categoriaController,
              decoration: const InputDecoration(labelText: 'Categoria (es. Primi Piatti)'),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<double>(
              value: _ivaSelezionata,
              decoration: const InputDecoration(labelText: 'Aliquota IVA'),
              items: _aliquoteIVA.map((aliq) {
                return DropdownMenuItem(
                  value: aliq,
                  child: Text('Aliquota ${aliq.toStringAsFixed(0)}%'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _ivaSelezionata = val),
            ),
            TextButton.icon(
              onPressed: _mostraDialogoAliquota,
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi nuova aliquota'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _salvaProdotto,
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}