import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'dart:convert';

class PurchasePage extends StatefulWidget {
  final Map<String, dynamic> product;

  const PurchasePage({Key? key, required this.product}) : super(key: key);

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  int _quantity = 1;
  String _selectedPaymentMethod = "Efectivo";
  bool _isLoading = false;

  Future<void> _storePurchase(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final url = "http://10.0.2.2:5000/api/ventas"; // Endpoint de la API

    final discountPrice =
        double.tryParse(widget.product['precio_descuento'].toString()) ?? 0;

    final total = discountPrice * _quantity;

    final purchaseData = {
      "cantidad": _quantity,
      "cod_super": widget.product['cod_super'] ?? "Desconocido",
      "cod_tipo": widget.product['cod_tipo'] ?? "Desconocido",
      "descuento_aplicado": ((1 - (discountPrice / widget.product['precio'])) * 100).round(),
      "fecha": DateTime.now().toIso8601String(),
      "forma_pago": _selectedPaymentMethod,
      "precio_descuento": discountPrice,
      "precio_unitario": widget.product['precio'] ?? 0,
      "producto_id": widget.product['id'] ?? "N/A",
      "total": total,
      "user_id": "963aa9e8-e102-437e-8a8a-a66bad114e67", // ID del usuario
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(purchaseData),
      );

      if (response.statusCode == 201) {
        // Almacén exitoso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compra registrada exitosamente."),
            backgroundColor: Colors.green,
          ),
        );
        await _generatePDF(context, purchaseData);
      } else {
        throw Exception("Error al registrar la compra.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generatePDF(BuildContext context, Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Factura de Compra",
                  style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text("Producto: ${widget.product['nombre']}", style: const pw.TextStyle(fontSize: 20)),
              pw.Text("Cantidad: ${data['cantidad']}"),
              pw.Text("Precio Unitario: \$${data['precio_unitario']}"),
              pw.Text("Descuento Aplicado: ${data['descuento_aplicado']}%"),
              pw.Text("Total: \$${data['total']}"),
              pw.Text("Forma de Pago: ${data['forma_pago']}"),
              pw.Text("Fecha: ${now.day}/${now.month}/${now.year}"),
              pw.SizedBox(height: 20),
              pw.Text("¡Gracias por su compra!",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File("${output.path}/factura_${widget.product['nombre']}.pdf");
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Factura descargada: ${file.path}"),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discountPrice =
        double.tryParse(widget.product['precio_descuento'].toString()) ?? 0;
    final total = discountPrice * _quantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de Compra"),
        backgroundColor: const Color.fromARGB(255, 0, 164, 44),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.product['imagen'],
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.product['nombre'] ?? "Producto",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("Precio con Descuento: \$${discountPrice.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 18, color: Colors.green)),
                  const SizedBox(height: 8),

                  // Selección de cantidad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Cantidad: ", style: TextStyle(fontSize: 18)),
                      DropdownButton<int>(
                        value: _quantity,
                        items: List.generate(10, (index) => index + 1)
                            .map((e) => DropdownMenuItem<int>(
                                  value: e,
                                  child: Text(e.toString()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _quantity = value!;
                          });
                        },
                      ),
                    ],
                  ),

                  // Forma de pago
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Forma de Pago: ", style: TextStyle(fontSize: 18)),
                      DropdownButton<String>(
                        value: _selectedPaymentMethod,
                        items: ["Efectivo", "Tarjeta de crédito", "Transferencia"]
                            .map((method) => DropdownMenuItem<String>(
                                  value: method,
                                  child: Text(method),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text("Total: \$${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),

                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 164, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      ),
                      onPressed: () => _storePurchase(context),
                      child: const Text("Confirmar Compra",
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
