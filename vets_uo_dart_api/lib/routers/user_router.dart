import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:vets_uo_dart_api/models/user.dart';
import 'package:vets_uo_dart_api/repositories/user_repository.dart';
import 'package:vets_uo_dart_api/encrypt_password.dart' as encrypter;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:vets_uo_dart_api/user_token_service.dart' as jwt_service;


final userRouter = Router()
  ..get('/users', _usersHandler)
  ..post('/users/signUp', _signUpHandler)
  ..post('/users/login', _loginHandler)
  ..get('/users/<id>', _getUserHandler)
  ..delete('/users/<id>', _deleteUserHandler)
  ..put('/users/<id>', _updateUserHandler);

Future<Response> _getUserHandler(Request request) async {
  try {
    dynamic userId = ObjectId.fromHexString(request.params['id'].toString());
    final users = await UsersRepository.findOne({"_id": userId});
    return users != null
        ? Response.ok(json.encode(users))
        : Response.notFound(json.encode({"message": "Usuario no encontrado"}));
  } catch (e) {
    return Response.internalServerError(body: json.encode({"message": "Error inesperado", "error": e.toString()}));
  }
}

Future<Response> _deleteUserHandler(Request request) async {
  try {
    final dynamic userId = ObjectId.fromHexString(request.params['id'].toString());
    final userExists = await UsersRepository.findOne({"_id": userId});

    if (userExists == null) {
      return Response.notFound(json.encode({"message": "Usuario no encontrado"}));
    }

    final deleteResult = await UsersRepository.deleteOne({"_id": userId});
    
    if (deleteResult['error'] != null) {
      return Response.internalServerError(body: json.encode({"message": "Error al eliminar el usuario"}));
    }
    
    return Response.ok(json.encode({"message": "Usuario eliminado correctamente"}));
  } catch (e) {
    return Response.internalServerError(body: json.encode({"message": "Error inesperado", "error": e.toString()}));
  }
}

Future<Response> _loginHandler(Request request) async {
  final credentialRequestBody = await request.readAsString();
  final Map<String, dynamic> bodyParams = json.decode(credentialRequestBody);
  
  final String email = bodyParams['email'] ?? '';
  final String password = bodyParams['password'] ?? '';

  final Map<String, dynamic> credentials = {"email": email, "password": password};
  final authorizedUser = await areCredentialsValid(credentials);

  if (!authorizedUser) {
    return Response.unauthorized(json.encode({
      "message": "Credenciales inválidas",
      "authenticated": false
    }));
  } else {
    String token = jwt_service.UserTokenService.generateJwt({"email": email});
    return Response.ok(json.encode({
      "message": "Usuario autorizado",
      "authenticated": true,
      "token": token
    }));
  }
}

Future<bool> areCredentialsValid(Map<String, dynamic> credentials) async {
  final user = await UsersRepository.findOne({"email": credentials["email"]});
  if (user != null) {
    return encrypter.checkPassword(credentials["password"], user["password"]);
  }
  return false;
}

Future<Response> _usersHandler(Request request) async {
  try {
    final users = await UsersRepository.findAll();
    return Response.ok(json.encode(users));
  } catch (e) {
    return Response.internalServerError(body: json.encode({"message": "Error al obtener usuarios"}));
  }
}

Future<Response> _signUpHandler(Request request) async {
  final userRequestBody = await request.readAsString();
  final user = User.fromJson(json.decode(userRequestBody));
  
  final List<Map<String, String>> userValidationErrors = await validateUser(user);
  if (userValidationErrors.isNotEmpty) {
    return Response.badRequest(body: jsonEncode(userValidationErrors), headers: {'content-type': 'application/json'});
  }

  final userCreated = await UsersRepository.insertOne(user);
  if (userCreated.containsKey("error")) {
    return Response.internalServerError(body: jsonEncode({"message": "Error al crear el usuario"}));
  }

  return Response.ok(json.encode({"message": "Usuario creado correctamente"}));
}

Future<List<Map<String, String>>> validateUser(User user) async {
  List<Map<String, String>> errors = [];
  
  final userFound = await UsersRepository.findOne({"email": user.email});
  if (userFound != null) errors.add({"email": "El usuario ya existe con este correo"});

  if (user.email.isEmpty) errors.add({"email": "El correo es un campo obligatorio"});
  if (user.name.isEmpty) errors.add({"name": "El nombre es un campo obligatorio"});
  if (user.surname.isEmpty) errors.add({"surname": "El apellido es un campo obligatorio"});
  if (user.password.isEmpty || user.password.length < 6) {
    errors.add({"password": "La contraseña debe tener al menos 6 caracteres"});
  }

  return errors;
}

Future<Response> _updateUserHandler(Request request) async {
  try {
    final dynamic userId = ObjectId.fromHexString(request.params['id'].toString());
    final userExists = await UsersRepository.findOne({"_id": userId});

    if (userExists == null) {
      return Response.notFound(json.encode({"message": "Usuario no encontrado"}));
    }

    final requestBody = await request.readAsString();
    final Map<String, dynamic> updateData = json.decode(requestBody);

    updateData.remove('_id');
    updateData.remove('password');

    final updateResult = await UsersRepository.updateOne({"_id": userId}, updateData);
    
    if (updateResult['error'] != null) {
      return Response.internalServerError(body: json.encode({"message": "Error al actualizar el usuario"}));
    }

    return Response.ok(json.encode({"message": "Usuario actualizado correctamente"}));
  } catch (e) {
    return Response.internalServerError(body: json.encode({"message": "Error inesperado", "error": e.toString()}));
  }
}
