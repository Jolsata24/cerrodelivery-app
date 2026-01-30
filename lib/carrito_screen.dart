import 'package:flutter/material.dart';
import 'carrito_model.dart';
import 'ubicacion_screen.dart';

class CarritoScreen extends StatefulWidget {
  @override
  _CarritoScreenState createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  void _modificarCantidad(int index, int delta) {
    setState(() {
      var item = Carrito.items[index];
      int nuevaCantidad = item.cantidad + delta;
      if (nuevaCantidad >= 1) {
        Carrito.items[index] = ProductoCarrito(
          id: item.id,
          nombre: item.nombre,
          precio: item.precio,
          cantidad: nuevaCantidad,
          idRestaurante: item.idRestaurante,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = Carrito.obtenerTotal();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo muy suave
      appBar: AppBar(
        title: Text(
          "Mi Carrito",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.25,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(Colors.orange),
          ),
        ),
      ),
      body: Carrito.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 100,
                    color: Colors.orange[200],
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Tu carrito está vacío 😔",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.all(20),
                    itemCount: Carrito.items.length,
                    separatorBuilder: (c, i) => SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      var item = Carrito.items[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(15),
                        child: Row(
                          children: [
                            // Botones Cantidad (Diseño Vertical)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () => _modificarCantidad(index, 1),
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${item.cantidad}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: item.cantidad > 1
                                        ? () => _modificarCantidad(index, -1)
                                        : null,
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.remove,
                                        size: 16,
                                        color: item.cantidad > 1
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 20),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "S/ ${(item.precio * item.cantidad).toStringAsFixed(2)}",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Borrar
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[300],
                              ),
                              onPressed: () =>
                                  setState(() => Carrito.items.removeAt(index)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Footer Elegante
                Container(
                  padding: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Subtotal",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "S/ ${subtotal.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => UbicacionScreen(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            "Siguiente: Ubicación 👉",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
