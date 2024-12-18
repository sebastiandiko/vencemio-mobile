import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationConfigPage extends StatefulWidget {
  const NotificationConfigPage({Key? key}) : super(key: key);

  @override
  State<NotificationConfigPage> createState() => _NotificationConfigPageState();
}

class _NotificationConfigPageState extends State<NotificationConfigPage> {
  final List<String> _daysOfWeek = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];
  List<dynamic> _products = []; // Lista dinámica para productos desde la API
  final List<String> _selectedDays = [];
  String? _selectedProduct;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts(); // Llamar al método para obtener los productos
  }

  // Método para obtener productos desde la API
  Future<void> _fetchProducts() async {
    const String endpoint = "https://vencemio-api.vercel.app/api/productos"; // Endpoint de tu API
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Productos obtenidos: $data");

        setState(() {
          _products = data;
          _isLoading = false;
        });
      } else {
        print("Error al obtener productos: ${response.statusCode}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error al obtener productos: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método para enviar una notificación
  Future<void> _sendNotification() async {
    if (_selectedDays.isEmpty || _selectedTime == null || _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos.')),
      );
      return;
    }

    final hour = _selectedTime!.hour;
    final minute = _selectedTime!.minute;

    print('Configuración de Notificación:');
    print('Días: $_selectedDays');
    print('Producto: $_selectedProduct');
    print('Hora: $hour:$minute');

    // Aquí deberías implementar la lógica para enviar la notificación a través de FCM.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificación enviada (simulación).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurar Notificaciones"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Mostrar un indicador de carga
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selecciona los días:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 10,
                    children: _daysOfWeek.map((day) {
                      final isSelected = _selectedDays.contains(day);
                      return ChoiceChip(
                        label: Text(day),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            isSelected
                                ? _selectedDays.remove(day)
                                : _selectedDays.add(day);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Selecciona el producto:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedProduct,
                    hint: const Text("Elige un producto"),
                    items: _products.map<DropdownMenuItem<String>>((product) {
                      return DropdownMenuItem<String>(
                        value: product['nombre'], // Usa el nombre del producto
                        child: Text(product['nombre']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProduct = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Selecciona la hora:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _selectedTime = pickedTime;
                        });
                      }
                    },
                    child: Text(_selectedTime == null
                        ? "Elige una hora"
                        : "Hora seleccionada: ${_selectedTime!.format(context)}"),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _sendNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Center(
                      child: Text(
                        "Enviar Notificación",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
