import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'carrito_model.dart';
import 'resumen_screen.dart';

class PagoScreen extends StatefulWidget {
  final String direccion, referencia, telefono;
  final double costoEnvio, lat, lng;

  PagoScreen({
    required this.direccion,
    required this.referencia,
    required this.telefono,
    required this.costoEnvio,
    required this.lat,
    required this.lng,
  });

  @override
  _PagoScreenState createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final String baseUrl = "https://cerrodelivery.com";
  String? _yapeNumero, _yapeQr;
  File? _imagenYape;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarInfoYape();
  }

  // (Mantén tu función _cargarInfoYape igual)
  Future<void> _cargarInfoYape() async {
    try {
      int idRes = Carrito.items.first.idRestaurante;
      var res = await http.get(
        Uri.parse(
          "$baseUrl/procesos/obtener_datos_restaurante.php?id_restaurante=$idRes",
        ),
      );
      var data = jsonDecode(res.body);
      setState(() {
        _yapeNumero = data['data']['yape_numero'];
        _yapeQr = data['data']['yape_qr'];
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imagenYape = File(picked.path));
  }

  void _continuar() {
    if (_imagenYape == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Falta la foto del Yape")));
      return;
    }
    double total = Carrito.obtenerTotal() + widget.costoEnvio;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => ResumenScreen(
          direccion: widget.direccion,
          referencia: widget.referencia,
          telefono: widget.telefono,
          costoEnvio: widget.costoEnvio,
          lat: widget.lat,
          lng: widget.lng,
          imagenYape: _imagenYape!,
          totalPagar: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double total = Carrito.obtenerTotal() + widget.costoEnvio;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Realizar Pago",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.75,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(Colors.purple),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(25),
        child: Column(
          children: [
            Text(
              "Monto Total a Pagar",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              "S/ ${total.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 30),

            // TARJETA DE YAPE ESTILIZADA
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF742384), // Color Yape
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: EdgeInsets.all(25),
              child: Column(
                children: [
                  Text(
                    "Escanea el QR o copia el número",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: _yapeQr != null
                        ? Image.network(
                            "$baseUrl/assets/img/qr/$_yapeQr",
                            height: 180,
                          )
                        : CircularProgressIndicator(),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _yapeNumero ?? "...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.white),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _yapeNumero!));
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("¡Copiado!")));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // ZONA DE CARGA DE FOTO
            Text(
              "Adjuntar Comprobante",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            InkWell(
              onTap: _seleccionarFoto,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ), // Se podría usar dotted_border package, pero solid está bien por ahora
                ),
                child: _imagenYape == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: Colors.purple,
                          ),
                          Text(
                            "Toca para subir captura",
                            style: TextStyle(color: Colors.purple),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _imagenYape!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _continuar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  "Revisar Pedido Final 👉",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
