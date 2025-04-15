// lib/model/user.dart
class User {
  final int? id;
  final String email;
  final String password;
  final String statoAbbonamento; // "prova" o "annuale"
  final String dataIscrizione;

  User({
    this.id,
    required this.email,
    required this.password,
    required this.statoAbbonamento,
    required this.dataIscrizione,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'password': password,
        'statoAbbonamento': statoAbbonamento,
        'dataIscrizione': dataIscrizione,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'],
        email: map['email'],
        password: map['password'],
        statoAbbonamento: map['statoAbbonamento'],
        dataIscrizione: map['dataIscrizione'],
      );
}