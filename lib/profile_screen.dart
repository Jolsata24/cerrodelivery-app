import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sesion.dart';
import 'main.dart'; // Para redirigir al Login al cerrar sesión

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ⚠️ TU URL DE NGROK
  final String baseUrl = "https://cerrodelivery.com";

  TextEditingController _nombreCtrl = TextEditingController();
  TextEditingController _emailCtrl = TextEditingController();
  TextEditingController _telefonoCtrl = TextEditingController();
  TextEditingController _passCtrl = TextEditingController();

  bool cargando = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    String url =
        "$baseUrl/api/perfil.php?accion=obtener&id_cliente=${Sesion.id}";
    try {
      var res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _nombreCtrl.text = data['data']['nombre'];
              _emailCtrl.text = data['data']['email'];
              _telefonoCtrl.text = data['data']['telefono'];
              cargando = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted)
        setState(() {
          cargando = false;
        });
    }
  }

  Future<void> actualizarPerfil() async {
    if (_nombreCtrl.text.isEmpty || _telefonoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nombre y teléfono son obligatorios")),
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    String url = "$baseUrl/api/perfil.php?accion=actualizar";
    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['id_cliente'] = Sesion.id.toString();
      request.fields['nombre'] = _nombreCtrl.text;
      request.fields['telefono'] = _telefonoCtrl.text;

      if (_passCtrl.text.isNotEmpty) {
        request.fields['password'] = _passCtrl.text;
      }

      var res = await request.send();
      var resBody = await res.stream.bytesToString();
      var data = jsonDecode(resBody);

      if (data['success'] == true) {
        Sesion.nombre = _nombreCtrl.text;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Perfil actualizado"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _passCtrl.clear();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${data['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error de conexión")));
    } finally {
      if (mounted)
        setState(() {
          guardando = false;
        });
    }
  }

  // --- WIDGET HELPER PARA INPUTS ---
  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController ctrl, {
    bool isPassword = false,
    bool isReadOnly = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isReadOnly ? Colors.grey[200] : Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isReadOnly ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword,
        readOnly: isReadOnly,
        style: TextStyle(color: isReadOnly ? Colors.grey[600] : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(
            icon,
            color: isReadOnly ? Colors.grey : Colors.orange,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo limpio
      appBar: AppBar(
        title: Text(
          "Mi Perfil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Porque está en el menú inferior
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: "Cerrar Sesión",
            onPressed: () {
              // Navegar al Login y borrar historial
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (c) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: cargando
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 1. CABECERA CON AVATAR
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: Text(
                                  _nombreCtrl.text.isNotEmpty
                                      ? _nombreCtrl.text[0].toUpperCase()
                                      : "C",
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          _nombreCtrl.text,
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _emailCtrl.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[100],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. FORMULARIO FLOTANTE
                  Transform.translate(
                    offset: Offset(
                      0,
                      -20,
                    ), // Subir un poco para solaparse con el naranja
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Información Personal",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 20),

                          _buildTextField(
                            "Nombre Completo",
                            Icons.person_outline,
                            _nombreCtrl,
                          ),
                          _buildTextField(
                            "Correo Electrónico",
                            Icons.email_outlined,
                            _emailCtrl,
                            isReadOnly: true,
                          ),
                          _buildTextField(
                            "Celular / WhatsApp",
                            Icons.phone_android_rounded,
                            _telefonoCtrl,
                          ),

                          Divider(height: 40),

                          Text(
                            "Seguridad",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Deja este campo vacío si no quieres cambiar tu contraseña.",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(height: 15),

                          _buildTextField(
                            "Nueva Contraseña",
                            Icons.lock_outline,
                            _passCtrl,
                            isPassword: true,
                          ),

                          SizedBox(height: 20),

                          // BOTÓN GUARDAR
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: guardando ? null : actualizarPerfil,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                elevation: 5,
                                shadowColor: Colors.orange.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: guardando
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "GUARDAR CAMBIOS",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
