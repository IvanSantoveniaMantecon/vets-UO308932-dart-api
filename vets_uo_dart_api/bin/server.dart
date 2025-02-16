import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:vets_uo_dart_api/routers/user_router.dart';
import 'package:vets_uo_dart_api/middelware/middelware.dart';

// Configure routes.
final _router = Router()
..get('/', _rootHandler);
Response _rootHandler(Request req) {
return Response.ok('Hello, World!\n');
}
void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(verifyTokenMiddleware()) // Agregamos el middleware
      .addHandler(Cascade().add(_router.call).add(userRouter.call).handler);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
