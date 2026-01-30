// lib/carrito_model.dart

class ProductoCarrito {
  final int id;
  final String nombre;
  final double precio;
  final int cantidad;
  final int idRestaurante;

  ProductoCarrito({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.idRestaurante,
  });

  // Convertir a JSON para enviar a la API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
      'id_restaurante': idRestaurante,
    };
  }
}

// ESTA ES LA LISTA GLOBAL (ACCESIBLE DESDE TODA LA APP)
class Carrito {
  static List<ProductoCarrito> items = [];

  static void agregar(ProductoCarrito producto) {
    // Verificar si ya existe para sumar cantidad
    int index = items.indexWhere((p) => p.id == producto.id);
    if (index != -1) {
      // Si ya existe, quitamos el viejo y ponemos el nuevo con más cantidad
      // (Simplificación para este tutorial)
      items[index] = ProductoCarrito(
        id: producto.id,
        nombre: producto.nombre,
        precio: producto.precio,
        cantidad: items[index].cantidad + producto.cantidad,
        idRestaurante: producto.idRestaurante,
      );
    } else {
      // Si el restaurante es diferente, podríamos limpiar el carrito (opcional)
      if (items.isNotEmpty &&
          items.first.idRestaurante != producto.idRestaurante) {
        items.clear(); // Solo permitir pedidos de un restaurante a la vez
      }
      items.add(producto);
    }
  }

  static double obtenerTotal() {
    double total = 0;
    for (var item in items) {
      total += (item.precio * item.cantidad);
    }
    return total;
  }

  static void limpiar() {
    items.clear();
  }
}
