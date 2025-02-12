import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:vets_uo_dart_api/db_manager.dart';
import 'dart:convert';
// Configure routes.
final _router = Router()
..get('/', _rootHandler)
..get('/echo/<message>', _echoHandler)
..get('/users', _usersHandler);
Response _rootHandler(Request req) {
return Response.ok('Hello, World!\n');
}
Response _echoHandler(Request request) {
final message = request.params['message'];
return Response.ok('$message\n');
}
Future<Response> _usersHandler(Request request) async {
  DbManager dbManager = DbManager.collection("users");

  print("🌍 Intentando conectar a MongoDB en _usersHandler...");
  await dbManager.connect(); // Asegura que hay conexión

  final users = await dbManager.findAll();
  return Response.ok(
    json.encode(users),
    headers: {'Content-Type': 'application/json'},
  );
}





void main(List<String> args) async {
// Use any available host or container IP (usually `0.0.0.0`).
final ip = InternetAddress.anyIPv4;
// Configure a pipeline that logs requests.
final handler =
Pipeline().addMiddleware(logRequests()).addHandler(_router.call);
// For running in containers, we respect the PORT environment variable.
final port = int.parse(Platform.environment['PORT'] ?? '8080');
final server = await serve(handler, ip, port);
print('Server listening on port ${server.port}');
}
