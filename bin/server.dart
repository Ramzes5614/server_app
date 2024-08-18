import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqflite/sqflite.dart';

final _router = Router()
  ..post('/temperature', _addTemperature)
  ..get('/temperature', _getTemperatures);

Database _db;

void main(List<String> args) async {
  _db = await openDatabase(
    'temperatures.db',
    onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE temperatures(id INTEGER PRIMARY KEY, temperature1 REAL, temperature2 REAL, date TEXT)",
      );
    },
    version: 1,
  );

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router.call);
  final server = await serve(handler, 'localhost', 8080);
  print('Server listening on port ${server.port}');
}

Future<Response> _addTemperature(Request request) async {
  final params = request.url.queryParameters;
  final temperature1 = double.tryParse(params['temperature1']);
  final temperature2 = double.tryParse(params['temperature2']);
  final date = params['date'];

  if (temperature1 == null || temperature2 == null || date == null) {
    return Response(400, body: 'Invalid parameters');
  }

  await _db.insert(
    'temperatures',
    {'temperature1': temperature1, 'temperature2': temperature2, 'date': date},
  );

  return Response.ok('Temperature added');
}

Future<Response> _getTemperatures(Request request) async {
  final params = request.url.queryParameters;
  final startDate = params['start_date'];
  final endDate = params['end_date'];

  if (startDate == null || endDate == null) {
    return Response(400, body: 'Invalid parameters');
  }

  final List<Map<String, dynamic>> maps = await _db.query(
    'temperatures',
    where: 'date BETWEEN ? AND ?',
    whereArgs: [startDate, endDate],
  );

  return Response.ok(maps.toString());
}