import 'package:flutter/material.dart';
import '../model/utente.dart';
import 'report_page.dart';
import 'vendite_page.dart';
import 'cassa_page.dart';
import 'prodotti_page.dart';
import 'gestione_utenti_page.dart';

class HomeScreen extends StatefulWidget {
  final Utente utenteLoggato;

  const HomeScreen({super.key, required this.utenteLoggato});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ReportPage(utente: widget.utenteLoggato),
      VenditePage(utente: widget.utenteLoggato),
      CassaPage(utente: widget.utenteLoggato),
      const ProdottiPage(),
      (widget.utenteLoggato.isAdmin || widget.utenteLoggato.email == 'admin@dicotec.it')
          ? GestioneUtentiPage(utenteLoggato: widget.utenteLoggato)
          : const Center(child: Text('👤 Profilo')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Vendite'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Cassa'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Prodotti'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
        ],
      ),
    );
  }
}