import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart'; // Importa la pantalla HomePage

class UserPreferencesPage extends StatefulWidget {
  final String userId; // ID del usuario para interactuar con el backend

  const UserPreferencesPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserPreferencesPage> createState() => _UserPreferencesPageState();
}

class _UserPreferencesPageState extends State<UserPreferencesPage> {
  final List<Map<String, String>> _categories = [
    {'name': 'Vegetales', 'icon': 'assets/vegetales.png'},
    {'name': 'Limpieza', 'icon': 'assets/limpieza.png'},
    {'name': 'Bebidas', 'icon': 'assets/bebidas.png'},
    {'name': 'Lácteos', 'icon': 'assets/lacteos.png'},
    {'name': 'Panadería', 'icon': 'assets/panaderia.jpg'},
    {'name': 'Enlatados', 'icon': 'assets/enlatados.png'},
    {'name': 'Mascotas', 'icon': 'assets/mascotas.png'},
  ];
  final List<String> _selectedCategories = [];
  bool _isSaving = false;

  Future<void> _savePreferences() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos una categoría.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final String apiUrl =
        'http://10.0.2.2:5000/api/users/${widget.userId}/preferences';

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'preferences': _selectedCategories}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferencias guardadas con éxito.')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              userId: widget.userId,
              userPreferences: _selectedCategories,
            ),
          ),
        );
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Error desconocido.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar preferencias: $errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF5CC), Color.fromARGB(255, 191, 255, 200)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              image: DecorationImage(
                image: AssetImage('assets/LogoVencemio.png'),
                fit: BoxFit.cover,
                opacity: 0.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Selecciona hasta 3 categorías:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1c802d),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected =
                          _selectedCategories.contains(category['name']);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedCategories.remove(category['name']);
                            } else if (_selectedCategories.length < 3) {
                              _selectedCategories.add(category['name']!);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Solo puedes seleccionar hasta 3 categorías.'),
                                ),
                              );
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF76c043)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFfcc40b)
                                  : const Color(0xFF76c043),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: AssetImage(category['icon']!),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                category['name']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF1c802d),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF76c043),
                      padding: const EdgeInsets.symmetric(
                        vertical: 20, // Aumenta el padding vertical
                        horizontal: 40, // Aumenta el padding horizontal
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Guardar y Continuar",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
