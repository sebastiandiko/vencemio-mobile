import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiTestPage extends StatefulWidget {
  const ApiTestPage({Key? key}) : super(key: key);

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Método para obtener productos de la API
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse("https://vencemio-api.vercel.app/api/productos/byCategory/Lacteos"), // Cambia la URL si usas un dispositivo físico
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _products = data; // Actualiza la lista de productos
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  // Método para formatear la fecha de vencimiento
  String _formatExpirationDate(Map<String, dynamic> fechaVencimiento) {
    final seconds = fechaVencimiento['_seconds'];
    final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts(); // Cargar productos al iniciar la vista
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prueba API"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Loader mientras se cargan los datos
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage)) // Muestra el mensaje de error
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        leading: product['imagen'] != null && product['imagen'].isNotEmpty
                            ? Image.network(
                                product['imagen'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported),
                        title: Text(
                          product['nombre'] ?? "Sin nombre",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Precio: \$${product['precio'] ?? 0}"),
                            Text("Precio descuento: \$${product['precio_descuento'] ?? 0}"),
                            Text("Stock: ${product['stock'] ?? 0}"),
                            Text("Vence: ${_formatExpirationDate(product['fecha_vencimiento'])}"),
                          ],
                        ),
                        trailing: Text(
                          "${product['porcentaje_descuento'] ?? 0}% OFF",
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
