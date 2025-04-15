class Product {
  final int? id;
  final String nome;
  final String descrizione;
  final double prezzo;
  final double iva;

  Product({
    this.id,
    required this.nome,
    required this.descrizione,
    required this.prezzo,
    required this.iva,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descrizione': descrizione,
      'prezzo': prezzo,
      'iva': iva,
    };
  }

  static Product fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      descrizione: map['descrizione'] as String,
      prezzo: map['prezzo'] as double,
      iva: map['iva'] as double,
    );
  }
}