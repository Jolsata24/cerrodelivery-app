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
  // ✅ 1. URL DE PRODUCCIÓN
  final String baseUrl = "https://cerrodelivery.com/";

  MapController _mapController = MapController();
  Timer? _timer;

  // Coordenadas por defecto (Cerro de Pasco)
  LatLng _ubicacionRepartidor = LatLng(-10.683, -76.256);
  LatLng? _ubicacionDestino;

  bool _repartidorAsignado = false;
  bool _cargando = true;
  bool _primeraVezCentrado = false;

  String _estadoTexto = "Cargando...";
  String _nombreRepartidor = "";
  String _telefonoRepartidor = ""; // Nueva variable para el teléfono

  @override
  void initState() {
    super.initState();
    _consultarUbicacion();
    // Actualizar cada 5 segundos
    _timer = Timer.periodic(Duration(seconds: 5), (t) => _consultarUbicacion());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _consultarUbicacion() async {
    try {
      final url = "$baseUrl/api/tracking.php?id_pedido=${widget.pedidoId}";
      print("📡 Consultando: $url"); // Debug en consola

      var res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        print("📥 JSON Recibido: $data"); // Debug para ver qué llega

        if (mounted) {
          setState(() {
            _cargando =
                false; // ✅ SIEMPRE quitamos el cargando al recibir respuesta

            if (data['success'] == true) {
              _estadoTexto = data['estado'] ?? "Estado desconocido";

              // 📦 DATOS DEL DESTINO (CASA)
              if (data['destino'] != null) {
                double latD =
                    double.tryParse(data['destino']['lat'].toString()) ?? 0.0;
                double lngD =
                    double.tryParse(data['destino']['lng'].toString()) ?? 0.0;
                if (latD != 0.0) {
                  _ubicacionDestino = LatLng(latD, lngD);
                }
              }

              // 🛵 DATOS DEL REPARTIDOR
              if (data['asignado'] == true && data['repartidor'] != null) {
                _repartidorAsignado = true;
                _nombreRepartidor =
                    data['repartidor']['nombre'] ?? "Repartidor";
                _telefonoRepartidor = data['repartidor']['telefono'] ?? "";

                double latR =
                    double.tryParse(data['repartidor']['lat'].toString()) ??
                    0.0;
                double lngR =
                    double.tryParse(data['repartidor']['lng'].toString()) ??
                    0.0;

                // Si las coordenadas son válidas, actualizamos la posición
                if (latR != 0.0 && lngR != 0.0) {
                  _ubicacionRepartidor = LatLng(latR, lngR);

                  // Centrar el mapa automáticamente solo la primera vez
                  if (!_primeraVezCentrado) {
                    _mapController.move(_ubicacionRepartidor, 16.0);
                    _primeraVezCentrado = true;
                  }
                }
              } else {
                _repartidorAsignado = false;
                _nombreRepartidor = "Buscando...";
              }
            } else {
              _estadoTexto = data['message'] ?? "Error al obtener datos";
            }
          });
        }
      } else {
        print("❌ Error HTTP: ${res.statusCode}");
      }
    } catch (e) {
      print("💥 Error App: $e");
      if (mounted) {
        setState(() {
          _cargando = false;
          _estadoTexto = "Error de conexión";
        });
      }
    }
  }

  void _centrarMapa() {
    if (_repartidorAsignado) {
      _mapController.move(_ubicacionRepartidor, 16.0);
    } else if (_ubicacionDestino != null) {
      _mapController.move(_ubicacionDestino!, 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pedido #${widget.pedidoId}",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _repartidorAsignado ? Colors.blue : Colors.orange,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _ubicacionRepartidor, // Inicia donde sea (luego se mueve)
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cerrodelivery.app',
              ),
              MarkerLayer(
                markers: [
                  // 📍 MARCADOR DE CASA (DESTINO)
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

                  // 🛵 MARCADOR DEL REPARTIDOR
                  if (_repartidorAsignado)
                    Marker(
                      point: _ubicacionRepartidor,
                      width: 70,
                      height: 70,
                      child: Column(
                        children: [
                          Icon(
                            Icons.two_wheeler, // Icono de moto
                            size: 40,
                            color: Colors.blue[800],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(blurRadius: 2, color: Colors.black26),
                              ],
                            ),
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
                ],
              ),
            ],
          ),

          // 🎯 BOTÓN PARA CENTRAR
          Positioned(
            right: 20,
            bottom: 180,
            child: FloatingActionButton(
              heroTag: "centrar_btn",
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: Colors.blue),
              onPressed: _centrarMapa,
            ),
          ),

          // 📋 TARJETA DE INFORMACIÓN (BOTTOM SHEET)
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
                  // Barra decorativa
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
                        Text("Conectando con el repartidor..."),
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
                          "Buscando Repartidor",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "Tu pedido está siendo procesado.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        // Avatar del Repartidor
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue[100],
                          child: Icon(
                            Icons.person,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 15),
                        // Datos del Repartidor
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    _estadoTexto,
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (_telefonoRepartidor.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "📞 $_telefonoRepartidor",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
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
