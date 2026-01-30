import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'carrito_model.dart';
import 'carrito_screen.dart';

class MenuScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String restaurantImage;

  MenuScreen({
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImage,
  });

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // ⚠️ TU URL DE NGROK
  final String baseUrl = "https://cerrodelivery.com";

  List<dynamic> platos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarMenu();
  }

  Future<void> cargarMenu() async {
    String url =
        "$baseUrl/api/obtener_menu.php?id_restaurante=${widget.restaurantId}";
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            platos = jsonDecode(response.body);
            cargando = false;
          });
        }
      }
    } catch (e) {
      if (mounted)
        setState(() {
          cargando = false;
        });
    }
  }

  void agregarAlCarrito(dynamic plato) {
    double precio = double.tryParse(plato['precio'].toString()) ?? 0.0;
    ProductoCarrito nuevoItem = ProductoCarrito(
      id: int.parse(plato['id'].toString()),
      nombre: plato['nombre_plato'],
      precio: precio,
      cantidad: 1,
      idRestaurante: int.parse(widget.restaurantId),
    );

    Carrito.agregar(nuevoItem);

    // Feedback visual elegante
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "${plato['nombre_plato']} agregado",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.orange, // 🧡 Branding
        behavior: SnackBarBehavior.floating, // Flota sobre el contenido
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo limpio
      body: CustomScrollView(
        slivers: [
          // 1. CABECERA CON IMAGEN Y DEGRADADO
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.orange,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true, // Título centrado se ve mejor
              title: Text(
                widget.restaurantName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.restaurantImage,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.orange),
                  ),
                  // Degradado para que se lea el texto y los iconos
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black45,
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => CarritoScreen()),
                  ),
                ),
              ),
            ],
          ),

          // 2. TÍTULO DE LA SECCIÓN
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.orange, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Menú / Carta",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. LISTA DE PLATOS ESTILIZADA
          cargando
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  ),
                )
              : platos.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildPlatoCard(platos[index]);
                  }, childCount: platos.length),
                ),

          // Espacio extra al final para que el último plato no quede pegado al borde
          SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_meals, size: 60, color: Colors.grey[300]),
          SizedBox(height: 10),
          Text(
            "No hay platos disponibles",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatoCard(dynamic plato) {
    String imgUrl = "$baseUrl/assets/img/platos/${plato['foto_url']}";

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FOTO DEL PLATO (Cuadrada y con bordes redondos)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imgUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.orange[50],
                    child: Icon(Icons.fastfood, color: Colors.orange[200]),
                  ),
                ),
              ),
              SizedBox(width: 15),

              // DETALLES
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Centrado verticalmente
                  children: [
                    SizedBox(height: 5),
                    Text(
                      plato['nombre_plato'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Text(
                      plato['descripcion'] ??
                          'Delicioso plato preparado al instante.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // PRECIO DESTACADO
                        Text(
                          "S/ ${plato['precio']}",
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),

                        // BOTÓN AGREGAR (Círculo Naranja)
                        InkWell(
                          onTap: () => agregarAlCarrito(plato),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
