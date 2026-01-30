import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'sesion.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CerroDelivery',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color.fromARGB(
          255,
          26,
          41,
          53,
        ), // Fondo general blanco
      ),
      home: LoginScreen(),
    ),
  );
}

// PINTOR DEL PATRÓN (Ajustado para verse bien sobre blanco)
class FoodPatternPainter extends CustomPainter {
  final double offset;
  FoodPatternPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    // Iconos en gris muy suave para no distraer
    final paint = Paint()..color = Colors.grey.withOpacity(0.1);

    final icons = [
      Icons.lunch_dining,
      Icons.local_pizza,
      Icons.icecream,
      Icons.set_meal,
      Icons.fastfood,
      Icons.coffee,
      Icons.bakery_dining,
      Icons.ramen_dining, // Agregué más variedad
    ];

    double spacing = 70; // Más espacio para que se vea más limpio
    int row = 0;

    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      int col = 0;
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        IconData icon = icons[(row + col) % icons.length];

        // Movimiento diagonal suave
        double xPos = x + (offset * spacing);
        double yPos = y + (offset * spacing);

        if (xPos > size.width) xPos -= (size.width + spacing);
        if (yPos > size.height) yPos -= (size.height + spacing);

        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: 28,
              fontFamily: icon.fontFamily,
              color: Colors.orangeAccent.withOpacity(0.30), // Color gris claro
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(xPos, yPos));
        col++;
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant FoodPatternPainter oldDelegate) =>
      oldDelegate.offset != offset;
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  String mensaje = "";
  bool cargando = false;
  bool ocultarPassword = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      mensaje = "";
      cargando = true;
    });
    // RECUERDA: CAMBIA LA IP SI ES NECESARIO
    String url =
        "https://unclinical-ungeometrically-elenor.ngrok-free.dev/cerrodeliveryv2/api/login_cliente_api.php";

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim(),
          "password": passController.text.trim(),
        }),
      );
      var data = jsonDecode(response.body);

      if (data['success'] == true) {
        Sesion.id = data['user_data']['id'].toString();
        Sesion.nombre = data['user_data']['nombre'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomeScreen(nombreUsuario: data['user_data']['nombre']),
          ),
        );
      } else {
        setState(() {
          mensaje = "❌ ${data['message']}";
        });
      }
    } catch (e) {
      setState(() {
        mensaje = "⚠️ Error de conexión";
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Quitamos el botón flotante que sobraba
      body: Stack(
        children: [
          // 1. FONDO BLANCO CON PATRÓN (Ocupa toda la pantalla)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: FoodPatternPainter(_controller.value),
                );
              },
            ),
          ),

          // 2. CABECERA NARANJA (Ocupa el 45% superior)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF8C00),
                    Color(0xFFFF5722),
                  ], // Naranja vibrante
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO SIN CÍRCULO BLANCO
                  // Al estar sobre naranja, las letras blancas se verán perfectas
                  Image.asset(
                    'assets/img/logo.png',
                    height: 100, // Ajusta tamaño si es necesario
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 10),
                  // Texto opcional si el logo no tiene nombre
                  // Text("CerroDelivery", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 30,
                  ), // Espacio extra para que no choque con la tarjeta
                ],
              ),
            ),
          ),

          // 3. TARJETA DE LOGIN (Flotando en el centro)
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    SizedBox(
                      height: size.height * 0.25,
                    ), // Empujamos hacia abajo para centrar con el borde
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 30,
                          horizontal: 20,
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Bienvenido (Version Final)",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Inicia sesión para continuar",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 30),

                            // INPUT EMAIL
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Correo",
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.orange,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            SizedBox(height: 20),

                            // INPUT PASSWORD
                            TextField(
                              controller: passController,
                              obscureText: ocultarPassword,
                              decoration: InputDecoration(
                                labelText: "Contraseña",
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Colors.orange,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    ocultarPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(
                                    () => ocultarPassword = !ocultarPassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            SizedBox(height: 30),

                            // BOTÓN INGRESAR
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: cargando ? null : login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 2,
                                ),
                                child: cargando
                                    ? CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        "INGRESAR",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            if (mensaje.isNotEmpty) ...[
                              SizedBox(height: 15),
                              Text(
                                mensaje,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // TEXTO REGISTRO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "¿Nuevo en CerroDelivery?",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () {}, // Pendiente: Navegar a registro
                          child: Text(
                            "Crea tu cuenta",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
