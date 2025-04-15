class Utente {
  final int? id;
  final String email;
  final String password;
  final String nome;
  final String cognome;
  final String? telefono;
  final String partitaIva;
  final String? codiceFiscale;
  final String? indirizzo;
  final String statoAbbonamento;
  final String dataIscrizione;
  final bool isAdmin; // 👈 aggiunto

  Utente({
    this.id,
    required this.email,
    required this.password,
    required this.nome,
    required this.cognome,
    this.telefono,
    required this.partitaIva,
    this.codiceFiscale,
    this.indirizzo,
    required this.statoAbbonamento,
    required this.dataIscrizione,
    this.isAdmin = false, // 👈 default: false
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'nome': nome,
      'cognome': cognome,
      'telefono': telefono,
      'partitaIva': partitaIva,
      'codiceFiscale': codiceFiscale,
      'indirizzo': indirizzo,
      'tipoAbbonamento': statoAbbonamento,
      'dataIscrizione': dataIscrizione,
      'isAdmin': isAdmin ? 1 : 0, // 👈 salvato come intero
    };
  }

  static Utente fromMap(Map<String, dynamic> map) {
    return Utente(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      nome: map['nome'],
      cognome: map['cognome'],
      telefono: map['telefono'],
      partitaIva: map['partitaIva'],
      codiceFiscale: map['codiceFiscale'],
      indirizzo: map['indirizzo'],
      statoAbbonamento: map['tipoAbbonamento'],
      dataIscrizione: map['dataIscrizione'],
      isAdmin: map['isAdmin'] == 1, // 👈 converti da int a bool
    );
  }
}