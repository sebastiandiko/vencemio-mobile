import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart'; // Para cerrar sesión

import 'user_preferences.dart';
import 'map_page.dart'; // Asegúrate de importar tu clase MapPage

class HomePage extends StatefulWidget {
  final List<String> userPreferences;
  final String userId; // ID del usuario

  const HomePage({Key? key, required this.userPreferences, required this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _products = [];
  String? _selectedCategory = "Todos";
  String? _selectedSupermarket = "Todos";

  final List<String> _categories = ['Todos', 'Bebidas', 'Limpieza', 'Vegetales', 'Lacteos'];
  final List<String> _supermarkets = [
    'Todos',
    'SupermaxMaipu359',
    'ImpulsoTucuman1236',
    'ElSuperYrigoyen1773'
  ];

  bool _isLoading = true;
  String _errorMessage = '';

  final String _baseUrl = "http://10.0.2.2:5000/api";

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String url = "$_baseUrl/productos";

      if (_selectedCategory != "Todos" && _selectedSupermarket != "Todos") {
        url += "/byCategory/${_selectedCategory!}/byCodSuper/${_selectedSupermarket!}";
      } else if (_selectedCategory != "Todos") {
        url += "/byCategory/${_selectedCategory!}";
      } else if (_selectedSupermarket != "Todos") {
        url += "/byCodSuper/${_selectedSupermarket!}";
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          final preferredProducts = data.where((product) {
            return widget.userPreferences.contains(product['cod_tipo']);
          }).toList();

          final nonPreferredProducts = data.where((product) {
            return !widget.userPreferences.contains(product['cod_tipo']);
          }).toList();

          _products = [...preferredProducts, ...nonPreferredProducts];
          _isLoading = false;
        });
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error al cargar productos: ${e.toString()}";
      });
    }
  }

  String _formatExpirationDate(String? fechaVencimiento) {
    if (fechaVencimiento == null) return "Sin fecha";
    final date = DateTime.parse(fechaVencimiento);
    return "${date.day}/${date.month}/${date.year}";
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.popUntil(context, ModalRoute.withName('/')); // Redirige al login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catálogo de Productos"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 0, 164, 44),
        leading: IconButton(
          icon: const Icon(Icons.settings), // Ícono de preferencias
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserPreferencesPage(userId: widget.userId),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map), // Ícono de mapa
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout), // Ícono de salir
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<String>(
                      value: _selectedCategory,
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                        _fetchProducts();
                      },
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(color: Color.fromARGB(255, 2, 161, 71)),
                    ),
                    DropdownButton<String>(
                      value: _selectedSupermarket,
                      items: _supermarkets.map((String supermarket) {
                        return DropdownMenuItem<String>(
                          value: supermarket,
                          child: Text(supermarket),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSupermarket = value;
                        });
                        _fetchProducts();
                      },
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(color: Colors.teal),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(color: Colors.teal),
                        SizedBox(height: 16),
                        Text("Cargando productos...", style: TextStyle(color: Colors.teal)),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final originalPrice = double.tryParse(product['precio']?.toString() ?? '0') ?? 0;
                          final discountPrice = double.tryParse(product['precio_descuento']?.toString() ?? '0') ?? 0;
                          final discountPercent = ((1 - (discountPrice / originalPrice)) * 100).toStringAsFixed(2);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            color: const Color.fromARGB(255, 232, 243, 231),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: product['imagen'] != null && product['imagen'].isNotEmpty
                                        ? Image.network(
                                            product['imagen'],
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.image_not_supported, size: 80),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['nombre'] ?? "Sin nombre",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Antes: \$${originalPrice.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "Ahora: \$${discountPrice.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(255, 0, 110, 11),
                                          ),
                                        ),
                                        Text(
                                          "${discountPercent}% OFF",
                                          style: const TextStyle(color: Color.fromARGB(255, 0, 155, 23)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
