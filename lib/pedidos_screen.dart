import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'sesion.dart';
import 'tracking_screen.dart';

class PedidosScreen extends StatefulWidget {
  @override
  _PedidosScreenState createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  // 1. URL BASE CORRECTA (Asegúrate que coincida con tu estructura)
  final String baseUrl = "https://cerrodelivery.com";

  List<dynamic> pedidos = [];
  bool cargando = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    cargarPedidos();
    // Polling cada 10 segundos
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      cargarPedidos(silencioso: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> cargarPedidos({bool silencioso = false}) async {
    // 2. USAMOS EL ARCHIVO QUE SABEMOS QUE FUNCIONA (pedidos_ok.php)
    // Y volvemos a usar el ID real de la sesión
    // Apunta al archivo correcto (pedidos.php o pedidos_ok.php, el que hayas guardado)
    String archivoApi = "/api/pedidos_ok.php";

    // Vuelve a usar Sesion.id para ver TUS pedidos reales
    String params = "?accion=listar&id_cliente=${Sesion.id}";

    String url = "$baseUrl$archivoApi$params";

    print("🚀 CONSULTANDO: $url");

    try {
      var res = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64)", // Disfraz anti-bloqueo
        },
      );

      if (res.statusCode == 200) {
        String bodyLimpio = res.body.trim();
        print("📦 RESPUESTA SERVER: $bodyLimpio"); // Debug

        // 3. PROTECCIÓN CONTRA RESPUESTAS VACÍAS O HTML DE ERROR
        if (bodyLimpio.isEmpty || bodyLimpio.startsWith("<")) {
          print("⚠️ Error: El servidor devolvió HTML o vacío.");
          return;
        }

        try {
          // Decodificamos
          var data = jsonDecode(bodyLimpio);

          if (mounted) {
            setState(() {
              // 4. ASEGURAR QUE SEA UNA LISTA
              if (data is List) {
                pedidos = data;
              } else {
                print("⚠️ La respuesta no es una lista: $data");
                pedidos = [];
              }
              if (!silencioso) cargando = false;
            });
          }
        } catch (e) {
          print("❌ Error al leer JSON: $e");
        }
      } else {
        print("❌ ERROR HTTP: ${res.statusCode}");
        if (mounted && !silencioso) setState(() => cargando = false);
      }
    } catch (e) {
      print("💥 ERROR DE CONEXIÓN: $e");
      if (mounted && !silencioso) {
        setState(() => cargando = false);
      }
    }
  }

  // ... (RESTO DE TUS FUNCIONES: _acelerarPedido, build, etc. IGUAL QUE ANTES) ...
  // COPIA AQUÍ TUS FUNCIONES _acelerarPedido, _mostrarDialogoCalificar, build, etc.
  // SON LAS MISMAS QUE YA TIENES.

  // --- ABRIR WHATSAPP ---
  Future<void> _acelerarPedido(
    String telefonoRestaurante,
    String nombreRestaurante,
    String idPedido,
  ) async {
    if (telefonoRestaurante == "null" || telefonoRestaurante.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("El restaurante no tiene WhatsApp registrado")),
      );
      return;
    }

    String mensaje =
        "Hola *$nombreRestaurante*, hice un pedido en la App de CerroDelivery (Pedido #$idPedido) y quisiera consultar su estado. 🛵💨";
    final Uri url = Uri.parse(
      "https://wa.me/51$telefonoRestaurante?text=${Uri.encodeComponent(mensaje)}",
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No se pudo abrir WhatsApp")));
    }
  }

  void _mostrarDialogoCalificar(int idRestaurante, String nombreRest) {
    // Pega aquí tu lógica de calificación
  }

  Color getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange.shade300;
      case 'confirmado':
        return Colors.teal;
      case 'preparando':
        return Colors.orange.shade800;
      case 'en camino':
        return Colors.blue;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getTextoEstado(String estado) {
    if (estado.isEmpty) return "";
    return estado[0].toUpperCase() + estado.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Mis Pedidos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => cargarPedidos(),
          ),
        ],
      ),
      body: cargando
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : pedidos.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(15),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                return _buildPedidoCard(pedidos[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long, size: 60, color: Colors.orange),
          ),
          SizedBox(height: 20),
          Text(
            "Sin historial de pedidos",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoCard(dynamic p) {
    String estado = p['estado_pedido'].toString().toLowerCase();
    bool mostrarBotonAcelerar = [
      'pendiente',
      'confirmado',
      'preparando',
    ].contains(estado);
    bool mostrarBotonRastrear = estado == 'en camino';
    bool mostrarBotonCalificar = estado == 'entregado';
    String telefonoRest = p['telefono_restaurante'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      "$baseUrl/assets/img/restaurantes/${p['imagen_fondo'] ?? 'default.png'}",
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 55,
                        height: 55,
                        color: Colors.orange[50],
                        child: Icon(Icons.store, color: Colors.orange),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['nombre_restaurante'] ?? "Restaurante",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        p['fecha_pedido'],
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: getColorEstado(p['estado_pedido']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getTextoEstado(p['estado_pedido']),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Divider(height: 1),
          ),
          Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "#${p['id']}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "S/ ${p['monto_total']}",
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          if (mostrarBotonAcelerar ||
              mostrarBotonRastrear ||
              mostrarBotonCalificar)
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  if (mostrarBotonAcelerar)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.chat_bubble_outline, size: 18),
                        label: Text("ACELERAR"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _acelerarPedido(
                          telefonoRest,
                          p['nombre_restaurante'],
                          p['id'].toString(),
                        ),
                      ),
                    ),
                  if (mostrarBotonRastrear)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.map, size: 18),
                        label: Text("RASTREAR"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) =>
                                  TrackingScreen(pedidoId: p['id'].toString()),
                            ),
                          );
                        },
                      ),
                    ),
                  if (mostrarBotonCalificar)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.star, size: 18),
                        label: Text("CALIFICAR"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange[900],
                          side: BorderSide(color: Colors.orange),
                        ),
                        onPressed: () => _mostrarDialogoCalificar(
                          int.parse(p['restaurante_id'].toString()),
                          p['nombre_restaurante'],
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
