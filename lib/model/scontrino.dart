import 'dart:convert';

class Scontrino {
  final int? id;
  final String data;
  final String ora;
  final List<Map<String, dynamic>> prodotti;
  final double totale;
  final String? nome;

  // ✅ Nuovi campi per invio SDI
  final String? intestatario;
  final String partitaIva;
  final String? codiceFiscale;
  final String? indirizzo;

  Scontrino({
    this.id,
    required this.data,
    required this.ora,
    required this.prodotti,
    required this.totale,
    this.nome,
    this.intestatario,
    required this.partitaIva,
    this.codiceFiscale,
    this.indirizzo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data,
      'ora': ora,
      'prodotti': jsonEncode(prodotti),
      'totale': totale,
      'nome': nome,
      'intestatario': intestatario,
      'partitaIva': partitaIva,
      'codiceFiscale': codiceFiscale,
      'indirizzo': indirizzo,
    };
  }

  factory Scontrino.fromMap(Map<String, dynamic> map) {
    return Scontrino(
      id: map['id'],
      data: map['data'],
      ora: map['ora'],
      prodotti: List<Map<String, dynamic>>.from(
        jsonDecode(map['prodotti']) as List,
      ),
      totale: map['totale'],
      nome: map['nome'],
      intestatario: map['intestatario'],
      partitaIva: map['partitaIva'],
      codiceFiscale: map['codiceFiscale'],
      indirizzo: map['indirizzo'],
    );
  }
}