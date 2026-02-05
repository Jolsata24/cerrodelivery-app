import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;
import 'carrito_model.dart';
import 'sesion.dart';
import 'pago_screen.dart';

class UbicacionScreen extends StatefulWidget {
  @override
  _UbicacionScreenState createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  // ⚠️ TU URL DE NGROK
  final String baseUrl = "https://cerrodelivery.com";

  MapController _mapController = MapController();
  LatLng _ubicacionCliente = LatLng(-10.683, -76.256); // Default Pasco
  LatLng? _ubicacionRestaurante;

  TextEditingController _direccionCtrl = TextEditingController();
  TextEditingController _refCtrl = TextEditingController();
  TextEditingController _telCtrl = TextEditingController();

  double _costoEnvio = 5.00;

  @override
  void initState() {
    super.initState();
    if (Carrito.items.isNotEmpty) _obtenerDatosRestaurante();
    _cargarTelefonoCliente();
    _obtenerUbicacionActual();
  }

  // 1. DATOS RESTAURANTE
  Future<void> _obtenerDatosRestaurante() async {
    int idRes = Carrito.items.first.idRestaurante;
    try {
      var res = await http.get(
        Uri.parse(
          "$baseUrl/procesos/obtener_datos_restaurante.php?id_restaurante=$idRes",
        ),
      );
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _ubicacionRestaurante = LatLng(
              double.parse(data['data']['latitud']),
              double.parse(data['data']['longitud']),
            );
          });
          _recalcularEnvio();
        }
      }
    } catch (e) {
      print(e);
    }
  }

  // 2. TELEFONO CLIENTE
  Future<void> _cargarTelefonoCliente() async {
    String url =
        "$baseUrl/api/perfil.php?accion=obtener&id_cliente=${Sesion.id}";
    try {
      var res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _telCtrl.text = data['data']['telefono'] ?? '';
          });
        }
      }
    } catch (e) {
      print("Error cargando teléfono: $e");
    }
  }

  // 3. GPS + GEOCODING MEJORADO
  Future<void> _obtenerUbicacionActual() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Activa tu GPS para ubicarte")));
      return;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return;
    }

    // Obtenemos coordenadas exactas
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Texto por defecto: Las coordenadas (Por si falla el nombre de la calle)
    String direccionFinal =
        "Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}";

    // Intentamos traducir a Nombre de Calle
    try {
      List<Placemark> marks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (marks.isNotEmpty) {
        var p = marks[0];

        // Verificamos si realmente trajo el nombre de la calle
        if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) {
          String calle = p.thoroughfare!;
          String numero = p.subThoroughfare ?? '';
          String zona = p.subLocality ?? '';
          direccionFinal = "$calle $numero, $zona".trim();
        }
      }
    } catch (e) {
      print("No se encontró nombre de calle, usando coordenadas.");
    }

    // Actualizamos UI
    setState(() {
      _direccionCtrl.text = direccionFinal;
      _ubicacionCliente = LatLng(pos.latitude, pos.longitude);
      _mapController.move(_ubicacionCliente, 16);
    });

    _recalcularEnvio();

    // MENSAJE DE ÉXITO VISUAL ✅
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Ubicación detectada con éxito"),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 4. CÁLCULO DE ENVÍO
  void _recalcularEnvio() {
    if (_ubicacionRestaurante == null) return;
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((_ubicacionRestaurante!.latitude - _ubicacionCliente.latitude) * p) /
            2 +
        c(_ubicacionCliente.latitude * p) *
            c(_ubicacionRestaurante!.latitude * p) *
            (1 -
                c(
                  (_ubicacionRestaurante!.longitude -
                          _ubicacionCliente.longitude) *
                      p,
                )) /
            2;
    double distanciaKm = 12742 * asin(sqrt(a));

    double costo = 5.00;
    if (distanciaKm > 1.5) costo += (distanciaKm - 1.5) * 2.00;

    setState(() {
      _costoEnvio = double.parse(costo.toStringAsFixed(1));
    });
  }

  void _continuar() {
    if (_direccionCtrl.text.isEmpty || _telCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Dirección y teléfono son obligatorios")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => PagoScreen(
          direccion: _direccionCtrl.text,
          referencia: _refCtrl.text,
          telefono: _telCtrl.text,
          costoEnvio: _costoEnvio,
          lat: _ubicacionCliente.latitude,
          lng: _ubicacionCliente.longitude,
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    IconData icon,
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text,
    bool esOpcional = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: esOpcional ? "$label (Opcional)" : label,
          prefixIcon: Icon(icon, color: Colors.orange),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Ubicación",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.50,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(Colors.orange),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // MAPA GRANDE
                  Container(
                    height: 380,
                    margin: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _ubicacionCliente,
                              initialZoom: 15,
                              onPositionChanged: (p, g) {
                                if (g) {
                                  _ubicacionCliente = p.center!;
                                  _recalcularEnvio();
                                }
                              },
                            ),
                            children: [
                              // REEMPLAZAR EL TILELAYER ACTUAL POR ESTE:
                              TileLayer(
                                // Estilo "Positron" (Gris suave y limpio)
                                urlTemplate:
                                    'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.cerrodelivery.app',
                              ),
                            ],
                          ),
                          Center(
                            child: Icon(
                              Icons.location_on,
                              size: 45,
                              color: Colors.red,
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: FloatingActionButton.extended(
                              backgroundColor: Colors.white,
                              icon: Icon(
                                Icons.my_location,
                                color: Colors.black,
                              ),
                              label: Text(
                                "Detectar mi ubicación",
                                style: TextStyle(color: Colors.black),
                              ),
                              onPressed: _obtenerUbicacionActual,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // FORMULARIO
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          "Detalles de Entrega",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 15),
                        _buildInput(
                          "Dirección Exacta (o Coordenadas)",
                          Icons.home_rounded,
                          _direccionCtrl,
                        ),
                        _buildInput(
                          "Referencia",
                          Icons.map_rounded,
                          _refCtrl,
                          esOpcional: true,
                        ),
                        _buildInput(
                          "Teléfono de Contacto",
                          Icons.phone_android_rounded,
                          _telCtrl,
                          type: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FOOTER
          Container(
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Costo de Envío",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      "S/ ${_costoEnvio.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _continuar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      "Confirmar Ubicación 👉",
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
        ],
      ),
    );
  }
}
