// lib/core/http_client.dart

// Import condicional: en web usa IOClient, en móvil también.
// El paquete `http` expone IOClient en ambos entornos.
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' show IOClient;

/// Factory que devuelve un http.Client que no respeta CORS en web.
http.Client createHttpClient() {
  return IOClient();
}
