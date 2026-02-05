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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Esto hace que el mapa suba hasta arriba del todo
      appBar: AppBar(
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Text(
            "Pedido #${widget.pedidoId}",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.transparent, // Transparente para ver el mapa
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
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
              // 1. EL NUEVO MAPA SUAVE
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cerrodelivery.app',
              ),

              // 2. MARCADORES ESTILO "UBER" (Burbujas con sombra)
              MarkerLayer(
                markers: [
                  // 📍 MARCADOR DE CASA (DESTINO)
                  if (_ubicacionDestino != null)
                    Marker(
                      point: _ubicacionDestino!,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.home_rounded,
                              size: 28,
                              color: Colors.redAccent,
                            ),
                          ),
                          // Triangulito simulado
                          Icon(
                            Icons.arrow_drop_down,
                            size: 24,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),

                  // 🛵 MARCADOR DEL REPARTIDOR (MOTO)
                  if (_repartidorAsignado)
                    Marker(
                      point: _ubicacionRepartidor,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors
                                  .black87, // Fondo oscuro para resaltar la moto
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.delivery_dining,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 2),
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(blurRadius: 2, color: Colors.black12),
                              ],
                            ),
                            child: Text(
                              "Tu pedido",
                              style: TextStyle(
                                fontSize: 9,
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

          // 🎯 BOTÓN DE CENTRAR FLOTANTE (Minimalista)
          Positioned(
            right: 20,
            bottom: 240, // Un poco más arriba de la tarjeta
            child: FloatingActionButton(
              heroTag: "centrar_btn",
              backgroundColor: Colors.white,
              elevation: 4,
              mini: true, // Más pequeño y elegante
              child: Icon(Icons.gps_fixed, color: Colors.black87),
              onPressed: _centrarMapa,
            ),
          ),

          // 📋 TARJETA DE INFORMACIÓN MODERNA (Sin bordes duros)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30), // Bordes muy redondos
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Sombra muy suave
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_cargando)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(width: 15),
                        Text(
                          "Localizando...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else if (!_repartidorAsignado)
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            size: 30,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Buscando Repartidor",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Estamos notificando a los conductores cerca.",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        // Avatar Grande y Limpio
                        Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey[100],
                            backgroundImage: AssetImage(
                              'assets/img/repartidor.jpg',
                            ), // Asegúrate de tener una imagen default
                            child: Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                        SizedBox(width: 15),

                        // Textos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nombreRepartidor,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _estadoTexto.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Botón de Llamar (Circular)
                        if (_telefonoRepartidor.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.phone, color: Colors.green),
                              onPressed: () {
                                // Aquí podrías agregar url_launcher para llamar real
                              },
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
