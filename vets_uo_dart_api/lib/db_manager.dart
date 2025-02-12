import 'package:mongo_dart/mongo_dart.dart';

class DbManager {
String _dbName = "vets-dart-api";
String _collectionName = "users";
late dynamic _collection;
late Db? _db;
DbManager(String dbName, String collectionName) {
_dbName = dbName;
_collectionName = collectionName;
}
DbManager.collection(String collectionName) {
_collectionName = collectionName;
}
Future<void> connect() async {
  final dbUrl = 'mongodb+srv://ivansantov:vOs3g58f@cluster0.h9zf8.mongodb.net/vets-dart-api?retryWrites=true&w=majority';
  
  _db = await Db.create(dbUrl);
  await _db?.open();
  _collection = _db?.collection(_collectionName);
}





Future<void> close() async {
  if (_db == null) {
    print('⚠️ Intentando cerrar pero _db es null.');
    return;
  }

  if (_db!.isConnected) {
    print('🔻 Cerrando conexión con MongoDB...');
    await _db!.close();
    print('✅ Conexión cerrada.');
  }
}


Future<List<Map<String, dynamic>>> findAll() async {
  try {
    print("🔍 Ejecutando findAll()");
    await connect(); // Asegura que hay conexión antes de buscar datos

    if (_db == null || !_db!.isConnected) {
      throw Exception("❌ No hay conexión con MongoDB");
    }

    print("✅ Ejecutando consulta...");
    final data = await _collection.find().toList();
    print("📄 Datos obtenidos: ${data.length} documentos");

    return data;
  } catch (error) {
    print("❌ Error en findAll: $error");
    return [
      {"error": "Error al recuperar los datos"}
    ];
  } finally {
    await close();
  }
}



}
