import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'carrito_model.dart';
import 'sesion.dart';
import 'home_screen.dart';
import 'widgets/cerro_loader.dart'; // Asegúrate de haber creado este archivo

class ResumenScreen extends StatefulWidget {
  final String direccion, referencia, telefono;
  final double costoEnvio, lat, lng, totalPagar;
  final File imagenYape;

  ResumenScreen({
    required this.direccion,
    required this.referencia,
    required this.telefono,
    required this.costoEnvio,
    required this.lat,
    required this.lng,
    required this.totalPagar,
    required this.imagenYape,
  });

  @override
  _ResumenScreenState createState() => _ResumenScreenState();
}

class _ResumenScreenState extends State<ResumenScreen> {
  // ⚠️ REVISA QUE ESTA URL SEA LA CORRECTA DE TU NGROK
  final String baseUrl = "https://cerrodelivery.com";

  bool _enviando = false;

  Future<void> _confirmarPedido() async {
    // Al poner esto en true, el build detectará el cambio y mostrará el CerroLoader
    setState(() => _enviando = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/api/pedidos.php?accion=crear"),
      );

      // Datos básicos
      request.fields['id_cliente'] = Sesion.id.toString();
      request.fields['restaurante_id'] = Carrito.items.first.idRestaurante
          .toString();
      request.fields['direccion'] = widget.direccion;
      request.fields['referencia'] = widget.referencia;
      request.fields['telefono'] = widget.telefono;
      request.fields['metodo_pago'] = "yape";
      request.fields['total'] = widget.totalPagar.toString();
      request.fields['latitud'] = widget.lat.toString();
      request.fields['longitud'] = widget.lng.toString();

      // El carrito lo enviamos como texto JSON
      request.fields['carrito'] = jsonEncode(
        Carrito.items.map((e) => e.toJson()).toList(),
      );

      // Adjuntar la imagen del Yape
      request.files.add(
        await http.MultipartFile.fromPath(
          'evidencia_yape',
          widget.imagenYape.path,
        ),
      );

      // Enviar
      var res = await request.send();
      var responseBytes = await res.stream.bytesToString();
      var data = jsonDecode(responseBytes);

      if (data['success'] == true) {
        Carrito.limpiar();

        // Mostramos el diálogo de éxito
        if (mounted) {
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (c) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Icon(Icons.check_circle, size: 80, color: Colors.green),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "¡Pedido Recibido!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Tu pedido #${data['pedido_id']} ha sido enviado. El restaurante lo confirmará pronto.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (c) => HomeScreen(nombreUsuario: Sesion.nombre),
                    ),
                    (r) => false,
                  ),
                  child: Text(
                    "VOLVER AL INICIO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${data['message']}")));
          setState(
            () => _enviando = false,
          ); // Volver a mostrar el formulario si falló
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de conexión al servidor")),
        );
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 AQUÍ ESTÁ EL CAMBIO IMPORTANTE:
    // Si se está enviando, reemplazamos toda la pantalla por la animación
    if (_enviando) {
      return Scaffold(body: CerroLoader(texto: "Confirmando tu pedido..."));
    }

    // Si NO se está enviando, mostramos el resumen normal
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Resumen",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(Colors.green),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // TARJETA DE DETALLES
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Detalle del Pedido",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(height: 30),
                  ...Carrito.items
                      .map(
                        (e) => Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${e.cantidad} x ${e.nombre}"),
                              Text(
                                "S/ ${(e.precio * e.cantidad).toStringAsFixed(2)}",
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Subtotal", style: TextStyle(color: Colors.grey)),
                      Text("S/ ${Carrito.obtenerTotal().toStringAsFixed(2)}"),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Envío", style: TextStyle(color: Colors.grey)),
                      Text("S/ ${widget.costoEnvio.toStringAsFixed(2)}"),
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TOTAL",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        "S/ ${widget.totalPagar.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // TARJETA DE ENTREGA
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Entregar en:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.orange, size: 20),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.direccion,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.grey, size: 20),
                      SizedBox(width: 5),
                      Text(widget.telefono),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // BOTÓN CONFIRMAR
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                    _confirmarPedido, // Ya no necesitamos verificar _enviando aquí porque la pantalla cambia
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 5,
                  shadowColor: Colors.green.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  "CONFIRMAR PEDIDO ✅",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
