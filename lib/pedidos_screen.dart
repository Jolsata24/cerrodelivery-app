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

class _PedidosScreenState extends State<PedidosScreen>
    with TickerProviderStateMixin {
  final String baseUrl =
      "https://cerrodelivery.com"; // ⚠️ Verifica si usas IP local

  List<dynamic> pedidos = [];
  bool cargando = true;
  Timer? _timer;

  // Controlador de Animación (Agregado para el efecto suave)
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();

    // 1. INICIALIZAMOS EL CONTROLADOR PRIMERO PARA EVITAR EL ERROR ROJO
    _listController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    cargarPedidos();

    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) cargarPedidos(silencioso: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _listController.dispose(); // Limpiamos memoria
    super.dispose();
  }

  Future<void> cargarPedidos({bool silencioso = false}) async {
    String cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
    String archivoApi = "/api/pedidos.php";
    String params = "?accion=listar&id_cliente=${Sesion.id}&v=$cacheBuster";
    String url = "$baseUrl$archivoApi$params";

    if (!silencioso) print("🚀 ACTUALIZANDO PEDIDOS...");

    try {
      var res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        String bodyLimpio = res.body.trim();
        // Validación extra de seguridad
        if (bodyLimpio.isEmpty || bodyLimpio.startsWith("<")) {
          print("⚠️ Respuesta inválida del servidor: $bodyLimpio");
          return;
        }

        try {
          var data = jsonDecode(bodyLimpio);
          if (mounted) {
            setState(() {
              if (data is List) {
                pedidos = data;
                // Reiniciar animación si hay nuevos datos
                _listController.forward(from: 0);
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

  // --- COLORES SUAVES (SOFT UI) ---
  Color getColorFondoEstado(String estado) {
    switch (estado.trim().toLowerCase()) {
      case 'pendiente':
        return Colors.orange[50]!;
      case 'confirmado':
        return Colors.teal[50]!;
      case 'preparando':
        return Colors.amber[50]!;
      case 'en camino':
        return Colors.blue[50]!;
      case 'entregado':
        return Colors.green[50]!;
      case 'cancelado':
        return Colors.red[50]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color getColorTextoEstado(String estado) {
    switch (estado.trim().toLowerCase()) {
      case 'pendiente':
        return Colors.orange[800]!;
      case 'confirmado':
        return Colors.teal[800]!;
      case 'preparando':
        return Colors.amber[900]!;
      case 'en camino':
        return Colors.blue[800]!;
      case 'entregado':
        return Colors.green[800]!;
      case 'cancelado':
        return Colors.red[800]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData getIconoEstado(String estado) {
    switch (estado.trim().toLowerCase()) {
      case 'pendiente':
        return Icons.access_time_rounded;
      case 'confirmado':
        return Icons.check_circle_outline;
      case 'preparando':
        return Icons.restaurant_menu;
      case 'en camino':
        return Icons.delivery_dining;
      case 'entregado':
        return Icons.task_alt;
      case 'cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Función de calificar pronto...")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo limpio
      appBar: AppBar(
        title: Text(
          "Mis Pedidos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // Degradado Naranja (Marca)
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF8C00), Color(0xFFFF5722)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => cargarPedidos(),
          ),
        ],
      ),
      body: cargando
          ? Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : pedidos.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                // ANIMACIÓN DE ENTRADA (Slide Up)
                final Animation<double> animation =
                    Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _listController,
                        curve: Interval(
                          (1 / pedidos.length) * index,
                          1.0,
                          curve: Curves.easeOutQuart,
                        ),
                      ),
                    );
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, 50 * (1 - animation.value)),
                    child: Opacity(opacity: animation.value, child: child),
                  ),
                  child: _buildPedidoCard(pedidos[index]),
                );
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
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 60,
              color: Colors.orange[200],
            ),
          ),
          SizedBox(height: 20),
          Text(
            "No tienes pedidos activos",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoCard(dynamic p) {
    String estadoRaw = p['estado_pedido'].toString();
    String estado = estadoRaw.trim().toLowerCase();

    bool mostrarBotonAcelerar = [
      'pendiente',
      'confirmado',
      'preparando',
    ].contains(estado);
    bool mostrarBotonRastrear = estado == 'en camino';
    bool mostrarBotonCalificar = estado == 'entregado';
    String telefonoRest = p['telefono_restaurante'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        // Sombra difusa suave
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          // 1. INFO PRINCIPAL
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen Restaurante
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    "$baseUrl/assets/img/restaurantes/${p['imagen_fondo'] ?? 'default.png'}",
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[100],
                      child: Icon(Icons.store, color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(width: 15),

                // Detalles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['nombre_restaurante'] ?? "Restaurante",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        p['fecha_pedido'],
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      SizedBox(height: 10),

                      // Badge de Estado (Pastel)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: getColorFondoEstado(estado),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              getIconoEstado(estado),
                              size: 14,
                              color: getColorTextoEstado(estado),
                            ),
                            SizedBox(width: 6),
                            Text(
                              estado.toUpperCase(),
                              style: TextStyle(
                                color: getColorTextoEstado(estado),
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Precio
                Text(
                  "S/ ${p['monto_total']}",
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          // 2. BOTONES DE ACCIÓN (Si corresponden)
          if (mostrarBotonAcelerar ||
              mostrarBotonRastrear ||
              mostrarBotonCalificar)
            Column(
              children: [
                Divider(height: 1, color: Colors.grey[100]),
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Row(
                    children: [
                      if (mostrarBotonAcelerar)
                        Expanded(
                          child: _botonAccion(
                            "Consulta",
                            Icons.chat_bubble_rounded,
                            Colors.green, // Icono genérico para evitar error
                            () => _acelerarPedido(
                              telefonoRest,
                              p['nombre_restaurante'],
                              p['id'].toString(),
                            ),
                          ),
                        ),

                      if (mostrarBotonRastrear)
                        Expanded(
                          child: _botonAccion(
                            "Rastrear",
                            Icons.location_on_rounded,
                            Colors.blue,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => TrackingScreen(
                                  pedidoId: p['id'].toString(),
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (mostrarBotonCalificar)
                        Expanded(
                          child: _botonAccion(
                            "Calificar",
                            Icons.star_rounded,
                            Colors.amber[700]!,
                            () => _mostrarDialogoCalificar(
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
        ],
      ),
    );
  }

  Widget _botonAccion(
    String texto,
    IconData icono,
    Color color,
    VoidCallback accion,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: accion,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 18),
            SizedBox(width: 8),
            Text(texto, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
