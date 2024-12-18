import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const MAPBOX_TOKEN =
    "pk.eyJ1Ijoic2ViYWRpa28iLCJhIjoiY20zcnI4dXRpMDhuOTJqcHh4ejgwc2Y0NCJ9.0h5pj5U8ub9Wa9gr3Z7ZLQ";

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? currentPosition;
  late final MapController _mapController;
  final double initialZoom = 15.0;

  List<Marker> supermarketMarkers = []; // Lista de marcadores para supermercados

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _determinePosition();
  }

  // Método para obtener la ubicación del usuario
Future<void> _determinePosition() async {
  print("Verificando si el servicio de ubicación está habilitado...");
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("El servicio de ubicación está deshabilitado.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('El servicio de ubicación está deshabilitado. Actívalo.')),
    );
    return;
  }

  print("Verificando permisos de ubicación...");
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    print("Permiso denegado. Solicitando permisos...");
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print("Permiso de ubicación denegado.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de ubicación denegado.')),
      );
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print("Permiso de ubicación denegado permanentemente.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permiso de ubicación denegado permanentemente.'),
      ),
    );
    return;
  }

  print("Obteniendo la posición actual del usuario...");
  final position = await Geolocator.getCurrentPosition();
  print("Posición actual: lat=${position.latitude}, lng=${position.longitude}");

  setState(() {
    currentPosition = LatLng(position.latitude, position.longitude);
  });

  if (currentPosition != null) {
    print("Centrando el mapa en la posición actual.");
    // Mover el mapa solo después de que FlutterMap esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(currentPosition!, initialZoom);
    });
  }

  // Después de obtener la ubicación del usuario, obtenemos los supermercados
  _fetchSupermarkets();
}


  // Método para obtener datos de supermercados desde el endpoint
  Future<void> _fetchSupermarkets() async {
    const url = "https://vencemio-api.vercel.app/api/superusers"; // URL base para obtener supermercados
    print("Solicitando datos de supermercados desde $url...");

    try {
      final response = await http.get(Uri.parse(url));
      print("Estado de la respuesta: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("Datos recibidos (${data.length} supermercados): $data");

        setState(() {
          // Crea marcadores para cada supermercado
          supermarketMarkers = data.map<Marker>((superuser) {
            final LatLng location = LatLng(
              superuser['ubicacion']['latitud'],
              superuser['ubicacion']['longitud'],
            );

            print(
                "Añadiendo marcador para ${superuser['cadena']} en lat=${location.latitude}, lng=${location.longitude}");

            return Marker(
              point: location,
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () {
                  print("Marcador tocado: ${superuser['cadena']}");
                  // Mostrar un cuadro de diálogo con información del supermercado
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(superuser['cadena']),
                      content: Text(
                          "Dirección: ${superuser['direccion']}\nCiudad: ${superuser['ciudad']}\nTeléfono: ${superuser['telefono']}"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cerrar"),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(
                  Icons.store,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            );
          }).toList();

          print("Total de marcadores creados: ${supermarketMarkers.length}");
        });
      } else {
        print("Error al obtener supermercados: ${response.statusCode}");
        throw Exception("Error al obtener supermercados: ${response.statusCode}");
      }
    } catch (e) {
      print("Error al cargar supermercados: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar supermercados: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Construyendo la pantalla de mapa...");

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Mapa'),
        backgroundColor: Colors.green,
      ),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPosition ?? LatLng(0, 0), // Proveer un valor predeterminado
                initialZoom: initialZoom,
                minZoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}@2x?access_token={accessToken}',
                  additionalOptions: const {
                    'accessToken': MAPBOX_TOKEN,
                    'id': 'mapbox/streets-v12',
                  },
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    if (currentPosition != null)
                      Marker(
                        point: currentPosition!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ...supermarketMarkers, // Agrega los marcadores de los supermercados
                  ],
                ),
              ],
            ),
    );
  }
}
