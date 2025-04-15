// lib/model/reparto.dart

class Reparto {
  final String nome;
  final double aliquota;

  Reparto({required this.nome, required this.aliquota});
}

// Lista di reparti predefiniti
final List<Reparto> repartiDisponibili = [
  Reparto(nome: 'Abbigliamento', aliquota: 22),
  Reparto(nome: 'Alimenti pronti', aliquota: 10),
  Reparto(nome: 'Pane e latte', aliquota: 4),
  Reparto(nome: 'Esente', aliquota: 0),
];