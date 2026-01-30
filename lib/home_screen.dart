import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'main.dart';
import 'menu_screen.dart';
import 'pedidos_screen.dart';
import 'carrito_screen.dart';
import 'sesion.dart';
import 'profile_screen.dart';

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
      backgroundColor: Colors.grey[50],
      body: _pantallas[_indiceActual],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          color: Colors.white,
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceActual,
          onTap: (index) => setState(() => _indiceActual = index),
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Pedidos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cuenta',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ✨ PANTALLA DE INICIO (Header Fijo + Scroll Abajo) ✨
// ============================================================================
class PantallaInicio extends StatefulWidget {
  final String nombreUsuario;
  PantallaInicio({required this.nombreUsuario});

  @override
  _PantallaInicioState createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final String baseUrl = "https://cerrodelivery.com";

  List<dynamic> restaurantes = [];
  List<dynamic> categorias = [];
  bool cargando = true;
  String direccionActual = "Cargando ubicación...";
  String categoriaSeleccionada = "";
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarDatos();
    _detectarDireccionHeader();
  }

  Future<void> _detectarDireccionHeader() async {
    bool servicio = await Geolocator.isLocationServiceEnabled();
    if (!servicio) {
      if (mounted)
        setState(() => direccionActual = "Cerro de Pasco (GPS Apagado)");
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
        if (marks.isNotEmpty) {
          if (mounted)
            setState(
              () => direccionActual =
                  "${marks[0].thoroughfare} ${marks[0].subThoroughfare}, ${marks[0].subLocality}",
            );
        }
      } catch (e) {
        if (mounted)
          setState(() => direccionActual = "Ubicación actual detectada");
      }
    }
  }

  Future<void> cargarDatos() async {
    await cargarCategorias();
    await cargarRestaurantes();
  }

  Future<void> cargarCategorias() async {
    try {
      var res = await http.get(
        Uri.parse("$baseUrl/api/obtener_categorias.php"),
      );
      if (res.statusCode == 200) {
        if (mounted)
          setState(() {
            categorias = jsonDecode(res.body);
          });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> cargarRestaurantes({
    String query = "",
    String catId = "",
  }) async {
    if (mounted)
      setState(() {
        cargando = true;
      });
    try {
      var res = await http.get(
        Uri.parse("$baseUrl/api/obtener_restaurantes.php?q=$query&cat=$catId"),
      );
      if (res.statusCode == 200) {
        if (mounted)
          setState(() {
            restaurantes = jsonDecode(res.body);
            cargando = false;
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          cargando = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    var populares = restaurantes
        .where((r) => double.parse(r['puntuacion_promedio'].toString()) >= 4.5)
        .toList();

    List<dynamic> categoriasGrandes = categorias.take(2).toList();
    List<dynamic> categoriasPequenas = categorias.skip(2).toList();

    return Column(
      // ⬅️ Usamos Column en lugar de SingleChildScrollView principal
      children: [
        // 1. ZONA FIJA (Header Naranja + Buscador)
        Container(
          height: 190, // Altura fija para el encabezado
          child: Stack(
            children: [
              // Fondo Naranja Curvo
              Container(
                height: 160, // El naranja llega hasta aquí
                padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Entregar en 📍",
                            style: TextStyle(
                              color: Colors.orange[100],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  direccionActual,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (c) => CarritoScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Buscador Flotante (Fijo en la parte baja del Stack)
              Positioned(
                bottom: 0, // Pegado al fondo del contenedor de 190px
                left: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "¿Qué vas a comer hoy?",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.orange),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (texto) => cargarRestaurantes(query: texto),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. ZONA SCROLLEABLE (El resto del contenido)
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: 20, bottom: 20),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARRUSEL DE PROMOCIONES
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        _buildPromoCard(
                          "Envío Gratis",
                          "Primer pedido",
                          Colors.orangeAccent,
                          Icons.motorcycle,
                        ),
                        _buildPromoCard(
                          "2x1 Burgers",
                          "Solo hoy",
                          Colors.redAccent,
                          Icons.lunch_dining,
                        ),
                        _buildPromoCard(
                          "Dscto Pollo",
                          "30% Off",
                          Colors.amber[700]!,
                          Icons.local_fire_department,
                        ),
                      ],
                    ),
                  ),

                  // CATEGORÍAS MIXTAS
                  SizedBox(height: 25),
                  Text(
                    "Explora por Categorías",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 15),

                  categorias.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            if (categoriasGrandes.isNotEmpty)
                              Row(
                                children: categoriasGrandes
                                    .map(
                                      (c) => Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: categoriasGrandes.last == c
                                                ? 0
                                                : 10,
                                          ),
                                          child: _buildBigCategoryCard(c),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),

                            SizedBox(height: 10),

                            if (categoriasPequenas.isNotEmpty)
                              GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      childAspectRatio: 0.8,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                itemCount: categoriasPequenas.length,
                                itemBuilder: (c, i) => _buildSmallCategoryCard(
                                  categoriasPequenas[i],
                                ),
                              ),
                          ],
                        ),

                  // LO MÁS POPULAR
                  if (populares.isNotEmpty) ...[
                    SizedBox(height: 25),
                    Text(
                      "Los Favoritos ⭐",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 15),
                    Container(
                      height: 210,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: populares.length,
                        itemBuilder: (c, i) =>
                            _buildRestauranteHorizontal(populares[i]),
                      ),
                    ),
                  ],

                  // TODOS LOS RESTAURANTES
                  SizedBox(height: 25),
                  Text(
                    "Todos los Restaurantes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 15),
                  cargando
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: restaurantes.length,
                          itemBuilder: (c, i) =>
                              _buildRestauranteVertical(restaurantes[i]),
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildBigCategoryCard(dynamic c) {
    bool esActiva = categoriaSeleccionada == c['id'].toString();
    String imgUrl =
        "$baseUrl/assets/img/categorias/${c['imagen_app'] ?? 'default.png'}";
    return GestureDetector(
      onTap: () => _seleccionarCategoria(c['id'].toString()),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          image: DecorationImage(
            image: NetworkImage(imgUrl),
            fit: BoxFit.cover,
          ),
          border: esActiva ? Border.all(color: Colors.orange, width: 2) : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
          alignment: Alignment.bottomLeft,
          padding: EdgeInsets.all(12),
          child: Text(
            c['nombre_categoria'],
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCategoryCard(dynamic c) {
    bool esActiva = categoriaSeleccionada == c['id'].toString();
    return GestureDetector(
      onTap: () => _seleccionarCategoria(c['id'].toString()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          border: esActiva ? Border.all(color: Colors.orange, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              "$baseUrl/assets/img/categorias/${c['imagen_app'] ?? 'default.png'}",
              height: 40,
              width: 40,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 8),
            Text(
              c['nombre_categoria'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _seleccionarCategoria(String id) {
    setState(
      () => categoriaSeleccionada = categoriaSeleccionada == id ? "" : id,
    );
    cargarRestaurantes(
      query: searchController.text,
      catId: categoriaSeleccionada,
    );
  }

  Widget _buildPromoCard(
    String titulo,
    String subtitulo,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 140,
      height: 80,
      margin: EdgeInsets.only(right: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitulo,
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 30),
        ],
      ),
    );
  }

  Widget _buildRestauranteHorizontal(dynamic r) {
    String imgUrl =
        "$baseUrl/assets/img/restaurantes/${r['imagen_fondo'] ?? 'default.png'}";
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => MenuScreen(
            restaurantId: r['id'].toString(),
            restaurantName: r['nombre_restaurante'],
            restaurantImage: imgUrl,
          ),
        ),
      ),
      child: Container(
        width: 160,
        margin: EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                imgUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Container(height: 110, color: Colors.grey[200]),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['nombre_restaurante'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        r['puntuacion_promedio'],
                        style: TextStyle(
                          fontSize: 12,
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

  Widget _buildRestauranteVertical(dynamic r) {
    String imgUrl =
        "$baseUrl/assets/img/restaurantes/${r['imagen_fondo'] ?? 'default.png'}";
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => MenuScreen(
            restaurantId: r['id'].toString(),
            restaurantName: r['nombre_restaurante'],
            restaurantImage: imgUrl,
          ),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: Image.network(
                imgUrl,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 110,
                  height: 110,
                  color: Colors.grey[200],
                  child: Icon(Icons.store),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['nombre_restaurante'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      r['direccion'] ?? "Cerro de Pasco",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 12, color: Colors.orange),
                              Text(
                                " ${r['puntuacion_promedio']}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        Text(
                          " 20-30 min",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
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
}
