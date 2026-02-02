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
  final String baseUrl = "https://cerrodelivery.com";

  List<dynamic> pedidos = [];
  bool cargando = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    cargarPedidos();
    // Actualización automática cada 10 segundos
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
    // 1. TRUCO ANTI-CACHE: Agregamos la hora actual para que la URL sea siempre distinta
    // y el celular se vea obligado a descargar los datos nuevos.
    String cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();

    // Asegúrate de usar el archivo que SÍ funciona (pedidos.php o pedidos_ok.php)
    String archivoApi = "/api/pedidos.php";

    // Usamos tu ID de sesión real
    String params = "?accion=listar&id_cliente=${Sesion.id}&v=$cacheBuster";

    String url = "$baseUrl$archivoApi$params";

    if (!silencioso) print("🚀 ACTUALIZANDO PEDIDOS...");

    try {
      var res = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        },
      );

      if (res.statusCode == 200) {
        String bodyLimpio = res.body.trim();

        // Validación de seguridad
        if (bodyLimpio.isEmpty || bodyLimpio.startsWith("<")) {
          // Si el servidor falla silenciosamente, no hacemos nada para no molestar al usuario
          return;
        }

        try {
          var data = jsonDecode(bodyLimpio);

          if (mounted) {
            setState(() {
              if (data is List) {
                pedidos = data;
              } else {
                pedidos = [];
              }
              if (!silencioso) cargando = false;
            });
          }
        } catch (e) {
          print("❌ Error JSON: $e");
        }
      }
    } catch (e) {
      print("💥 Error Conexión: $e");
    }
  }

  // ... (Tus funciones auxiliares siguen igual) ...
  Future<void> _acelerarPedido(
    String telefonoRest,
    String nombreRest,
    String idPedido,
  ) async {
    if (telefonoRest == "null" || telefonoRest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("El restaurante no tiene WhatsApp")),
      );
      return;
    }
    String mensaje =
        "Hola *$nombreRest*, consulta sobre mi pedido #$idPedido 🛵";
    final Uri url = Uri.parse(
      "https://wa.me/51$telefonoRest?text=${Uri.encodeComponent(mensaje)}",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No se pudo abrir WhatsApp")));
    }
  }

  void _mostrarDialogoCalificar(int idRestaurante, String nombreRest) {
    // Tu lógica de calificar aquí...
  }

  Color getColorEstado(String estado) {
    // Limpiamos espacios por si acaso
    switch (estado.trim().toLowerCase()) {
      case 'pendiente':
        return Colors.orange.shade300;
      case 'confirmado':
        return Colors.teal;
      case 'preparando':
        return Colors.orange.shade800;
      case 'en camino':
        return Colors.blue; // <--- AQUÍ DEBE COINCIDIR
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
      child: Text(
        "Sin historial de pedidos",
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildPedidoCard(dynamic p) {
    // 2. LIMPIEZA CRÍTICA: Quitamos espacios y pasamos a minúsculas
    String estadoRaw = p['estado_pedido'].toString(); // Texto original
    String estado = estadoRaw.trim().toLowerCase(); // Texto limpio

    // DEBUG: Ver qué estado llega realmente
    print(
      "🔍 Pedido #${p['id']} - Estado Original: '$estadoRaw' -> Limpio: '$estado'",
    );

    // 3. LÓGICA DE BOTONES
    bool mostrarBotonAcelerar = [
      'pendiente',
      'confirmado',
      'preparando',
    ].contains(estado);

    // OJO: El texto aquí debe ser idéntico al de tu base de datos (en minúsculas)
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
          // CABECERA
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
                      errorBuilder: (c, e, s) =>
                          Icon(Icons.store, color: Colors.orange, size: 40),
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
                    color: getColorEstado(estado),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getTextoEstado(estado),
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
          Divider(height: 1),
          // PRECIO
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
          // BOTONES DE ACCIÓN
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

                  // AQUÍ ESTÁ EL BOTÓN DE RASTREAR
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
