// Esta clase guardará los platos temporalmente en la memoria del celular
class Carrito {
  // La lista estática: accesible desde cualquier lado escribiendo Carrito.platos
  static List<Map<String, dynamic>> platos = [];

  // Guardamos el ID del restaurante para asegurar que solo se pida de uno a la vez
  static String? restauranteId;

  static void agregarPlato(Map<String, dynamic> plato, String idRest) {
    // Si intentan pedir de otro restaurante, limpiamos el carrito anterior
    if (restauranteId != null && restauranteId != idRest) {
      platos.clear();
    }
    restauranteId = idRest;

    // Verificamos si el plato ya existe para aumentar cantidad
    int index = platos.indexWhere((p) => p['id'] == plato['id']);
    if (index != -1) {
      platos[index]['cantidad'] += 1;
    } else {
      // Si es nuevo, lo agregamos con cantidad 1
      plato['cantidad'] = 1;
      platos.add(plato);
    }
  }

  static double obtenerTotal() {
    double total = 0;
    for (var p in platos) {
      // Convertimos a double por seguridad
      double precio = double.parse(p['precio'].toString());
      int cantidad = int.parse(p['cantidad'].toString());
      total += (precio * cantidad);
    }
    return total;
  }

  static void limpiar() {
    platos.clear();
    restauranteId = null;
  }
}
