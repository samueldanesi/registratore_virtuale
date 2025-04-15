import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/product.dart';
import '../model/scontrino.dart';
import '../utils/pdf_generator.dart';
import '../db/database_helper.dart';
import 'preconti_page.dart';
import 'scontrino_page.dart';

import '../model/utente.dart'; // 👈 se non c'è, aggiungilo

class CassaPage extends StatefulWidget {
  final Utente utente;

  const CassaPage({super.key, required this.utente});
  @override
  State<CassaPage> createState() => _CassaPageState();
}

class _CassaPageState extends State<CassaPage> {
  final List<Map<String, dynamic>> scontrino = [];
  Map<String, List<Product>> prodottiPerCategoria = {};
  String? categoriaSelezionata;
  String input = '';
  String? nota;
  String? tastoPremuto;
  double scontoPercentuale = 0.0;
  int? idPrecontoAttivo;
  bool mostraScontrinoEsteso = false;
  bool usaComeQuantita = false;
  bool isLoading = true;
  double? primoValoreMoltiplicazione;
  bool attesaSecondoValore = false;
  String? primoValoreVisualizzato;
  // Palette di colori blu personalizzata
  final Color primaryBlue = const Color(0xFF1976D2);
  final Color secondaryBlue = const Color(0xFF64B5F6);
  final Color accentBlue = const Color(0xFF0D47A1);
  final Color surfaceBlue = const Color(0xFFE3F2FD);
  final Color onSurfaceBlue = const Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      await caricaProdottiDalDatabase();
    } catch (e) {
      debugPrint('Errore nel caricamento iniziale: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel caricamento: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> caricaProdottiDalDatabase() async {
    final tutti = await ProductDatabase.instance.readAll();
    Map<String, List<Product>> mappa = {};

    for (final prodotto in tutti) {
      mappa.putIfAbsent(prodotto.categoria, () => []).add(prodotto);
    }

    setState(() {
      prodottiPerCategoria = mappa;
      categoriaSelezionata ??= mappa.keys.first;
    });
  }

  double? _valutaInputMoltiplicativo(String inputRaw) {
    try {
      final tokens = inputRaw.split('x').map((e) => e.trim().replaceAll(',', '.'));
      final values = tokens.map((e) => double.parse(e)).toList();
      return values.reduce((a, b) => a * b);
    } catch (e) {
      return null;
    }
  }

  void aggiungiProdotto(Product p) {
  double quantita = 1.0;
  double prezzo = p.prezzo;

  if (primoValoreMoltiplicazione != null) {
    if (input.isNotEmpty) {
      final secondoValore = double.tryParse(input.replaceAll(',', '.'));
      if (secondoValore != null) {
        // Caso 9 x 9
        quantita = primoValoreMoltiplicazione! * secondoValore;
      } else {
        quantita = primoValoreMoltiplicazione!;
      }
    } else {
      // Caso 9 x prodotto → usa 9 come quantità
      quantita = primoValoreMoltiplicazione!;
    }
  } else if (input.isNotEmpty) {
    final valoreInput = double.tryParse(input.replaceAll(',', '.'));
    if (valoreInput != null) {
      prezzo = valoreInput;
    }
  }

  setState(() {
    scontrino.add({
      'nome': p.nome,
      'quantita': quantita,
      'prezzo': prezzo,
      'iva': p.iva,
      'sconto': scontoPercentuale,
    });

    input = '';
    usaComeQuantita = false;
    primoValoreMoltiplicazione = null;
    attesaSecondoValore = false;
    primoValoreVisualizzato = null;
  });
}

  void azzeraScontrino() async {
    if (idPrecontoAttivo != null) {
      await ProductDatabase.instance.eliminaPreconto(idPrecontoAttivo!);
    }

    setState(() {
      scontrino.clear();
      input = '';
      nota = null;
      scontoPercentuale = 0.0;
      idPrecontoAttivo = null;
      
    });
  }

  double calcolaTotale() {
    return scontrino.fold(0.0, (totale, p) {
      final double prezzo = p['prezzo'] as double;
      final double quantita = p['quantita'] as double;
      final double sconto = (p['sconto'] ?? 0.0) as double;
      return totale + (prezzo * quantita * (1 - sconto));
    });
  }

  Future<void> generaScontrino() async {
  try {
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'it_IT');

    if (nota != null && nota!.isNotEmpty) {
      scontrino.add({
        'nome': 'Nota: $nota',
        'quantita': 1.0,
        'prezzo': 0.0,
        'iva': 0.0,
      });
    }

    final nuovoScontrino = Scontrino(
      data: formatter.format(now),
      ora: DateFormat('HH:mm').format(now),
      prodotti: scontrino,
      totale: calcolaTotale(),
      intestatario: '${widget.utente.nome} ${widget.utente.cognome}',
      partitaIva: widget.utente.partitaIva,
      codiceFiscale: widget.utente.codiceFiscale,
      indirizzo: widget.utente.indirizzo,
    );

    await ProductDatabase.instance.inserisciScontrino(nuovoScontrino);

    if (idPrecontoAttivo != null) {
      await ProductDatabase.instance.eliminaPreconto(idPrecontoAttivo!);
    }

   await generateAndSendPDF(
  scontrino,
  calcolaTotale(),
  intestatario: '${widget.utente.nome} ${widget.utente.cognome}',
  partitaIva: widget.utente.partitaIva ?? '',
  codiceFiscale: widget.utente.codiceFiscale ?? '',
  indirizzo: widget.utente.indirizzo ?? '',
);
    azzeraScontrino();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scontrino emesso con successo')),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Errore: ${e.toString()}')),
    );
  }
}
  Future<void> salvaPreconto() async {
    try {
      final controller = TextEditingController();
      final conferma = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nome preconto'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Es. Tavolo 3',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Conferma'),
            ),
          ],
        ),
      );

      if (conferma == true) {
        final now = DateTime.now();
        final formatter = DateFormat('dd/MM/yyyy HH:mm', 'it_IT');
        String nomeFinale = controller.text.trim();

        if (nomeFinale.isEmpty) {
          final precontiEsistenti = await ProductDatabase.instance.leggiTuttiPreconti();
          int numero = 1;
          final nomiEsistenti = precontiEsistenti.map((p) => p.nome ?? '').toSet();

          while (nomiEsistenti.contains('Preconto $numero')) {
            numero++;
          }
          nomeFinale = 'Preconto $numero';
        }

        final preconto = Scontrino(
  data: formatter.format(now),
  ora: DateFormat('HH:mm').format(now),
  prodotti: scontrino,
  totale: calcolaTotale(),
  nome: nomeFinale,
  intestatario: '${widget.utente.nome} ${widget.utente.cognome}',
  partitaIva: widget.utente.partitaIva,
  codiceFiscale: widget.utente.codiceFiscale,
  indirizzo: widget.utente.indirizzo,
);

        if (idPrecontoAttivo != null) {
          await ProductDatabase.instance.eliminaPreconto(idPrecontoAttivo!);
        }

        await ProductDatabase.instance.inserisciPreconto(preconto);
        azzeraScontrino();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preconto salvato come "$nomeFinale"')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: ${e.toString()}')),
      );
    }
  }

  String _formatPrice(double price) => NumberFormat('#,##0.00', 'it_IT').format(price);
  String _formatNumber(double number) => NumberFormat('#,##0.###', 'it_IT').format(number);

  void mostraDialogoNota() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi nota'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Es. "senza cipolla"',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final testoNota = controller.text.trim();
              if (testoNota.isNotEmpty) {
                setState(() {
                  nota = testoNota;
                  scontrino.add({
                    'nome': 'Nota: $testoNota',
                    'quantita': 1.0,
                    'prezzo': 0.0,
                    'iva': 0.0,
                    'sconto': 0.0,
                  });
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }

  void mostraDialogoSconto() async {
    final percentController = TextEditingController();
    final valoreController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Applica sconto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: percentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sconto in %',
                  hintText: 'es. 10 per 10%',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sconto in €',
                  hintText: 'es. 5 per 5 euro',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final scontoPerc = double.tryParse(percentController.text.trim()) ?? 0.0;
                      final scontoVal = double.tryParse(valoreController.text.trim()) ?? 0.0;
                      final totale = scontrino.fold(0.0, (tot, p) => tot + (p['prezzo'] * p['quantita']));

                      if (scontoPerc > 0) {
                        setState(() => scontoPercentuale = scontoPerc / 100);
                      } else if (scontoVal > 0) {
                        setState(() => scontoPercentuale = scontoVal / totale);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Applica'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void mostraDialogoAzioni() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.orange),
              title: const Text('Aggiungi nota'),
              onTap: () {
                Navigator.pop(context);
                mostraDialogoNota();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.percent, color: Colors.green),
              title: const Text('Applica sconto'),
              onTap: () {
                Navigator.pop(context);
                mostraDialogoSconto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScontrinoEsteso() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scontrino (${scontrino.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => mostraScontrinoEsteso = false),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: scontrino.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = scontrino[index];
              return _buildProdottoItem(item, index);
            },
          ),
        ),
        _buildTotaleWidget(),
      ],
    );
  }

  Widget _buildProdottoItem(Map<String, dynamic> item, int index) {
    final quantita = item['quantita'] as double;
    final nome = item['nome'];
    final prezzoUnitario = item['prezzo'] as double;
    final sconto = (item['sconto'] ?? 0.0) as double;
    final prezzoFinale = prezzoUnitario * (1 - sconto);
    final totale = prezzoFinale * quantita;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => setState(() => scontrino.removeAt(index)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${quantita.toStringAsFixed(quantita.truncateToDouble() == quantita ? 0 : 2)} × ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (sconto > 0)
                      Text(
                        '€${_formatPrice(prezzoUnitario)} ',
                        style: TextStyle(
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      '€${_formatPrice(prezzoFinale)}',
                      style: TextStyle(
                        color: sconto > 0 ? Colors.green : Colors.grey[600],
                        fontWeight: sconto > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '€${_formatPrice(totale)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTotaleWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceBlue,
        borderRadius: BorderRadius.circular(12),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTastierino() {
    const tasti = [
      '7', '8', '9', 'CE',
      '4', '5', '6', 'x',
      '1', '2', '3', 'Azioni',
      '0', ',', 'Emetti', 'Preconto'
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: tasti.length,
      itemBuilder: (context, index) {
        final tasto = tasti[index];
        return _buildTasto(tasto);
      },
    );
  }

  Widget _buildTasto(String tasto) {
    Color bgColor;
    Color textColor = Colors.white;
    double fontSize = 20;

    switch (tasto) {
      case 'CE':
        bgColor = Colors.red;
        break;
      case 'Emetti':
        bgColor = Colors.green;
        break;
      case 'Preconto':
        bgColor = Colors.orange;
        fontSize = 16;
        break;
      case 'Azioni':
      case 'x':
        bgColor = secondaryBlue;
        textColor = Colors.black87;
        break;
      default:
        bgColor = primaryBlue;
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: tastoPremuto == tasto ? Colors.amber : bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: Colors.transparent,
      ),
      onPressed: () => _gestisciTasto(tasto),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          tasto,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  void _navigaAPreconti() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrecontiPage(
          onRiprendiPreconto: (preconto) {
            setState(() {
              scontrino.clear();
              scontrino.addAll(preconto.prodotti);
              idPrecontoAttivo = preconto.id;
            });
          },
        ),
      ),
    );
  }

  void _gestisciTasto(String tasto) {
    setState(() => tastoPremuto = tasto);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => tastoPremuto = null);
    });

    switch (tasto) {
      case 'Azioni':
        mostraDialogoAzioni();
        break;
      case 'x':
  if (input.isEmpty) return; // prevenzione
  final valore = double.tryParse(input.replaceAll(',', '.'));
  if (valore != null) {
    setState(() {
      primoValoreMoltiplicazione = valore;
      attesaSecondoValore = true;
      primoValoreVisualizzato = input;
      input = '';
    });
  }
  break;
       case 'CE':
  if (scontrino.isEmpty && input.isEmpty) return;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Conferma eliminazione'),
      content: const Text('Sei sicuro di voler azzerare lo scontrino?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              input = '';
              usaComeQuantita = false;
              nota = null;
              scontrino.clear();
              scontoPercentuale = 0.0;
              primoValoreMoltiplicazione = null;
              attesaSecondoValore = false;
              primoValoreVisualizzato = null;
              idPrecontoAttivo = null;
            });
          },
          child: const Text('Conferma'),
        ),
      ],
    ),
  );
  break;
      case 'Emetti':
        generaScontrino();
        break;
      case 'Preconto':
        salvaPreconto();
        break;
      case ',':
        if (!input.contains(',')) {
          setState(() => input += ',');
        }
        break;
      default:
        setState(() {
  input += tasto;

  if (attesaSecondoValore && primoValoreMoltiplicazione != null) {
    final secondo = double.tryParse(input.replaceAll(',', '.'));
    if (secondo != null) {
      final risultato = primoValoreMoltiplicazione! * secondo;
      input = risultato.toString();
      usaComeQuantita = true;
      attesaSecondoValore = false;
      primoValoreMoltiplicazione = null;
    }
  }
});
    }
  }

  @override
Widget build(BuildContext context) {
  if (isLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  final prodotti = prodottiPerCategoria[categoriaSelezionata] ?? [];
  final altezzaTastierino = MediaQuery.of(context).size.height * 0.45;

  return Scaffold(
    appBar: AppBar(
      title: const Text('Cassa', style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: primaryBlue,
      actions: [
        if (scontrino.isNotEmpty)
          IconButton(
            icon: Badge(
              label: Text(scontrino.length.toString()),
              child: const Icon(Icons.receipt_long, color: Colors.white),
            ),
            onPressed: () => setState(() => mostraScontrinoEsteso = true),
          ),
        IconButton(
          icon: const Icon(Icons.history, color: Colors.white),
          onPressed: _navigaAPreconti,
        ),
      ],
    ),
    body: mostraScontrinoEsteso
        ? _buildScontrinoEsteso()
        : Column(
            children: [
              // 🔹 Selettore categorie
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: prodottiPerCategoria.keys.map((categoria) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(categoria),
                        selected: categoria == categoriaSelezionata,
                        onSelected: (_) => setState(() => categoriaSelezionata = categoria),
                        selectedColor: secondaryBlue,
                        labelStyle: const TextStyle(color: Colors.black87),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 🔹 Griglia prodotti scrollabile
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: prodotti.length,
                  itemBuilder: (context, index) {
                    final p = prodotti[index];
                    return Material(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      elevation: 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => aggiungiProdotto(p),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  p.nome,
                                  style: const TextStyle(fontSize: 14),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '€${_formatPrice(p.prezzo)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 🔹 Striscia azzurra con totale e input
              if (scontrino.isNotEmpty || input.isNotEmpty || primoValoreVisualizzato != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: InkWell(
                    onTap: () => setState(() => mostraScontrinoEsteso = true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              attesaSecondoValore && primoValoreVisualizzato != null
                                  ? '$primoValoreVisualizzato ×'
                                  : usaComeQuantita
                                      ? '$input ×'
                                      : input.isNotEmpty
                                          ? 'Prezzo: $input'
                                          : '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '€${_formatPrice(calcolaTotale())}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 🔹 Tastierino fisso
              SizedBox(
                height: altezzaTastierino,
                child: buildTastierino(),
              ),
            ],
          ),
  );
}
}