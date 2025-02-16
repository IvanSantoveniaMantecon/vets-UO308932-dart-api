import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:vets_uo_dart_api/user_token_service.dart' as jwt_service;

Middleware verifyTokenMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final String path = request.url.path;

      // Excluir rutas de login y signup del middleware
      if (path == 'users/signUp' || path == 'users/login') {
        return innerHandler(request);
      }

      final token = request.headers['token'] ?? "";
      final verifiedToken = jwt_service.UserTokenService.verifyJwt(token);

      if (verifiedToken['authorized'] == false) {
        return Response.unauthorized(json.encode({
          "message": "Token inválido o no autorizado",
          "error": "El Token no existe o está vacío"
        }));
      }

      return innerHandler(request);
    };
  };
}
