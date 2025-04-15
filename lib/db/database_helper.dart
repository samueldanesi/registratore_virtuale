import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../model/product.dart';
import '../model/scontrino.dart';
import '../model/utente.dart';

class ProductDatabase {
  static final ProductDatabase instance = ProductDatabase._init();
  static Database? _database;

  ProductDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('products.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE prodotti (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descrizione TEXT,
        prezzo REAL NOT NULL,
        iva REAL NOT NULL,
        categoria TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE scontrini (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        ora TEXT NOT NULL,
        prodotti TEXT NOT NULL,
        totale REAL NOT NULL,
        nome TEXT,
        intestatario TEXT,
        partitaIva TEXT,
        codiceFiscale TEXT,
        indirizzo TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE preconti (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        ora TEXT NOT NULL,
        prodotti TEXT NOT NULL,
        totale REAL NOT NULL,
        nome TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE utenti (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        nome TEXT NOT NULL,
        cognome TEXT NOT NULL,
        telefono TEXT,
        partitaIva TEXT,
        codiceFiscale TEXT,
        indirizzo TEXT,
        tipoAbbonamento TEXT NOT NULL,
        dataIscrizione TEXT NOT NULL,
        isAdmin INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS preconti (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          data TEXT NOT NULL,
          ora TEXT NOT NULL,
          prodotti TEXT NOT NULL,
          totale REAL NOT NULL,
          nome TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE scontrini ADD COLUMN nome TEXT");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE prodotti ADD COLUMN categoria TEXT DEFAULT 'Generico'");
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS utenti (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          nome TEXT NOT NULL,
          cognome TEXT NOT NULL,
          telefono TEXT,
          partitaIva TEXT,
          codiceFiscale TEXT,
          indirizzo TEXT,
          tipoAbbonamento TEXT NOT NULL,
          dataIscrizione TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE utenti ADD COLUMN isAdmin INTEGER NOT NULL DEFAULT 0");
    }
    if (oldVersion < 7) {
      await db.execute("ALTER TABLE scontrini ADD COLUMN intestatario TEXT");
      await db.execute("ALTER TABLE scontrini ADD COLUMN partitaIva TEXT");
      await db.execute("ALTER TABLE scontrini ADD COLUMN codiceFiscale TEXT");
      await db.execute("ALTER TABLE scontrini ADD COLUMN indirizzo TEXT");
    }
    if (oldVersion < 8) {
  await db.execute("ALTER TABLE scontrini ADD COLUMN intestatario TEXT");
  await db.execute("ALTER TABLE scontrini ADD COLUMN partitaIva TEXT");
  await db.execute("ALTER TABLE scontrini ADD COLUMN codiceFiscale TEXT");
  await db.execute("ALTER TABLE scontrini ADD COLUMN indirizzo TEXT");
}
  }

  // ================= METODI PRODOTTI =================
  Future<void> create(Product prodotto) async {
    final db = await instance.database;
    await db.insert('prodotti', prodotto.toMap());
  }

  Future<List<Product>> readAll() async {
    final db = await instance.database;
    final result = await db.query('prodotti');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<void> update(Product prodotto) async {
    final db = await instance.database;
    await db.update(
      'prodotti',
      prodotto.toMap(),
      where: 'id = ?',
      whereArgs: [prodotto.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await instance.database;
    await db.delete('prodotti', where: 'id = ?', whereArgs: [id]);
  }

  // ================= METODI SCONTRINI =================
  Future<void> inserisciScontrino(Scontrino scontrino) async {
    final db = await instance.database;
    await db.insert('scontrini', scontrino.toMap());
  }

  Future<List<Scontrino>> leggiTuttiScontrini() async {
    final db = await instance.database;
    final result = await db.query('scontrini', orderBy: 'id DESC');
    return result.map((map) => Scontrino.fromMap(map)).toList();
  }

  // ================= METODI PRECONTI =================
  Future<void> inserisciPreconto(Scontrino scontrino) async {
    final db = await instance.database;
    await db.insert('preconti', scontrino.toMap());
  }

  Future<List<Scontrino>> leggiTuttiPreconti() async {
    final db = await instance.database;
    final result = await db.query('preconti', orderBy: 'id DESC');
    return result.map((map) => Scontrino.fromMap(map)).toList();
  }

  Future<void> eliminaPreconto(int id) async {
    final db = await instance.database;
    await db.delete('preconti', where: 'id = ?', whereArgs: [id]);
  }

  // ================= METODI UTENTI =================
  Future<void> inserisciUtente(Utente user) async {
    final db = await instance.database;
    await db.insert('utenti', user.toMap());
  }

  Future<List<Utente>> leggiTuttiUtenti() async {
    final db = await instance.database;
    final result = await db.query('utenti');
    return result.map((map) => Utente.fromMap(map)).toList();
  }

  Future<Utente?> login(String email, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'utenti',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return Utente.fromMap(result.first);
    } else {
      return null;
    }
  }

  // ================= REPORTING =================
  Future<Map<String, double>> prodottiPiuVenduti() async {
    final db = await instance.database;
    final rows = await db.query('scontrini');
    final Map<String, double> conteggi = {};

    for (final row in rows) {
      final List prodotti = jsonDecode(row['prodotti'] as String);
      for (final p in prodotti) {
        final nome = p['nome'];
        final quantita = (p['quantita'] as num).toDouble();
        if (nome.startsWith('Nota:')) continue;
        conteggi[nome] = (conteggi[nome] ?? 0) + quantita;
      }
    }

    return conteggi;
  }

  Future<Map<int, Map<String, double>>> incassiFiltrati(String filtro) async {
    final db = await instance.database;
    final rows = await db.query('scontrini');

    final now = DateTime.now();
    DateTime inizio;
    switch (filtro) {
      case 'oggi':
        inizio = DateTime(now.year, now.month, now.day);
        break;
      case 'settimana':
        inizio = now.subtract(const Duration(days: 7));
        break;
      case 'mese':
        inizio = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3mesi':
        inizio = DateTime(now.year, now.month - 3, now.day);
        break;
      case '6mesi':
        inizio = DateTime(now.year, now.month - 6, now.day);
        break;
      case 'anno':
        inizio = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        inizio = DateTime(2000);
    }

    final Map<int, Map<String, double>> incassi = {};

    for (final row in rows) {
      final data = DateFormat('dd/MM/yyyy').parse(row['data'] as String);
      if (data.isAfter(inizio)) {
        final giorno = data.day;
        final totale = (row['totale'] as num).toDouble();
        incassi[giorno] = {
          'totale': (incassi[giorno]?['totale'] ?? 0) + totale,
        };
      }
    }

    return incassi;
  }
}