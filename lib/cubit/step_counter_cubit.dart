import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:aad_oauth/model/config.dart';
import 'package:consentimiento/config/route_list.dart';
import 'package:consentimiento/main.dart';
import 'package:encrypt/encrypt.dart' as encryptLibrary;
import 'package:encrypt/encrypt.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:consentimiento/config/model/model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:typed_data';
part 'step_counter_state.dart';

final navigatorKey = GlobalKey<NavigatorState>();
Database? _database;
String? timeOfDay;
String token = '';
List<String> responseIds = [];
final IV iv = IV.fromSecureRandom(16);
String decrypted = '';

class StepCounterCubit extends Cubit<StepCounterState> {
  StepCounterCubit(BuildContext context)
      : super(StepCounterState.initial(context)) {
    _initDatabase();
  }

  void updateTextControllers(TextEditingController usuarioController,
      TextEditingController claveController) {
    emit(state.copyWith(
        usuarioController: usuarioController,
        claveController: claveController));
  }

  void _initDatabase() async {
    _database = await _openDatabase();
    // Realiza otras inicializaciones de la base de datos si es necesario
  }

  void updateEmpleados(List<Empleado> empleados) {
    emit(state.copyWith(empleados: empleados));
  }

  void clearFilteredEmpleados() {
    emit(state.copyWith(empleados: []));
  }

  void passStep() async {
    if (state.nextStep <= 3) {
      emit(state.copyWith(nextStep: state.nextStep + 1));
    }
    if (state.nextStep == 3) {
      print('move it');
    }
    if (state.nextStep > 3) {
      print('te pasaste');
    }
  }

  void previusStep() async {
    emit(state.copyWith(nextStep: state.nextStep - 1));
    print('steps: ${state.nextStep}');
  }

  void resetStep() async {
    emit(state.copyWith(nextStep: 0));
    print('pasos: ${state.nextStep}');
  }

  void resetEmpleado(Empleado? empleado) {
    emit(state.copyWith(selectedEmpleado: empleado = null));
  }

  void selectHacienda(Hacienda? hacienda) {
    emit(state.copyWith(selectedHacienda: hacienda));
  }

  void selectEmpleado2(Empleado? empleado) {
    emit(state.copyWith(selectedEmpleado: empleado));
  }

  void insertlatlon(double lat, double lon) {
    emit(state.copyWith(lat: lat, lon: lon));
  }

  void toggleSeleccion(Registro registro) {
    final List<Registro> nuevosRegistros = state.registros.map((r) {
      if (r == registro) {
        print('r');
        // Si es el registro seleccionado, cambia su estado
        r.seleccionado = !r.seleccionado;
      }
      return r;
    }).toList();
    print('rr');
    emit(state.copyWith(registros: nuevosRegistros));
  }

  void toggleSeleccionEmpleadoLoca(EmpleadoLocal empleadoLocal) {
    final List<EmpleadoLocal> nuevosEmpleadosL = state.empleadoL.map((r) {
      if (r == empleadoLocal) {
        print('r');
        // Si es el registro seleccionado, cambia su estado
        r.seleccionado = !r.seleccionado;
      }
      return r;
    }).toList();
    print('rr');
    emit(state.copyWith(empleadoL: nuevosEmpleadosL));
  }

  void toggleSeleccionConsentimientoLoca(
      ConsentimientoLocal consentimientoLocal) {
    final List<ConsentimientoLocal> nuevosConsentimientosL =
        state.consentimientoL!.map((r) {
      if (r == consentimientoLocal) {
        print('r');
        // Si es el registro seleccionado, cambia su estado
        r.seleccionado = !r.seleccionado;
      }
      return r;
    }).toList();
    print('rr');
    emit(state.copyWith(consentimientoL: nuevosConsentimientosL));
  }

  void eliminarRegistrosSeleccionados() {
    final nuevosConsentimientoL = state.consentimientoL
        .where((consentimientoL) => !consentimientoL.seleccionado)
        .toList();
    emit(state.copyWith(consentimientoL: nuevosConsentimientoL));
  }

  void actualizarRegistros(List<ConsentimientoLocal> nuevosConsentimientoL) {
    emit(state.copyWith(consentimientoL: nuevosConsentimientoL));
    print(state.consentimientoL);
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'consentimientoss.db');
    return openDatabase(path, version: 1, onCreate: (db, version) {
      db.execute(
          'CREATE TABLE Haciendas (id INTEGER PRIMARY KEY, name TEXT, aban8 INTEGER, estado TEXT, id_hacienda TEXT)');
      db.execute(
          'CREATE TABLE Plantillas (id INTEGER PRIMARY KEY, titulo TEXT, contenidoC TEXT, contenidoV TEXT, id_plantilla INTEGER, estado TEXT)');
      db.execute(
          'CREATE TABLE Empleados (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, cedula TEXT, empresa TEXT, hacienda_id TEXT, estado TEXT, id_zona TEXT, id_empleado INTEGER , FOREIGN KEY (hacienda_id) REFERENCES Haciendas(id))');
      db.execute(
          'CREATE TABLE Empleado (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, cedula TEXT, empresa TEXT, hacienda_id TEXT, estado TEXT, id_zona TEXT, id_empleado INTEGER)');
      db.execute(
          'CREATE TABLE Consentimiento (id INTEGER PRIMARY KEY AUTOINCREMENT, id_empleado INTEGER, id_emp_zona_hac INTEGER , aceptado TEXT, lat REAL, lon REAL, fecha TEXT, hora TEXT ,estado_contratacion TEXT, path_img TEXT, path_video TEXT)');
      db.execute(
          'CREATE TABLE Encuestas (id INTEGER PRIMARY KEY AUTOINCREMENT, id_encuesta INTEGER, id_plantilla INTEGER, estado TEXT, id_tipo_compania INTEGER, nombre TEXT, fecha_inicio TEXT, fecha_fin TEXT)');
      db.execute(
          'CREATE TABLE Companias (id INTEGER PRIMARY KEY AUTOINCREMENT, id_compania TEXT, nombre TEXT, logo TEXT)');
      db.execute(
          'CREATE TABLE Keys (id INTEGER PRIMARY KEY AUTOINCREMENT, token TEXT, key TEXT, expire INTEGER, perfil TEXT, iv TEXT)');
    });
  }

  void resetState() async {
    emit(state.copyWith(
      haciendas: [],
      empleados: [],
      plantilla: [],
      encuestas: [],
      compania: [],
      permisos: [],
      responseLogin: [],
      contenidoC: "",
      contenidoV: "",
      titulo: "",
      estadoPlantilla: "",
      idsHaciendas: [],
      idsEncuestas: [],
      //selectedEmpleado: null,
      //selectedHacienda: null,
    ));
  }

  void loadDataHacienda() async {
    try {
      final Uri uri = Uri.parse(
          //https://10.96.80.66:10447
          //'https://10.35.3.11:10447/Entity/HaciendaES/api/es/hacienda');
          'https://srbp01ap00.favoritafruit.corp:10447/Entity/HaciendaES/api/es/hacienda');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<Hacienda> haciendasFiltradas = [];
        final List<dynamic> jsonData = jsonDecode(response.body);
        final List<Hacienda> haciendas =
            jsonData.map((data) => Hacienda.fromJson(data)).toList();
        final permisosselect = state.idsHaciendas;
        for (var id in permisosselect) {
          try {
            var haciendaFiltrada =
                haciendas.firstWhere((hacienda) => hacienda.id == id);
            if (haciendaFiltrada != null) {
              haciendasFiltradas.add(haciendaFiltrada);
            }
            print(haciendasFiltradas);
          } catch (e) {
            print('error al filtrar haciendas de permisos: $e');
          }
        }

        for (var hacienda in haciendasFiltradas) {
          String id = hacienda.id;

          int? aban8 = hacienda.aban8;
          // Imprime otras propiedades si es necesario
          print('Id: $id, Aban8: $aban8');
        }

        await insertHaciendasToSQL(haciendasFiltradas);
        try {
          cargarHaciendasDesdeSQL();
        } catch (e) {
          print('error no se pudo cargar desde el metodo la data del sql: $e');
        }
      } else {
        throw Exception('Failed to load data from the API');
      }
    } catch (e) {
      print('Error H: $e');
    }
  }

  Future<void> cargarHaciendasDesdeSQL() async {
    try {
      final haciendasDesdeSQL = await getHaciendasFromSQL();
      if (haciendasDesdeSQL.isNotEmpty) {
        emit(state.copyWith(haciendas: haciendasDesdeSQL));
      }
    } catch (e) {
      print('Error al cargar las haciendas desde la tabla SQL: $e');
    }
  }

  Future<void> insertHaciendasToSQL(List<Hacienda> haciendas) async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final batch = _database!.batch();
    for (Hacienda hacienda in haciendas) {
      final existingHaciendas = await _database!.query(
        'Haciendas',
        where: 'id_hacienda = ?',
        whereArgs: [hacienda.name],
      );
      if (existingHaciendas.isEmpty) {
        batch.insert('Haciendas', hacienda.toMap());
      }
    }

    await batch.commit();
  }

  Future<List<Hacienda>> getHaciendasFromSQL() async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final List<Map<String, dynamic>> results =
        await _database!.query('Haciendas');
    return results.map((map) => Hacienda.fromMap(map)).toList();
  }

  void loadDataPlantilla() async {
    try {
      final response = await http.get(
        Uri.parse(
            //'https://10.35.3.11:10447/Entity/PlantillaES/api/es/plantilla'),
            'https://srbp01ap00.favoritafruit.corp:10447/Entity/PlantillaES/api/es/plantilla'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<Plantilla> plantillasFiltrados = [];
        final List<dynamic> jsonData = jsonDecode(response.body);
        print(jsonData);
        final List<Plantilla> plantillas =
            jsonData.map((data) => Plantilla.fromJson(data)).toList();

        for (var plantilla in plantillas) {
          if (plantilla.estado == "A") {
            plantillasFiltrados.add(plantilla);
          } else if (plantilla.estado == "I") {
            print('estdos I: ${plantillas}');
          }
        }

        await insertPlantillaToSQL(plantillasFiltrados);

        //await insertPlantillaToSQL(plantillas);
        try {
          cargarPlantillaDesdeSQL();
        } catch (e) {
          print('Error al cargar las plantillas desde la tabla SQL: $e');
        }
      } else {
        throw Exception('Failed to load data from the API');
      }
    } catch (e) {
      print('Error P: $e');
    }
  }

  Future<void> cargarPlantillaDesdeSQL() async {
    try {
      final plantillaDesdeSQL = await getPlantillasFromSQL();
      if (plantillaDesdeSQL.isNotEmpty) {
        emit(state.copyWith(plantilla: plantillaDesdeSQL));
      }
      print('plantillas sql: ${state.plantilla}');
    } catch (e) {
      print('Error al cargar las plantillas desde la tabla SQL: $e');
    }
  }

  Future<void> insertPlantillaToSQL(List<Plantilla> plantillas) async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final batch = _database!.batch();
    for (Plantilla plantilla in plantillas) {
      final existingPlantillas = await _database!.query(
        'Plantillas',
        where: 'titulo = ?',
        whereArgs: [plantilla.titulo],
      );
      if (existingPlantillas.isEmpty) {
        batch.insert('Plantillas', {
          'titulo': plantilla.titulo,
          'contenidoC': plantilla.contenidoC,
          'contenidoV': plantilla.contenidoV,
          'id_plantilla': plantilla.id,
          'estado': plantilla.estado, // Convierte bool a int
        });
      }
    }
    await batch.commit();
  }

  Future<List<Plantilla>> getPlantillasFromSQL() async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final List<Map<String, dynamic>> results =
        await _database!.query('Plantillas');
    return results.map((map) => Plantilla.fromMap(map)).toList();
  }

  String encryptString(
    String texto,
  ) {
    final encrypter = Encrypter(
        AES(encryptLibrary.Key.fromUtf8(decrypted), mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(texto, iv: iv);
    print('credenciales: ${state.key.keys} y $iv');
    return encrypted.base64;
  }

  void loadDataEmpleado(
    List<String> idHaciendas,
    List<int> idEncuestas,
  ) async {
    List<Empleado> allEmpleados = [];

    Set<String> combinacionesUnicas = Set<String>();

    try {
      for (String idHacienda in idHaciendas) {
        // for (int idEncuesta in idEncuestas[0]) {
        String combinacion = '$idHacienda-${idEncuestas[0]}';

        if (combinacionesUnicas.contains(combinacion)) {
          continue;
        }

        final response = await http.get(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          Uri.parse(
              //'https://10.35.3.11:10447/Entity/PersonaES/api/es/persona/encuesta/${idHacienda}/${idEncuestas[0]}'),
              'https://srbp01ap00.favoritafruit.corp:10447/Entity/PersonaES/api/es/persona/encuesta/${idHacienda}/${idEncuestas[0]}'),
        );

        var idEncuestaSP = idEncuestas[0];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('idEncuestaSP', idEncuestaSP);

        if (response.statusCode == 200) {
          final List<dynamic> jsonData = jsonDecode(response.body);

          final List<Empleado> empleados =
              jsonData.map((data) => Empleado.fromJson(data)).toSet().toList();

          for (Empleado empleado in empleados) {
            print('keys: ${state.key!.keys}');
            empleado.name = encryptString(empleado.name);
            empleado.cedula = encryptString(empleado.cedula);
          }

          allEmpleados.addAll(empleados);

          combinacionesUnicas.add(combinacion);
        } else {
          throw Exception(
              'Failed to load data from the API for Hacienda $idHacienda and Encuesta $idEncuestas');
        }
        //}
      }

      allEmpleados.sort((a, b) => a.name.compareTo(b.name));
      await insertarEmpleadostoSQL(allEmpleados);
      try {
        cargarEmpleadosDesdeSQL();
      } catch (e) {
        print('failed cargar empleados to SQL from metodo: $e');
      }
    } catch (e) {
      print('Error E: $e');
    }
  }

  Future<void> insertarEmpleadostoSQL(List<Empleado> empleados) async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final batch = _database!.batch();
    for (Empleado empleado in empleados) {
      final existingEmpleados = await _database!.query(
        'Empleados',
        where: 'name = ?',
        whereArgs: [empleado.name],
      );
      if (existingEmpleados.isEmpty) {
        batch.insert('Empleados', empleado.toMap());
      }
    }

    await batch.commit();
  }

  Future<void> cargarEmpleadosDesdeSQL() async {
    try {
      cargarKeysDesdeSQL();
      final empleadosDesdeSQL = await getEmpleadosFromSQL();
      if (empleadosDesdeSQL.isNotEmpty) {
        String claveCifrado = state.key.keys;
        String ivDB = state.key.iv;
        //Uint8List ivDecoded = base64Decode(ivDB);
        IV iv2 = IV.fromBase64(ivDB);

        final prefs = await SharedPreferences.getInstance();
        var clave = await prefs.getString('claveBase64');
        var ivR = await prefs.getString('ivBase64');

        final claveRecuperada =
            encryptLibrary.Key(Uint8List.fromList(base64.decode(clave!)));
        final ivRecuperado =
            encryptLibrary.IV(Uint8List.fromList(base64.decode(ivR!)));

        //metodo para crear el nuevo objeto para desencriptar
        final encrypter2 =
            encryptLibrary.Encrypter(encryptLibrary.AES(claveRecuperada));

        // Para desencriptar en el futuro, utiliza la misma clave y IV
        decrypted = encrypter2.decrypt(
            encryptLibrary.Encrypted.fromBase64(claveCifrado),
            iv: ivRecuperado);
        print('00 Valor desencriptado: $decrypted');

        final encrypter = encryptLibrary.Encrypter(encryptLibrary.AES(
          encryptLibrary.Key.fromUtf8(decrypted),
          mode: encryptLibrary.AESMode.cbc,
        ));

        List<Empleado> empleadosCifrados = empleadosDesdeSQL;

        for (Empleado empleado in empleadosCifrados) {
          final nombreCifrado =
              encryptLibrary.Encrypted.fromBase64(empleado.name);
          final cedulaCifrada =
              encryptLibrary.Encrypted.fromBase64(empleado.cedula);
          final nombreDesencriptado = encrypter.decrypt(nombreCifrado, iv: iv2);
          final cedulaDesencriptada = encrypter.decrypt(cedulaCifrada, iv: iv2);

          empleado.name = nombreDesencriptado;
          empleado.cedula = cedulaDesencriptada;
        }
        empleadosCifrados.sort((a, b) => a.name.compareTo(b.name));

        emit(state.copyWith(empleados: empleadosCifrados));
      }
    } catch (e) {
      print('Error al cargar las empleados desde la tabla SQL: $e');
    }
    loadEmployeeData();
    contadorEmpleadosAceptados();
  }

  Future<List<Compania>> getCompaniasFromSQL() async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final List<Map<String, dynamic>> results =
        await _database!.query('Companias');
    return results.map((map) => Compania.fromMap(map)).toSet().toList();
  }

  Future<List<Empleado>> getEmpleadosFromSQL() async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final List<Map<String, dynamic>> results =
        await _database!.query('Empleados');
    return results.map((map) => Empleado.fromMap(map)).toSet().toList();
  }

  Future<List<Keys>> getKeysFromSQL() async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final List<Map<String, dynamic>> results = await _database!.query('Keys');
    print(results);
    return results.map((map) => Keys.fromMap(map)).toList();
  }

  void loadDataCompania() async {
    try {
      final response = await http.get(
        //https://10.96.80.66:10447
        Uri.parse(
            //'https://10.35.3.11:10447/Entity/CompaniaES/api/es/compania'),
            'https://srbp01ap00.favoritafruit.corp:10447/Entity/CompaniaES/api/es/compania'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final List<Compania> companiasFiltradas = [];
        print(jsonData);
        final List<Compania> companies =
            jsonData.map((data) => Compania.fromJson(data)).toList();

        //emit(state.copyWith(compania: companies));
        await insertarComapaniesToSQL(companies);
        try {
          cargarCompaniasDesdeSQL();
        } catch (e) {
          print('failed cargar companias to SQL from metodo: $e');
        }
      } else {
        throw Exception('Failed to load data from the API');
      }
    } catch (e) {
      // Maneja cualquier error que pueda ocurrir durante la carga de datos.
      print('Error C: $e');
    }
  }

  Future<void> insertarComapaniesToSQL(List<Compania> companias) async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final batch = _database!.batch();
    for (Compania compania in companias) {
      final existingCompanias = await _database!.query(
        'Companias',
        where: 'id_compania = ?',
        whereArgs: [compania.id],
      );
      if (existingCompanias.isEmpty) {
        batch.insert('Companias', compania.toMap());
      }
    }
    // Realiza la inserción en la base de datos
    await batch.commit();
  }

  void loadDataDispositivo() async {
    try {
      final response = await http.get(
        Uri.parse(
            //'https://10.35.3.11:10447/Entity/DispositivoES/api/es/dispositivo'),
            'https://srbp01ap00.favoritafruit.corp:10447/Entity/DispositivoES/api/es/dispositivo'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        print(jsonData);
        final List<Dispositivo> dispositivos =
            jsonData.map((data) => Dispositivo.fromJson(data)).toList();
        //emit(state.copyWith(nextStep: state.nextStep + 1));
        emit(state.copyWith(dispositivo: dispositivos));
      } else {
        throw Exception('Failed to load data from the API');
      }
    } catch (e) {
      // Maneja cualquier error que pueda ocurrir durante la carga de datos.
      print('Error PI: $e');
    }
  }

  Future<void> cargarCompaniasDesdeSQL() async {
    try {
      final companiesDesdeSQL = await getCompaniasFromSQL();
      if (companiesDesdeSQL.isNotEmpty) {
        emit(state.copyWith(compania: companiesDesdeSQL));
      }
    } catch (e) {
      print('Error al cargar las companias desde la tabla SQL: $e');
    }
  }

  void marcarEmpleadoAceptado(Empleado empleado) {
    final nuevosEmpleados = state.empleados.map((e) {
      final now = DateTime.now();
      final fecha = now.toLocal();
      final dia = fecha.day;
      final mes = fecha.month;
      final year = fecha.year;
      String fecha2 = '$dia/$mes/$year';
      if (e.id == empleado.id) {
        final empleadoAceptado = e.copyWithEstadoContratacion('A', fecha2);
        print('Estado cambiado: ${empleadoAceptado.estado_encuesta}');
        //actualizarEmpleadoAceptado(empleadoAceptado.id);
        return empleadoAceptado;
        //return e.copyWithEstadoContratacion('aceptado');
      } else {
        return e;
      }
    }).toList();
    emit(state.copyWith(empleados: nuevosEmpleados));
  }

  Future<void> marcarEmpleadoAceptado2(int empleadoId) async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final empleadoAceptadoData = {
      'estado': 'A',
    };

    await _database!.update(
      'Empleados', // Nombre de la tabla
      empleadoAceptadoData, // Datos actualizados
      where: 'id_empleado = ?', // Condición WHERE para identificar el empleado
      whereArgs: [empleadoId], // Valor del empleadoId
    );
  }

  Future<void> insertarEmpleado(Empleado empleado) async {
    final now = DateTime.now();
    final fecha = now.toLocal();
    final dia = fecha.day;
    final mes = fecha.month;
    final year = fecha.year;
    String fecha2 = '$dia/$mes/$year';
    final empleadoAceptado = empleado.copyWithEstadoContratacion('A', fecha2);

    // Luego, guárdalo en la base de datos
    if (_database != null) {
      await _database!.insert('Empleado', empleadoAceptado.toMap());
      print('Empleado insertado en la base de datos con estado "aceptado"');
    }
  }

  Future<void> llenarYInsertarConsentimiento(
      //aqui hare el filtrado y la busqueda, agregare la lista de permisos,
      //luego buscare en cada item de la lista el id hacienda y el id permiso, luego que tenga el id hacienda,
      //lo filtrare en haciendas, buscare al empleado si es de esa hacienda y agregare el id permiso de acuerdo a esa id hacienda y empleado
      Hacienda hacienda,
      Empleado empleado,
      String pathIMG,
      String pathVIDEO) async {
    try {
      var id_permiso;
      final permisos = state.permisos;
      final now = DateTime.now();
      final fecha = now.toLocal();
      final hora = TimeOfDay.fromDateTime(fecha);
      final dia = fecha.day;
      final mes = fecha.month;
      final year = fecha.year;
      for (final permiso in permisos) {
        if (permiso.idHacienda == empleado.haciendaId) {
          id_permiso = permiso.id_permiso;
          print(
              'Permiso encontrado para empleado en esta hacienda: ${permiso.id_permiso}');
        }
      }
      String fecha2 = '$dia/$mes/$year';
      final consentimiento = Consentimiento(
        idEmpleado: empleado.id,
        fecha: fecha.toString(),
        hora: hora.toString(), // Usando la hora actual
        estadoContratacion: empleado.estado_encuesta,
        aceptado: true,
        id_emp_zona_hac: idEncuestaSP2,
        lat: state.lat,
        lon: state.lon,
        pathIMG: pathIMG,
        pathVIDEO: pathVIDEO,
      );

      if (_database != null) {
        await _database!.insert('Consentimiento', consentimiento.toMap());
        print('Consentimiento insertado en la tabla Empleado');
      }
      // Itera a través de la lista de permisos y busca coincidencias
    } catch (e) {
      // Maneja cualquier error que pueda ocurrir durante el proceso.
      print('Error: $e');
    }
  }

  Future<List<ConsentimientoLocal>> getConsentimientoLocalFromSQL() async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final List<Map<String, dynamic>> results =
        await _database!.query('Consentimiento');
    return results.map((map) => ConsentimientoLocal.fromMap(map)).toList();
  }

  Future<void> loadConsentimientoLocalData() async {
    // Implementa la lógica para cargar los datos de los empleados desde la base de datos local.
    // Esto puede incluir ejecutar una consulta SQL y mapear los resultados en objetos Registro.
    final consent = await getConsentimientoLocalFromSQL();
    // Actualiza el estado con los datos cargados.
    print('cargaaaa: ${consent}');
    emit(state.copyWith(consentimientoL: consent));
  }

  Future<List<EmpleadoLocal>> getEmployeesLocalFromSQL() async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final List<Map<String, dynamic>> results =
        await _database!.query('Empleado');
    return results.map((map) => EmpleadoLocal.fromMap(map)).toList();
  }

  Future<void> loadEmployeeData() async {
    // Implementa la lógica para cargar los datos de los empleados desde la base de datos local.
    // Esto puede incluir ejecutar una consulta SQL y mapear los resultados en objetos Registro.
    final employees = await getEmployeesLocalFromSQL();
    // Actualiza el estado con los datos cargados.
    emit(state.copyWith(empleadoL: employees));
  }

  Future<void> borrarTablasSQL() async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    // Ejecuta las sentencias SQL para borrar las tablas
    await _database!.transaction((txn) async {
      await txn.rawDelete('DELETE FROM Haciendas');
      await txn.rawDelete('DELETE FROM Plantillas');
      await txn.rawDelete('DELETE FROM Empleados');
      await txn.rawDelete('DELETE FROM Encuestas');
      await txn.rawDelete('DELETE FROM Companias');
      await txn.rawDelete('DELETE FROM Keys');
    });

    print('Tablas SQL borradas');
  }

  Future<void> borrarTablaSQLConsentimiento() async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    // Ejecuta las sentencias SQL para borrar las tablas
    await _database!.transaction((txn) async {
      await txn.rawDelete('DROP TABLE IF EXISTS Consentimiento');
    });

    print('Tablas SQL borradas');
  }

  Future<void> deleteAllConsentimientos() async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    // Ejecuta la sentencia SQL para eliminar todas las filas de la tabla 'Consentimiento'.
    await _database!.rawDelete('DELETE FROM Consentimiento');

    // Actualiza el estado de la aplicación para reflejar los cambios.
    emit(state.copyWith(
        consentimientoL: [])); // Borra todos los consentimientos en el estado.
  }

  Future<int?> getEmployeeCount() async {
    final db =
        await _openDatabase(); // Abre la base de datos (debe estar implementada en tu código).
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM Empleado'));
    return count;
  }

  void actualizarFecha() {
    initializeDateFormatting('es'); // Inicializa la localización en español
    final now = DateTime.now();
    final fecha = now.toLocal();
    final dia = fecha.day;
    final mes = fecha.month;
    final year = fecha.year;
    final hora = TimeOfDay.fromDateTime(fecha);
    // Obtén el nombre del mes en español
    final mesNombre = DateFormat.MMMM('es').format(fecha);

    emit(state.copyWith(mes: mesNombre, anio: year, dia: dia, hora: hora));
  }

  Future<void> SendDataDispositivo(String deviceId, String nameDevice,
      BuildContext context, String wifiname) async {
    final url = Uri.parse(
        'https://srbp01ap00.favoritafruit.corp:10447/Entity/DispositivoES/api/es/dispositivo');
    final now = DateTime.now();
    final formattedDate = now.toUtc().toIso8601String();
    final replaceWN = wifiname.replaceAll('"', '');

    final Map<String, dynamic> data = {
      "Wifi": replaceWN,
      "Identificador": "$deviceId",
      "Nombre": "$nameDevice",
      "Estado": "A",
      "UsuarioCreador": 0,
      "FechaCreacion": formattedDate
    };

    final jsonData = jsonEncode(data);
    print('data a enviar: $jsonData');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonData,
      );

      if (response.statusCode == 201) {
        final cubit = context.read<StepCounterCubit>();
        _showRegistrePopup(context, cubit);
      } else {
        print('Error en la solicitud: ${response.statusCode}');
        _showUnRegistrePopup(context);
        print(response.body);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future SendDataConsentimientos(
      List<ConsentimientoLocal> consentimientos) async {
    for (final consentimiento in consentimientos) {
      final String responseId = await SendDataConsentimiento(consentimiento);
      if (responseId != null) {
        responseIds.add(responseId);
        emit(state.copyWith(respondeIds: responseIds));
      }
    }
  }

  void saveLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now();
    prefs.setInt('loginTime', currentTime.millisecondsSinceEpoch);
    print('guardo sesion');
  }

  static final Config config = new Config(
    navigatorKey: navigatorKey,
    tenant: "242d51ea-ee67-47c1-9913-352e12776ebe",
    clientId: "e166e119-5f16-4445-a4fc-a23f5333bcc5",
    scope: "openid profile offline_access User.read",
    redirectUri:
        "msauth://com.reybanpac.consentimiento/sBEl%2FMdK4KZarZXFRHsTetmNv%2B0%3D",
    isB2C: false,
    domainHint: "consumers",
  );

  void logout() async {
    final AadOAuth oauth = AadOAuth(config);
    await oauth.logout();
  }

  static const userProfileBaseUrl = 'https://graph.microsoft.com/v1.0/me';
  static const authorization = 'Authorization';
  static const bearer = 'Bearer ';
  // Microsoft Graph API call to fetch user profile
  Future authenticateMyProfile() async {
    final AadOAuth oauth = AadOAuth(config);
    try {
      await oauth.login();
      String? accessToken = await oauth.getAccessToken();
      print(accessToken);
      var response = await http.get(
          Uri.parse('https://graph.microsoft.com/v1.0/me'),
          headers: {authorization: bearer + accessToken!});
      print(response.body);
      // Decodificar la respuesta JSON
      Map<String, dynamic> userData = json.decode(response.body);
      String givenName = userData['givenName'];
      // Guardar el valor en SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', givenName);
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<String> signIn(String email, String password, BuildContext context,
      StepCounterCubit cubit) async {
    config.loginHint = email;
    final AadOAuth oauth = AadOAuth(config);

    await oauth.login();
    final accessToken = await oauth.getAccessToken();

    final Map<String, dynamic> requestData = {
      "Usuario": email,
      "Clave": password,
      "Identificador": deviceId,
    };
    try {
      if (accessToken == null) {
        print('Acces Token is Null');
        _showErrorLoginToken(context, cubit);
      } else {
        final graphResponse = await http.post(
          Uri.parse(
              //'https://10.35.3.11:10447/Micro/LoguearUsuarioMS/api/ms/loguearusuario'),
              'https://srbp01ap00.favoritafruit.corp:10447/Micro/LoguearUsuarioMS/api/ms/loguearusuario'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(requestData),
        );
        switch (graphResponse.statusCode) {
          case HttpStatus.ok:
            //startSession(720);
            authenticateMyProfile().then((value) => Navigator.of(context)
                .pushReplacementNamed(RouteList.dashboard));
            saveLoginTime();
            print('Éxito');
            String ivEncode = base64Encode(iv.bytes);

            //print('IV en base64: $ivBase64');
            final dynamic jsonData = jsonDecode(graphResponse.body);

            if (jsonData is Map<String, dynamic> &&
                jsonData.containsKey('token') &&
                jsonData.containsKey('key') &&
                jsonData.containsKey('expires')) {
              print('${ivEncode}');
              Keys keys = Keys.fromJson({
                'token': jsonData['token'],
                'key': jsonData['key'],
                'expires': jsonData['expires'],
                'iv': ivEncode,
              });

              // Decodificar el campo Key que viene en base64
              final String base64Key = keys.keys;
              final Uint8List keyBytes = base64.decode(base64Key);
              final decodedString = utf8.decode(keyBytes);
              //guardar en el sql
              /////////
              List<Keys> keyList = [];

              print(' 008 Cadena decodificada: $decodedString');
              // Genera una clave segura para AES (32 bytes, 256 bits) - key 2
              final secureKey = encryptLibrary.Key.fromSecureRandom(32);

              // Genera un IV aleatorio (16 bytes) -- iv 2
              final iv = encryptLibrary.IV.fromSecureRandom(16);

              // Crea una instancia de Encrypter con la clave y el IV
              final encrypter =
                  encryptLibrary.Encrypter(encryptLibrary.AES(secureKey));

              // Valor a encriptar
              final valorOriginal = decodedString;

              // Encripta el valor
              final encrypted = encrypter.encrypt(valorOriginal, iv: iv);

              // Convierte el valor encriptado a una representación de cadena
              final valorEncriptado = encrypted.base64;

              print(' 008 Valor encriptado y en base 64: $valorEncriptado');
              final claveBase64 =
                  base64.encode(secureKey.bytes); //convierte key 2 en base 64
              final ivBase64 =
                  base64.encode(iv.bytes); // convierte iv 2 en base 64
              print('Clave en Base64: $claveBase64');
              print('IV en Base64: $ivBase64');
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('claveBase64', claveBase64);
              await prefs.setString('ivBase64', ivBase64);

              keys.keys = valorEncriptado;
              keyList.add(keys);
              await insertarKeystoSQL(keyList);
              try {
                cargarKeysDesdeSQL();
              } catch (e) {
                print('failed cargar keys to SQL from metodo: $e');
              }
              //print('prueba: ${state.key!.keys}');

//codigo para decodificar las claves a base 64 de las key 2
              final claveRecuperada = encryptLibrary.Key(
                  Uint8List.fromList(base64.decode(claveBase64)));
              final ivRecuperado = encryptLibrary
                  .IV(Uint8List.fromList(base64.decode(ivBase64)));

              //metodo para crear el nuevo objeto para desencriptar
              final encrypter2 =
                  encryptLibrary.Encrypter(encryptLibrary.AES(claveRecuperada));

              // Para desencriptar en el futuro, utiliza la misma clave y IV
              decrypted = encrypter2.decrypt(
                  encryptLibrary.Encrypted.fromBase64(keys.keys),
                  iv: ivRecuperado);
              print('008 Valor desencriptado: $decrypted');

              final List<dynamic> permisosJson = jsonData['permisos'];

              emit(state.copyWith(key: keys));

              token = jsonData['token'];

              final List<Permiso> permisos = permisosJson
                  .map((permisoJson) => Permiso.fromJson(permisoJson))
                  .toList();

              // Extraer los IDs de las haciendas
              final List<String> haciendaIds =
                  permisos.map((permiso) => permiso.idHacienda).toList();

              // Extraer los IDs de las encuestas
              final List<int> encuestaIds =
                  permisos.map((permiso) => permiso.idEncuesta).toList();

              final RespondeLogin responseLogin = RespondeLogin(
                token: jsonData['token'],
                permisos: permisos,
              );

              final List<RespondeLogin> currentResponseLogin =
                  state.responseLogin ?? [];

              final List<RespondeLogin> updatedResponseLogin =
                  List<RespondeLogin>.from(currentResponseLogin)
                    ..add(responseLogin);

              //print('Respuesta: ${response.body}');
              emit(state.copyWith(permisos: permisos));
              emit(state.copyWith(responseLogin: updatedResponseLogin));
              emit(state.copyWith(idsHaciendas: haciendaIds));
              emit(state.copyWith(idsEncuestas: encuestaIds));

              // Aquí puedes hacer lo que necesites con los IDs de las haciendas
              print('Hacienda IDs: $haciendaIds');
            } else {
              throw Exception('Invalid or missing data in the response.');
            }
            print('entro en los load');
            loadDataEmpleado(state.idsHaciendas, state.idsEncuestas);
            print(state.responseLogin);
            print(state.idsHaciendas);
            _openDatabase();
            loadDataHacienda();
            loadDataPlantilla();

            loadDataCompania();
            loadDataDispositivo();
            loadDataEncuesta();
            buscarIdPlantillas();
            //Navigator.of(context).pushReplacementNamed(RouteList.dashboard);
            _showWelcome(context, cubit);
            break;
          case HttpStatus.badGateway:
            print('Error en la puerta de enlace');
            _showErrorLogin(context, cubit);
            throw Exception('Failed to load data from the API login');

          case HttpStatus.badRequest:
            print('Solicitud incorrecta');
            _showErrorLogin(context, cubit);
            throw Exception('Failed to load data from the API login');

          default:
            print('Código de estado desconocido: ${graphResponse.statusCode}');
            break;
        }
      }
    } catch (e) {
      print('error $e');
    }

    return 'se lazo la variable';
  }

  Future<void> insertarKeystoSQL(List<Keys> keys) async {
    if (_database == null) {
      _database = await _openDatabase();
    }

    final batch = _database!.batch();
    for (Keys key in keys) {
      final existingKeys = await _database!.query(
        'Keys',
        where: 'key = ?',
        whereArgs: [key.keys],
      );
      if (existingKeys.isEmpty) {
        batch.insert('Keys', key.toMap());
      }
    }

    await batch.commit();
  }

  Future<void> cargarKeysDesdeSQL() async {
    try {
      final keysDesdeSQL = await getKeysFromSQL();
      if (keysDesdeSQL.isNotEmpty) {
        emit(state.copyWith(key: keysDesdeSQL[0]));
      }
    } catch (e) {
      print('Error al cargar las keys desde la tabla SQL 1 : $e');
    }
  }

  Future<void> buscarIdPlantillas() async {
    final cubitencuesta = state.encuestas;
    final cubitPlantilla = state.plantilla;

    for (var encuesta in cubitencuesta) {
      for (var plantilla in cubitPlantilla) {
        if (encuesta.id_plantilla == plantilla.id) {
          String titulo = plantilla.titulo;
          String contenidoC = plantilla.contenidoC;
          String contenidoV = plantilla.contenidoV;
          String estadoPlantilla = plantilla.estado;
          emit(state.copyWith(
              titulo: titulo,
              contenidoC: contenidoC,
              contenidoV: contenidoV,
              estadoPlantilla: estadoPlantilla));
          print('Título: ${state.titulo}');
          print('Contenido: ${state.contenidoC}');
          print('Contenido: ${state.estadoPlantilla}');
        }
      }
    }
  }

  void contadorEmpleadosAceptados() async {
    List<Empleado> empleadoss = state.empleados;
    List<Hacienda> haciendass = state.haciendas;

    List<int> cantidadTotalEmpleadosPorHacienda = [];

    for (Hacienda hacienda in haciendass) {
      String idHacienda = hacienda.id;

      // Filtra los empleados por su hacienda.
      List<Empleado> empleadosEnHacienda = empleadoss
          .where((empleado) {
            return empleado.haciendaId == idHacienda;
          })
          .toSet()
          .toList();

      // Obtiene la cantidad total de empleados en la hacienda.
      int cantidadTotalEmpleados = empleadosEnHacienda.length;
      cantidadTotalEmpleadosPorHacienda.add(cantidadTotalEmpleados);
    }

    print(
        "Cantidad total de empleados por cada hacienda: $cantidadTotalEmpleadosPorHacienda");
    emit(state.copyWith(totalEmpleados: cantidadTotalEmpleadosPorHacienda));
    List<EmpleadoLocal> empleados = state.empleadoL;
    List<Hacienda> haciendas = state.haciendas;

    List<int> contadorEmpleadosActPorHacienda = [];

// Itera sobre cada hacienda.
    for (Hacienda hacienda in haciendas) {
      String idHacienda = hacienda.id;

      // Filtra los empleados por su hacienda.
      List<EmpleadoLocal> empleadosEnHacienda = empleados.where((empleado) {
        return empleado.hacienda_id == idHacienda;
      }).toList();

      // Filtra los empleados por el estado_contratacion "ACT".
      List<EmpleadoLocal> empleadosActEnHacienda =
          empleadosEnHacienda.where((empleado) {
        return empleado.estado_encuesta == "A";
      }).toList();

      // Obtiene la cantidad de empleados en "ACT" y agrégala a la lista.
      int cantidadEmpleadosAct = empleadosActEnHacienda.length;
      contadorEmpleadosActPorHacienda.add(cantidadEmpleadosAct);
    }

    print(
        "Contador de empleados en estado ACT por cada hacienda: $contadorEmpleadosActPorHacienda");
    emit(state.copyWith(porcentajeAceptados: contadorEmpleadosActPorHacienda));

    List<int> porcentajePorHacienda = [];

    for (int i = 0; i < cantidadTotalEmpleadosPorHacienda.length; i++) {
      int totalEmpleados = cantidadTotalEmpleadosPorHacienda[i];
      int empleadosFiltrados = contadorEmpleadosActPorHacienda[i];

      int porcentaje = ((empleadosFiltrados / totalEmpleados) * 100).round();
      porcentajePorHacienda.add(porcentaje);
    }
    print("Porcentaje por cada hacienda: $porcentajePorHacienda");
    emit(state.copyWith(porcentajeEmpleados: porcentajePorHacienda));
    for (int i = 0; i < porcentajePorHacienda.length; i++) {
      int porcentaje = porcentajePorHacienda[i];
      Hacienda hacienda = haciendass[i];

      print("Hacienda: ${hacienda.name}, Porcentaje: $porcentaje%");
    }

    for (int i = 0; i < contadorEmpleadosActPorHacienda.length; i++) {
      int empleadosAceptados = contadorEmpleadosActPorHacienda[i];
      Hacienda hacienda = haciendass[i];

      print(
          "Hacienda: ${hacienda.name}, Empleados Aceptados: $empleadosAceptados");
    }
  }

  void loadDataEncuesta() async {
    try {
      final response = await http.get(
        Uri.parse(
            //'https://10.35.3.11:10447/Entity/EncuestaES/api/es/encuesta'),
            'https://srbp01ap00.favoritafruit.corp:10447/Entity/EncuestaES/api/es/encuesta'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<Encuesta> encuestasFiltradas = [];
        final List<dynamic> jsonData = jsonDecode(response.body);
        print(jsonData);
        final List<Encuesta> encuestas =
            jsonData.map((data) => Encuesta.fromJson(data)).toList();
        final permisosselect = state.idsEncuestas;
        for (var id in permisosselect) {
          try {
            var encuestaFiltrada =
                encuestas.firstWhere((encuesta) => encuesta.id_encuesta == id);
            if (encuestaFiltrada != null) {
              encuestasFiltradas.add(encuestaFiltrada);
            }
            print(encuestaFiltrada);
          } catch (e) {
            print('error al filtrar haciendas de permisos: $e');
          }
        }

        await insertEncuestaToSQL(encuestasFiltradas);
        try {
          cargarEncuestaToSQL();
        } catch (e) {
          print('error al cargar encuestas por sqly metodo');
        }
      } else {
        throw Exception('Failed to load data from the API');
      }
    } catch (e) {
      // Maneja cualquier error que pueda ocurrir durante la carga de datos.
      print('Error EC: $e');
    }
  }

  Future<void> cargarEncuestaToSQL() async {
    try {
      final encuestasDesdeSQL = await getEncuestasFromSQL();
      if (encuestasDesdeSQL.isNotEmpty) {
        emit(state.copyWith(encuestas: encuestasDesdeSQL));
      }
      buscarIdPlantillas();
    } catch (e) {
      print('Error al cargar las encuestas desde la tabla SQL: $e');
    }
  }

  Future<void> insertEncuestaToSQL(List<Encuesta> encuestas) async {
    if (_database == null) {
      _database = await _openDatabase();
    }
    final batch = _database!.batch();
    for (Encuesta encuesta in encuestas) {
      final existingEncuesta = await _database!.query('Encuestas',
          where: 'id_encuesta = ?', whereArgs: [encuesta.id_encuesta]);
      if (existingEncuesta.isEmpty) {
        batch.insert('Encuestas', encuesta.toMap());
      }
    }
    await batch.commit();
  }

  Future<List<Encuesta>> getEncuestasFromSQL() async {
    if (_database == null) {
      _database = await _openDatabase();
    }
    final List<Map<String, dynamic>> results =
        await _database!.query('Encuestas');
    return results.map((map) => Encuesta.fromMap(map)).toList();
  }

  Future<void> uploadFiles(
      String id, String? imagePath, String? videoPath) async {
    final dio = Dio();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final formData = FormData();

    if (imagePath != null) {
      final imageFile = File(imagePath);
      var imageName = basename(imagePath);
      formData.files.add(MapEntry(
        'file',
        await MultipartFile.fromFile(imageFile.path, filename: imageName),
      ));
    }

    if (videoPath != null) {
      final videoFile = File(videoPath);
      var videoName = basename(videoPath);
      formData.files.add(MapEntry(
        'file',
        await MultipartFile.fromFile(videoFile.path, filename: videoName),
      ));
    }

    try {
      final response = await dio.post(
        //'https://10.35.3.11:10447/Utility/TransferenciaArchivoUS/api/us/transferenciaarchivo/upload/${id}',
        'https://srbp01ap00.favoritafruit.corp:10447/Utility/TransferenciaArchivoUS/api/us/transferenciaarchivo/upload/${id}', // Reemplaza con la URL de tu servidor
        data: formData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('Archivos enviados exitosamente');
      } else {
        print(
            'Error al enviar archivos. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<String> SendDataConsentimiento(
      ConsentimientoLocal consentimientoLocal) async {
    final url = Uri.parse(
        //'https://10.35.3.11:10447/Entity/RegistroConsentimientoES/api/es/registroconsentimiento');
        'https://srbp01ap00.favoritafruit.corp:10447/Entity/RegistroConsentimientoES/api/es/registroconsentimiento');
    final now = DateTime.now();
    final formattedDate = now.toUtc().toIso8601String();
    String? input = consentimientoLocal.hora;

// Define el patrón para buscar el valor de tiempo
    RegExp pattern = RegExp(r'\((.*?)\)');

// Busca el patrón en la cadena
    Match? match = pattern.firstMatch(input!);

    if (match != null) {
      // Obtiene la hora y la asigna a una variable
      timeOfDay = match.group(1)!;

      print('horaaa: ${timeOfDay}'); // Esto imprimirá "20:00"
    } else {
      print("No se encontró un valor de tiempo en el formato especificado.");
    }

    final Map<String, dynamic> data = {
      "id_persona": consentimientoLocal.idEmpleado,
      "id_encuesta": consentimientoLocal
          .id_emp_zona_hac, //trae el dato de id encuesta del shared preference
      "aceptado": true,
      "latitud": consentimientoLocal.lat,
      "longitud": consentimientoLocal.lon,
      "fecha": formattedDate,
      "hora": timeOfDay,
      "estado": 'S'
    };

    final jsonData = jsonEncode(data);
    print('data a enviar: $jsonData');

    try {
      print('este es el token 2 : $token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonData,
      );

      if (response.statusCode == 201) {
        print('Solicitud exitosa');
        final responseJson = json.decode(response.body);
        final String consentimientoId = responseJson;
        uploadFiles(consentimientoId.toString(), consentimientoLocal.pathIMG,
            consentimientoLocal.pathVIDEO);

        return consentimientoId.toString();
      } else {
        print('Error en la solicitud: ${response.statusCode}');
        print(response.body);
        return '';
      }
    } catch (e) {
      print('Error: $e');
    }
    return '';
  }
}

void _showRegistrePopup(BuildContext context, StepCounterCubit cubit) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        contentPadding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        content: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13), color: Colors.white),
            width: 70,
            height: 140,
            child: Stack(children: [
              Positioned(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      size: 40,
                      Icons.verified_outlined,
                      color: Color(0xff4147D5),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 15,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 5, bottom: 1, left: 5, right: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Dispositivo agregado',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1B478D),
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  'Ya se descargaron los servicios de hacienda.',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF1B478D),
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 30,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Color(0xFF1B478D),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, RouteList.login);

                              //_showLoginPopUp(context, cubit);
                            },
                            child: Text(
                              'Cerrar',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontFamily: 'Manrope'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ])),
      );
    },
  );
}

void _showUnRegistrePopup(BuildContext context) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        contentPadding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        content: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13), color: Colors.white),
            width: 70,
            height: 140,
            child: Stack(children: [
              Positioned(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      size: 40,
                      Icons.disabled_by_default_outlined,
                      color: Color(0xff4147D5),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 15,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 5, bottom: 1, left: 5, right: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Error a registrar dispositivo',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1B478D),
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  'Intente nuevamente o contacte con el soporte.',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF1B478D),
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 30,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Color(0xFF1B478D),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cerrar',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontFamily: 'Manrope'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ])),
      );
    },
  );
}

void _showWelcome(BuildContext context, StepCounterCubit cubit) {
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          contentPadding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          content: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13), color: Colors.white),
              width: 60,
              height: 190,
              child: Stack(children: [
                Positioned(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        size: 40,
                        Icons.waving_hand_outlined,
                        color: Color(0xFF1B478D),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5, bottom: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('Bienvenido',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.bold)),
                                /*   Text('dispositivo esta en el sistema',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.bold)), */
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8, left: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Text(
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                'Ya el sistema esta listo para funcionar correctamente.',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontFamily: 'Manrope'),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  //fixedSize: Size(80, 30),
                                  primary: Color(0xFF1B478D),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onPressed: () {
                                Navigator.pop(context);
                                context
                                    .read<StepCounterCubit>()
                                    .cargarEmpleadosDesdeSQL();
                                context
                                    .read<StepCounterCubit>()
                                    .cargarEmpleadosDesdeSQL();
                                context
                                    .read<StepCounterCubit>()
                                    .cargarEmpleadosDesdeSQL();

                                //_verify(cubit);
                              },
                              child: Text(
                                'Cerrar',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'Manrope'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ])),
        );
      });
}

void _showErrorLogin(BuildContext context, StepCounterCubit cubit) {
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          contentPadding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          content: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13), color: Colors.white),
              width: 60,
              height: 190,
              child: Stack(children: [
                Positioned(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        size: 40,
                        Icons.error_outline,
                        color: Color(0xFF1B478D),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5, bottom: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('No se pudo iniciar sesion',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.bold)),
                                /*   Text('dispositivo esta en el sistema',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.bold)), */
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8, left: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Text(
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                'Intenta mas tarde o comunicate con tu proveedor.',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontFamily: 'Manrope'),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  //fixedSize: Size(80, 30),
                                  primary: Color(0xFF1B478D),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onPressed: () {
                                Navigator.pop(context);
                                //Navigator.pop(context);
                              },
                              child: Text(
                                'Cerrar',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'Manrope'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ])),
        );
      });
}

void _showErrorLoginToken(BuildContext context, StepCounterCubit cubit) {
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          contentPadding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          content: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13), color: Colors.white),
              width: 60,
              height: 190,
              child: Stack(children: [
                Positioned(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        size: 40,
                        Icons.error_outline,
                        color: Color(0xFF1B478D),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5, bottom: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('No se pudo iniciar sesion',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.bold)),
                                /*   Text('dispositivo esta en el sistema',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.bold)), */
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8, left: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Text(
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                'Usuario y/o Contraseña incorrecta.',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontFamily: 'Manrope'),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  //fixedSize: Size(80, 30),
                                  primary: Color(0xFF1B478D),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Cerrar',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'Manrope'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ])),
        );
      });
}
