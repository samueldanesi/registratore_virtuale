import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScontrinoPage extends StatelessWidget {
  final List<Map<String, dynamic>> scontrino;
  final double Function() calcolaTotale;
  final void Function(int index) rimuoviVoce;

  const ScontrinoPage({
    super.key,
    required this.scontrino,
    required this.calcolaTotale,
    required this.rimuoviVoce,
  });

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##0.00', 'it_IT');
    return formatter.format(price);
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0.###', 'it_IT');
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scontrino attuale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: scontrino.length,
              itemBuilder: (context, index) {
                final item = scontrino[index];
                final double prezzo = item['prezzo'];
                final double quantita = item['quantita'];
                final double sconto = item.containsKey('sconto') ? item['sconto'] : 0.0;
                final double prezzoFinale = prezzo * (1 - sconto);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(item['nome']),
                    subtitle: sconto > 0
                        ? RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                              children: [
                                TextSpan(text: "${_formatNumber(quantita)} x "),
                                TextSpan(
                                  text: "€${_formatPrice(prezzo)}",
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                const TextSpan(text: " → "),
                                TextSpan(
                                  text: "€${_formatPrice(prezzoFinale)}",
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          )
                        : Text("${_formatNumber(quantita)} x €${_formatPrice(prezzo)}"),
                    trailing: Text(
                      '€${_formatPrice(prezzoFinale * quantita)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => rimuoviVoce(index),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTALE:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '€${_formatPrice(calcolaTotale())}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}