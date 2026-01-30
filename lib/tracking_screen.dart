import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class TrackingScreen extends StatefulWidget {
  final String pedidoId;
  TrackingScreen({required this.pedidoId});

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // ⚠️ TU URL DE NGROK
  final String baseUrl = "https://cerrodelivery.com";

  MapController _mapController = MapController();
  Timer? _timer;

  // Coordenadas por defecto (Cerro de Pasco)
  LatLng _ubicacionRepartidor = LatLng(-10.683, -76.256);
  LatLng? _ubicacionDestino;

  bool _repartidorAsignado = false;
  bool _cargando = true;
  bool _primeraVezCentrado =
      false; // 👈 NUEVA VARIABLE PARA CONTROLAR EL CENTRADO
  String _estadoTexto = "Cargando...";
  String _nombreRepartidor = "";

  @override
  void initState() {
    super.initState();
    _consultarUbicacion();
    _timer = Timer.periodic(Duration(seconds: 5), (t) => _consultarUbicacion());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _consultarUbicacion() async {
    try {
      var res = await http.get(
        Uri.parse("$baseUrl/api/tracking.php?id_pedido=${widget.pedidoId}"),
      );
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);

        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _cargando = false;
              _estadoTexto = data['estado'];

              if (data['asignado'] == true) {
                _repartidorAsignado = true;
                _nombreRepartidor = data['repartidor']['nombre'];

                // Parseo seguro de coordenadas
                double latR =
                    double.tryParse(data['repartidor']['lat'].toString()) ??
                    0.0;
                double lngR =
                    double.tryParse(data['repartidor']['lng'].toString()) ??
                    0.0;

                // Si viene 0, usamos default para no romper el mapa
                if (latR == 0.0 || lngR == 0.0) {
                  latR = -10.683;
                  lngR = -76.256;
                } else {
                  // SI TENEMOS UBICACIÓN REAL:
                  _ubicacionRepartidor = LatLng(latR, lngR);

                  // 🔥 EL TRUCO MAGICO:
                  // Si es la primera vez que recibimos datos válidos, movemos la cámara ahí
                  if (!_primeraVezCentrado) {
                    _mapController.move(_ubicacionRepartidor, 16.0);
                    _primeraVezCentrado =
                        true; // Ya no lo movemos más para dejar que el usuario explore
                  }
                }

                if (data['destino'] != null) {
                  _ubicacionDestino = LatLng(
                    double.parse(data['destino']['lat'].toString()),
                    double.parse(data['destino']['lng'].toString()),
                  );
                }
              } else {
                _repartidorAsignado = false;
                _nombreRepartidor = "Buscando...";
              }
            });
          }
        }
      }
    } catch (e) {
      print("Error tracking: $e");
    }
  }

  // Función para centrar manualmente
  void _centrarMapa() {
    if (_repartidorAsignado) {
      _mapController.move(_ubicacionRepartidor, 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Rastrear Pedido #${widget.pedidoId}",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: _repartidorAsignado ? Colors.blue : Colors.orange,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _ubicacionRepartidor,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app_delivery_cliente',
              ),
              MarkerLayer(
                markers: [
                  if (_repartidorAsignado)
                    Marker(
                      point: _ubicacionRepartidor,
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          Icon(
                            Icons.delivery_dining,
                            size: 40,
                            color: Colors.blue,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            color: Colors.white,
                            child: Text(
                              "Repartidor",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_ubicacionDestino != null)
                    Marker(
                      point: _ubicacionDestino!,
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.home_filled,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // BOTÓN FLOTANTE PARA RE-CENTRAR 📍
          Positioned(
            right: 20,
            bottom: 180, // Arriba de la tarjeta de info
            child: FloatingActionButton(
              heroTag: "centrar_btn",
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: Colors.blue),
              onPressed: _centrarMapa,
            ),
          ),

          // TARJETA INFERIOR (Igual que antes)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(height: 15),

                  if (_cargando)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(width: 15),
                        Text("Conectando..."),
                      ],
                    )
                  else if (!_repartidorAsignado)
                    Column(
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 50,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Repartidor no asignado",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "Esperando confirmación del restaurante...",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blue[100],
                          child: Icon(Icons.person, color: Colors.blue),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nombreRepartidor,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                "$_estadoTexto • En camino",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
