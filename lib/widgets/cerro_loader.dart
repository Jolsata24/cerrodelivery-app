import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // Librería de animaciones fáciles

class CerroLoader extends StatelessWidget {
  final String texto;

  CerroLoader({this.texto = "Cargando..."});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Fondo blanco limpio
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ANIMACIÓN "PULSE" (Latido)
          Pulse(
            infinite: true, // Que nunca pare
            duration: Duration(milliseconds: 1500),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(0.1),
              ),
              padding: EdgeInsets.all(20),
              // Aquí iría tu logo o una imagen de hamburguesa
              // Usamos un Icono grande por ahora
              child: Icon(Icons.lunch_dining, size: 60, color: Colors.orange),
            ),
          ),
          SizedBox(height: 30),

          // Texto animado que aparece
          FadeInUp(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: 20),

          // Una barrita de carga muy finita y elegante
          SizedBox(
            width: 150,
            child: LinearProgressIndicator(
              backgroundColor: Colors.orange[50],
              valueColor: AlwaysStoppedAnimation(Colors.orange),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }
}
