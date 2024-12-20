import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'login.dart';
import 'botpresschatpage.dart';
import 'user_preferences.dart';
import 'map_page.dart';
import 'purchasepage.dart';

class HomePage extends StatefulWidget {
  final List<String> userPreferences;
  final String userId;

  const HomePage(
      {Key? key, required this.userPreferences, required this.userId})
      : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _products = [];
  Map<String, Map<String, String>> _supermarketDetails = {};
  String? _selectedCategory = "Todos";
  String? _selectedSupermarket = "Todos";

  Position? _currentPosition;

  final List<String> _categories = [
    'Todos',
    'Bebidas',
    'Limpieza',
    'Verduras',
    'Pastas',
    'Snacks',
    'Panaderia',
    'Enlatados',
    'Mascotas',
    'Frutas',
    'Lacteos'
  ];

  final List<String> _supermarkets = [
    'Todos',
    'SupermaxMaipu359',
    'ImpulsoTucuman1236',
    'ElSuperYrigoyen1773',
    'DepotMarianoMoreno1350',
    'TatuSanLorenzo1050',
    'ImpulsoParaguay997',
    'LaReinaAv.PedroFerré2002',
    'ParadaCangaRaulAlfonsin3496',
    'CarrefourPedroFerré2985',
    'Facor3deAbril1068',
    'SupermaxCarlosPellegrini767',
    'ParadaCangaIndependencia5444'
  ];

  bool _isLoading = true;
  String _errorMessage = '';
  final String _baseUrl = "https://vencemio-api.vercel.app/api";

  @override
  void initState() {
    super.initState();
    _getUserLocation().then((_) => _fetchProducts());
  }

  Future<void> _getUserLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Error al obtener la ubicación: $e";
      });
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String url = "$_baseUrl/productos";

      // Manejo del filtrado doble
      if (_selectedCategory != "Todos" && _selectedSupermarket != "Todos") {
        url =
            "$_baseUrl/productos/filter/${_selectedSupermarket!}/${_selectedCategory!}";
      } else if (_selectedCategory != "Todos") {
        url = "$_baseUrl/productos/byCategory/${_selectedCategory!}";
      } else if (_selectedSupermarket != "Todos") {
        url = "$_baseUrl/productos/byCodSuper/${_selectedSupermarket!}";
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _fetchSupermarketDetails(
            data); // Obtener detalles del supermercado
        setState(() {
          _products = _filterProductsByProximityAndPreferences(
              data); // Filtrar por proximidad y preferencias
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

  Future<void> _fetchSupermarketDetails(List<dynamic> products) async {
    Map<String, Map<String, String>> details = {};
    for (var product in products) {
      final codSuper = product['cod_super'];
      if (!details.containsKey(codSuper)) {
        final response = await http
            .get(Uri.parse("$_baseUrl/superusers/cod_super/$codSuper"));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final ubicacion =
              data['ubicacion']; // Almacenar el valor de 'ubicacion'
          details[codSuper] = {
            'cadena': data['cadena'] ?? 'Desconocido',
            'direccion': data['direccion'] ?? 'Desconocida',
            'latitud': ubicacion != null && ubicacion['latitud'] != null
                ? ubicacion['latitud'].toString()
                : '0.0',
            'longitud': ubicacion != null && ubicacion['longitud'] != null
                ? ubicacion['longitud'].toString()
                : '0.0',
          };
        }
      }
    }
    _supermarketDetails = details;
  }

  List<dynamic> _filterProductsByProximityAndPreferences(
      List<dynamic> products) {
    if (_currentPosition == null) {
      // Si no hay ubicación, priorizamos solo por preferencias
      final preferredProducts = products.where((product) {
        return widget.userPreferences.contains(product['cod_tipo']);
      }).toList();
      final nonPreferredProducts = products.where((product) {
        return !widget.userPreferences.contains(product['cod_tipo']);
      }).toList();

      return [...preferredProducts, ...nonPreferredProducts];
    }

    List<MapEntry<String, double>> distances = [];

    _supermarketDetails.forEach((codSuper, details) {
      final lat = double.tryParse(details['latitud'] ?? '');
      final lon = double.tryParse(details['longitud'] ?? '');
      if (lat != null && lon != null) {
        final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lon,
        );
        distances.add(MapEntry(codSuper, distance));
      }
    });

    // Ordenar los supermercados por distancia
    distances.sort((a, b) => a.value.compareTo(b.value));

    // Obtener supermercados más cercanos en orden
    final closestSupermarkets = distances.map((entry) => entry.key).toList();

    // Separar productos por preferencia
    final preferredProducts = products.where((product) {
      return widget.userPreferences.contains(product['cod_tipo']);
    }).toList();

    final nonPreferredProducts = products.where((product) {
      return !widget.userPreferences.contains(product['cod_tipo']);
    }).toList();

    // Ordenar los productos por proximidad a los supermercados
    List<dynamic> orderedProducts = [];

    for (var codSuper in closestSupermarkets) {
      // Añadir productos preferidos y no preferidos de cada supermercado
      orderedProducts.addAll(preferredProducts.where((product) {
        return product['cod_super'] == codSuper;
      }));
      orderedProducts.addAll(nonPreferredProducts.where((product) {
        return product['cod_super'] == codSuper;
      }));
    }

    return orderedProducts;
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
    final originalPrice =
        double.tryParse(product['precio']?.toString() ?? '0') ?? 0;
    final discountPrice =
        double.tryParse(product['precio_descuento']?.toString() ?? '0') ?? 0;
    final discountPercent =
        ((1 - (discountPrice / originalPrice)) * 100).toStringAsFixed(0);
    final codSuper = product['cod_super'];
    final cadena = _supermarketDetails[codSuper]?['cadena'] ?? 'Cargando...';
    final direccion =
        _supermarketDetails[codSuper]?['direccion'] ?? 'Cargando...';

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$discountPercent% OFF",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
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
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text("Cadena: $cadena"),
                Text("Dirección: $direccion"),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      "\$${originalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "\$${discountPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PurchasePage(product: product),
                      ),
                    );
                  },
                  child: const Text("Comprar", style: TextStyle(fontSize: 16, color: Colors.black)), 
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
      backgroundColor: Color(0xFFFFF5CC), // Color de fondo existente
      appBar: AppBar(
        title: const Text(
          "Catálogo de Productos",
          style: TextStyle(
            color: Color(0xFFFCC40B), // Cambiar color de texto
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF1C802D),
        actions: [
          IconButton(
            icon: const Icon(Icons.map,
                color: Color(0xFFFCC40B)), // Color del ícono
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const MapPage()));
            },
            tooltip: "Ver Mapa",
          ),
          IconButton(
            icon: const Icon(Icons.settings,
                color: Color(0xFFFCC40B)), // Color del ícono
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UserPreferencesPage(userId: widget.userId),
                ),
              );
            },
            tooltip: "Preferencias",
          ),
          IconButton(
            icon: const Icon(Icons.logout,
                color: Color(0xFFFCC40B)), // Color del ícono
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
                      child: Text(
                        category,
                        style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0)), // Color del texto
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _fetchProducts();
                    });
                  },
                ),
                DropdownButton<String>(
                  value: _selectedSupermarket,
                  items: _supermarkets.map((String market) {
                    return DropdownMenuItem<String>(
                      value: market,
                      child: Text(
                        market,
                        style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0)), // Color del texto
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSupermarket = value;
                      _fetchProducts();
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
                        child: Text(
                          _errorMessage,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) =>
                            _buildProductCard(_products[index]),
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
        child:
            const Icon(Icons.chat, color: Color(0xFFFCC40B)), // Color del ícono
        tooltip: "Hablar con el Bot",
      ),
    );
  }
}
