import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'menu_screen.dart';
import 'pedidos_screen.dart';
import 'carrito_screen.dart';
import 'profile_screen.dart';
import 'sesion.dart';

// ============================================================================
// 🏠 HOME SCREEN (Contenedor Principal)
// ============================================================================
class HomeScreen extends StatefulWidget {
  final String nombreUsuario;
  HomeScreen({required this.nombreUsuario});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceActual = 0;
  late List<Widget> _pantallas;

  @override
  void initState() {
    super.initState();
    _pantallas = [
      PantallaInicio(nombreUsuario: widget.nombreUsuario),
      PedidosScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _indiceActual, children: _pantallas),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceActual,
          onTap: (index) => setState(() => _indiceActual = index),
          selectedItemColor: Colors.deepOrange,
          unselectedItemColor: Colors.grey[400],
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Pedidos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Cuenta',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Icon(Icons.shopping_bag_outlined, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => CarritoScreen()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ============================================================================
// ✨ PANTALLA DE INICIO
// ============================================================================
class PantallaInicio extends StatefulWidget {
  final String nombreUsuario;
  PantallaInicio({required this.nombreUsuario});

  @override
  _PantallaInicioState createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio>
    with TickerProviderStateMixin {
  final String baseUrl = "https://cerrodelivery.com";

  List<dynamic> restaurantes = [];
  List<dynamic> categorias = [];
  bool cargando = true;
  String direccionActual = "Detectando ubicación...";
  String categoriaSeleccionada = "";
  TextEditingController searchController = TextEditingController();

  late AnimationController _listController;

  // DICCIONARIO DE ICONOS 3D
  final Map<String, String> iconos3D = {
    'hamburguesa': 'https://cdn-icons-png.flaticon.com/512/2983/2983067.png',
    'pollo': 'https://cdn-icons-png.flaticon.com/512/6679/6679109.png',
    'broaster': 'https://cdn-icons-png.flaticon.com/512/10574/10574768.png',
    'chaufa': 'https://cdn-icons-png.flaticon.com/512/590/590797.png',
    'marisco': 'https://cdn-icons-png.flaticon.com/512/3081/3081840.png',
    'parrilla': 'https://cdn-icons-png.flaticon.com/512/1134/1134447.png',
    'salchipapa': 'https://cdn-icons-png.flaticon.com/512/1046/1046784.png',
    'bebida': 'https://cdn-icons-png.flaticon.com/512/2405/2405479.png',
    'postre': 'https://cdn-icons-png.flaticon.com/512/3081/3081967.png',
    'default': 'https://cdn-icons-png.flaticon.com/512/737/737967.png',
  };

  String _getIconoUrl(String nombreCategoria) {
    String nombre = nombreCategoria.toLowerCase();
    for (var key in iconos3D.keys) {
      if (nombre.contains(key)) return iconos3D[key]!;
    }
    return iconos3D['default']!;
  }

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    cargarDatos();
    _detectarDireccion();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _detectarDireccion() async {
    bool servicio = await Geolocator.isLocationServiceEnabled();
    if (!servicio) {
      if (mounted) setState(() => direccionActual = "Pasco (Activa tu GPS)");
      return;
    }
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied)
      permiso = await Geolocator.requestPermission();

    if (permiso == LocationPermission.whileInUse ||
        permiso == LocationPermission.always) {
      Position pos = await Geolocator.getCurrentPosition();
      try {
        List<Placemark> marks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (marks.isNotEmpty && mounted) {
          setState(
            () => direccionActual =
                "${marks[0].thoroughfare} ${marks[0].subThoroughfare}",
          );
        }
      } catch (e) {
        if (mounted) setState(() => direccionActual = "Ubicación actual");
      }
    }
  }

  Future<void> cargarDatos() async {
    await Future.wait([cargarCategorias(), cargarRestaurantes()]);
  }

  Future<void> cargarCategorias() async {
    try {
      var res = await http.get(
        Uri.parse("$baseUrl/api/obtener_categorias.php"),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() => categorias = jsonDecode(res.body));
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> cargarRestaurantes({
    String query = "",
    String catId = "",
  }) async {
    if (mounted) setState(() => cargando = true);
    try {
      var res = await http.get(
        Uri.parse("$baseUrl/api/obtener_restaurantes.php?q=$query&cat=$catId"),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          restaurantes = jsonDecode(res.body);
          cargando = false;
        });
        _listController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var populares = restaurantes.where((r) {
      var punt = double.tryParse(r['puntuacion_promedio'].toString()) ?? 0.0;
      return punt >= 4.5;
    }).toList();

    return Column(
      children: [
        _buildColorfulHeader(),
        Expanded(
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (categorias.isNotEmpty) ...[
                    _buildSectionTitle("Categorías"),
                    SizedBox(height: 15),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: categorias
                            .map((c) => _buildCategoryChip(c))
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 30),
                  ],

                  if (populares.isNotEmpty) ...[
                    _buildSectionTitle("Los Favoritos ⭐"),
                    SizedBox(height: 15),
                    Container(
                      height:
                          250, // Aumentamos altura para que quepan los badges
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: populares.length,
                        itemBuilder: (c, i) => _buildPopularCard(populares[i]),
                      ),
                    ),
                    SizedBox(height: 30),
                  ],

                  _buildSectionTitle("Restaurantes"),
                  SizedBox(height: 15),

                  cargando
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: Colors.deepOrange,
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: restaurantes.length,
                          itemBuilder: (context, index) {
                            final Animation<double> animation =
                                Tween<double>(begin: 0.0, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: _listController,
                                    curve: Interval(
                                      (1 / restaurantes.length) * index,
                                      1.0,
                                      curve: Curves.easeOutQuart,
                                    ),
                                  ),
                                );
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, 30 * (1 - animation.value)),
                                child: Opacity(
                                  opacity: animation.value,
                                  child: child,
                                ),
                              ),
                              child: _buildRestaurantCard(restaurantes[index]),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGETS DE DISEÑO ---

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.deepOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildColorfulHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(25, 50, 25, 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF5722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Entregar en 📍",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      direccionActual,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.deepOrange),
                ),
              ),
            ],
          ),
          SizedBox(height: 25),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: (val) =>
                  cargarRestaurantes(query: val, catId: categoriaSeleccionada),
              style: TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: "¿Qué se te antoja hoy?",
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.deepOrange),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(dynamic cat) {
    bool isSelected = categoriaSeleccionada == cat['id'].toString();
    String imgUrl = _getIconoUrl(cat['nombre_categoria']);

    return GestureDetector(
      onTap: () => _seleccionarCategoria(cat['id'].toString()),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(right: 15),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.deepOrange.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Image.network(imgUrl, height: 24, width: 24),
            SizedBox(width: 8),
            Text(
              cat['nombre_categoria'],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TARJETA POPULAR (Horizontal) - Ahora con Tiempo y Estrellas
  Widget _buildPopularCard(dynamic rest) {
    return GestureDetector(
      onTap: () => _irAlMenu(rest),
      child: Container(
        width: 200, // Un poco más ancha
        margin: EdgeInsets.only(right: 15, bottom: 10, top: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    "$baseUrl/assets/img/restaurantes/${rest['imagen_fondo'] ?? 'default.png'}",
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 120,
                      color: Colors.orange[50],
                      child: Icon(Icons.store, color: Colors.orange),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(blurRadius: 5, color: Colors.black12),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text(
                          rest['puntuacion_promedio'] ?? "4.5",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rest['nombre_restaurante'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),

                  // NUEVO: FILA DE DATOS (Tiempo y Envío)
                  Row(
                    children: [
                      // Badge Tiempo
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.blue[800],
                            ),
                            SizedBox(width: 4),
                            Text(
                              rest['tiempo_entrega'] ?? "30-45 min",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      // Texto Envío Gratis
                      Text(
                        "Envío gratis",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
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
    );
  }

  // TARJETA VERTICAL - Ahora con Tiempo y Estrellas grandes
  Widget _buildRestaurantCard(dynamic rest) {
    bool abierto = rest['estado'] == 'activo'; // Usamos 'activo' según tu BD
    return GestureDetector(
      onTap: () => abierto ? _irAlMenu(rest) : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
              child: Image.network(
                "$baseUrl/assets/img/restaurantes/${rest['imagen_fondo'] ?? 'default.png'}",
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Container(width: 110, height: 110, color: Colors.grey[200]),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            rest['nombre_restaurante'],
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        if (!abierto)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              "Cerrado",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      rest['direccion'] ?? "Pasco, Perú",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                    ),
                    SizedBox(height: 8),

                    // --- NUEVA FILA DE INFO (Badge Time + Badge Star) ---
                    Row(
                      children: [
                        // 1. TIEMPO
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.grey[700],
                              ),
                              SizedBox(width: 4),
                              Text(
                                rest['tiempo_entrega'] ?? "20-30 min",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        // 2. ESTRELLAS
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Colors.amber[800],
                              ),
                              SizedBox(width: 3),
                              Text(
                                rest['puntuacion_promedio'] ?? "4.5",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.amber[900],
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
      ),
    );
  }

  void _seleccionarCategoria(String id) {
    setState(
      () => categoriaSeleccionada = (categoriaSeleccionada == id) ? "" : id,
    );
    cargarRestaurantes(
      query: searchController.text,
      catId: categoriaSeleccionada,
    );
  }

  void _irAlMenu(dynamic rest) {
    String imgUrl =
        "$baseUrl/assets/img/restaurantes/${rest['imagen_fondo'] ?? 'default.png'}";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => MenuScreen(
          restaurantId: rest['id'].toString(),
          restaurantName: rest['nombre_restaurante'],
          restaurantImage: imgUrl,
        ),
      ),
    );
  }
}
