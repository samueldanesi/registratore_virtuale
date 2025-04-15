import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

Future<void> generateAndSendPDF(
  List<Map<String, dynamic>> prodotti,
  double totale, {
  required String intestatario,
  required String partitaIva,
  required String codiceFiscale,
  required String indirizzo,
}) async {
  final pdf = pw.Document();

  final now = DateTime.now();
  final data = DateFormat('dd/MM/yyyy').format(now);
  final ora = DateFormat('HH:mm').format(now);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a6,
      build: (pw.Context context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  '🧾 SCONTRINO',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Data: $data - Ora: $ora'),
              pw.SizedBox(height: 8),
              pw.Text('Cliente: $intestatario'),
              pw.Text('P.IVA: $partitaIva'),
              pw.Text('C.F.: $codiceFiscale'),
              pw.Text('Indirizzo: $indirizzo'),
              pw.SizedBox(height: 16),
              pw.Text('Prodotti:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              ...prodotti.map((p) {
                final nome = p['nome'];
                final qta = p['quantita'];
                final prezzo = p['prezzo'];
                final iva = p['iva'];
                final prezzoNetto = prezzo / (1 + iva / 100);
                final valoreIVA = prezzo - prezzoNetto;
                final totaleProdotto = prezzo * qta;

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('- $nome x$qta'),
                        pw.Text('€ ${totaleProdotto.toStringAsFixed(2)}'),
                      ],
                    ),
                    pw.Text('  IVA ${iva.toStringAsFixed(0)}% (€ ${valoreIVA.toStringAsFixed(2)})'),
                    pw.SizedBox(height: 6),
                  ],
                );
              }),

              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Totale (IVA inclusa):',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('€ ${totale.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  await Printing.sharePdf(bytes: await pdf.save(), filename: 'scontrino.pdf');
}