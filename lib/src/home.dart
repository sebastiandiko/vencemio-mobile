import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vencemio/src/login.dart';
import 'package:vencemio/src/botpresschatpage.dart'; // Importa la página del chat de Botpress
import 'dart:convert';
import 'user_preferences.dart';
import 'map_page.dart';
import 'purchasepage.dart';

class HomePage extends StatefulWidget {
  final List<String> userPreferences;
  final String userId;

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

  final String _baseUrl = "https://vencemio-api.vercel.app/api";

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

      if (_selectedCategory != "Todos" && _selectedSupermarket == "Todos") {
        url += "/byCategory/${_selectedCategory!}";
      } else if (_selectedSupermarket != "Todos" && _selectedCategory == "Todos") {
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

  void _resetCategory() {
    setState(() {
      _selectedCategory = "Todos";
      _fetchProducts();
    });
  }

  void _resetSupermarket() {
    setState(() {
      _selectedSupermarket = "Todos";
      _fetchProducts();
    });
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Sesión cerrada exitosamente."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildProductCard(product) {
    final originalPrice = double.tryParse(product['precio']?.toString() ?? '0') ?? 0;
    final discountPrice = double.tryParse(product['precio_descuento']?.toString() ?? '0') ?? 0;
    final discountPercent = ((1 - (discountPrice / originalPrice)) * 100).toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  product['imagen'] ?? '',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (discountPrice < originalPrice)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$discountPercent% OFF",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['nombre'] ?? "Sin nombre",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      "\$${originalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "\$${discountPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PurchasePage(product: product),
                      ),
                    );
                  },
                  child: const Text("Comprar", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catálogo de Productos"),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage()));
            },
            tooltip: "Ver Mapa",
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserPreferencesPage(userId: widget.userId),
                ),
              );
            },
            tooltip: "Preferencias",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Cerrar Sesión",
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                      _resetSupermarket();
                    });
                  },
                ),
                DropdownButton<String>(
                  value: _selectedSupermarket,
                  items: _supermarkets.map((String market) {
                    return DropdownMenuItem<String>(
                      value: market,
                      child: Text(market),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSupermarket = value;
                      _resetCategory();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Text(_errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 16)),
                      )
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) => _buildProductCard(_products[index]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BotpressChat()),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.chat),
        tooltip: "Hablar con el Bot",
      ),
    );
  }
}
