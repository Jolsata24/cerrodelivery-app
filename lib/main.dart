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
        scaffoldBackgroundColor: Colors.white, // Fondo limpio
      ),
      home: LoginScreen(),
    ),
  );
}

// 1. PINTOR DEL PATRÓN (Más sutil y lento)
class FoodPatternPainter extends CustomPainter {
  final double offset;
  FoodPatternPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    // Iconos casi transparentes para no ensuciar
    final paint = Paint()..color = Colors.grey.withOpacity(0.05);

    final icons = [
      Icons.lunch_dining,
      Icons.local_pizza,
      Icons.icecream,
      Icons.set_meal,
      Icons.fastfood,
      Icons.coffee,
      Icons.bakery_dining,
      Icons.ramen_dining,
    ];

    double spacing = 80; // Más espaciado
    int row = 0;

    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      int col = 0;
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        IconData icon = icons[(row + col) % icons.length];

        // Movimiento diagonal muy lento
        double xPos = x + (offset * spacing);
        double yPos = y + (offset * spacing);

        if (xPos > size.width) xPos -= (size.width + spacing);
        if (yPos > size.height) yPos -= (size.height + spacing);

        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: 24, // Más pequeños
              fontFamily: icon.fontFamily,
              color: Colors.orange.withOpacity(0.08), // Color muy muy suave
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

// 2. CLIPPER PARA LA CURVA (La Ola Naranja)
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50); // Empieza abajo a la izquierda

    // Punto de control para la curva (hace la barriga de la ola)
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // Segunda parte de la curva (subida suave)
    var secondControlPoint = Offset(
      size.width - (size.width / 3.25),
      size.height - 80,
    );
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0); // Sube a la derecha
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  String mensaje = "";
  bool cargando = false;
  bool ocultarPassword = true;

  // Controladores de animación
  late AnimationController _bgController; // Para el fondo
  late AnimationController _entryController; // Para la entrada de la tarjeta
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // 1. Animación del fondo (Lenta e infinita)
    _bgController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 30),
    )..repeat();

    // 2. Animación de Entrada (Suave al abrir la app)
    _entryController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200), // Tarda 1.2 segundos en entrar
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1), // Empieza un poco más abajo
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    // Iniciar la entrada
    _entryController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      mensaje = "";
      cargando = true;
    });
    // RECUERDA: CAMBIA LA IP SI ES NECESARIO (usa tu IP local si pruebas en celular real)
    String url =
        "https://cerrodelivery.com/api/login_cliente_api.php"; // URL de ejemplo

    try {
      // Simulación de delay para ver el loader suave
      // await Future.delayed(Duration(seconds: 1));

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
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. FONDO CON PATRÓN SUAVE
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return CustomPaint(
                  painter: FoodPatternPainter(_bgController.value),
                );
              },
            ),
          ),

          // 2. CABECERA CURVA (OLA)
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: size.height * 0.45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF8C00), // Naranja oscuro
                    Color(0xFFFFB74D), // Naranja pastel (más suave)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO CON SOMBRA SUAVE
                    Hero(
                      // Efecto Hero si navegas
                      tag: 'logo',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/img/logo.png',
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 50), // Espacio para la curva
                  ],
                ),
              ),
            ),
          ),

          // 3. FORMULARIO FLOTANTE (Con animación de entrada)
          Align(
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.22), // Ajuste visual
                        // TARJETA PRINCIPAL
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  0.08,
                                ), // Sombra muy difusa
                                blurRadius: 30,
                                offset: Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "¡Hola de nuevo!",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Ingresa tus datos para pedir.",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 30),

                                // INPUT EMAIL
                                _buildSoftInput(
                                  controller: emailController,
                                  label: "Correo electrónico",
                                  icon: Icons.email_rounded,
                                  type: TextInputType.emailAddress,
                                ),
                                SizedBox(height: 20),

                                // INPUT PASSWORD
                                _buildSoftInput(
                                  controller: passController,
                                  label: "Contraseña",
                                  icon: Icons.lock_rounded,
                                  isPassword: true,
                                  isVisible: !ocultarPassword,
                                  onVisibilityToggle: () {
                                    setState(() {
                                      ocultarPassword = !ocultarPassword;
                                    });
                                  },
                                ),
                                SizedBox(height: 30),

                                // BOTÓN INGRESAR (Gradiente suave)
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange,
                                          Colors.orangeAccent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: cargando ? null : login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      child: cargando
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              "INGRESAR",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),

                                if (mensaje.isNotEmpty) ...[
                                  SizedBox(height: 20),
                                  Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        mensaje,
                                        style: TextStyle(
                                          color: Colors.red[400],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 30),

                        // TEXTO REGISTRO
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "¿No tienes cuenta?",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                "Regístrate aquí",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para inputs más limpios
  Widget _buildSoftInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    TextInputType type = TextInputType.text,
    VoidCallback? onVisibilityToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.orange[300]),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[400],
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        ),
      ),
    );
  }
}
