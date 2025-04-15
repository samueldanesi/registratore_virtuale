import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database_helper.dart';
import '../model/utente.dart';

class ReportPage extends StatefulWidget {
  final Utente utente;
  const ReportPage({super.key, required this.utente});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String filtroProdotti = 'Quantità';
  String filtroIncassi = '1 mese';

  Map<String, double> prodottiVenduti = {};
  Map<int, Map<String, double>> incassiPerData = {};

  @override
  void initState() {
    super.initState();
    caricaDati();
  }

  Future<void> caricaDati() async {
    final prodotti = await ProductDatabase.instance.prodottiPiuVenduti();
    final incassi = await ProductDatabase.instance.incassiFiltrati(filtroIncassi);
    setState(() {
      prodottiVenduti = prodotti;
      incassiPerData = incassi;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report analitico')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prodotti più venduti', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: filtroProdotti,
              items: const [
                DropdownMenuItem(value: 'Quantità', child: Text('Per quantità')),
                DropdownMenuItem(value: 'Incasso', child: Text('Per incasso')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => filtroProdotti = value);
                  caricaDati();
                }
              },
            ),
            SizedBox(
              height: 220,
              child: prodottiVenduti.isEmpty
                  ? const Center(child: Text('Nessun dato'))
                  : PieChart(
                      PieChartData(
                        sections: prodottiVenduti.entries.map((entry) {
                          return PieChartSectionData(
                            title: entry.key,
                            value: entry.value,
                            radius: 50,
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            const Text('Incassi nel tempo', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: filtroIncassi,
              items: const [
                DropdownMenuItem(value: '1 giorno', child: Text('Oggi')),
                DropdownMenuItem(value: '7 giorni', child: Text('Ultimi 7 giorni')),
                DropdownMenuItem(value: '1 mese', child: Text('Ultimo mese')),
                DropdownMenuItem(value: '3 mesi', child: Text('Ultimi 3 mesi')),
                DropdownMenuItem(value: '6 mesi', child: Text('Ultimi 6 mesi')),
                DropdownMenuItem(value: '1 anno', child: Text('Ultimo anno')),
                DropdownMenuItem(value: 'Tutto', child: Text('Tutto')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => filtroIncassi = value);
                  caricaDati();
                }
              },
            ),
            SizedBox(
              height: 250,
              child: incassiPerData.isEmpty
                  ? const Center(child: Text('Nessun dato'))
                  : LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(show: true),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            spots: incassiPerData.entries
                                .map((entry) => FlSpot(
                                      entry.key.toDouble(),
                                      entry.value['totale'] ?? 0.0,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}