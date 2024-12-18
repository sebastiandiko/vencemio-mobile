import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';

class UserPreferencesPage extends StatefulWidget {
  final String userId;

  const UserPreferencesPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserPreferencesPage> createState() => _UserPreferencesPageState();
}

class _UserPreferencesPageState extends State<UserPreferencesPage> {
  final List<Map<String, String>> _categories = [
    {'name': 'Verduras', 'icon': 'assets/verduras.jpg'},
    {'name': 'Frutas', 'icon': 'assets/frutas.jpg'},
    {'name': 'Limpieza', 'icon': 'assets/limpieza.png'},
    {'name': 'Bebidas', 'icon': 'assets/bebidas.png'},
    {'name': 'Lacteos', 'icon': 'assets/lacteos.png'},
    {'name': 'Panadería', 'icon': 'assets/panaderia.jpg'},
    {'name': 'Enlatados', 'icon': 'assets/enlatados.png'},
    {'name': 'Mascotas', 'icon': 'assets/mascotas.png'},
  ];

  final List<String> _selectedCategories = [];
  bool _isSaving = false;

  Future<void> _savePreferences() async {
    if (_selectedCategories.isEmpty) {
      _showSnackBar('Por favor selecciona al menos una categoría.');
      return;
    }

    setState(() => _isSaving = true);

    final String apiUrl =
        'http://10.0.2.2:5000/api/users/${widget.userId}/preferences';

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'preferences': _selectedCategories}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Preferencias guardadas con éxito.');
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
        _showSnackBar('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error de conexión: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildCategoryCard(Map<String, String> category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategories.remove(category['name']);
          } else if (_selectedCategories.length < 3) {
            _selectedCategories.add(category['name']!);
          } else {
            _showSnackBar('Solo puedes seleccionar hasta 3 categorías.');
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF76c043), Color(0xFF1c802d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFe0f7fa), Color(0xFFffffff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              spreadRadius: 1,
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(category['icon']!),
            ),
            const SizedBox(height: 10),
            Text(
              category['name']!,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCounter() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF76c043),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "Seleccionadas: ${_selectedCategories.length} / 3",
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1c802d),
        title: const Text(
          "Configurar Preferencias",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: Column(
        children: [
          _buildSelectedCounter(),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected =
                    _selectedCategories.contains(category['name']);
                return _buildCategoryCard(category, isSelected);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1c802d),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Guardar Preferencias",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
