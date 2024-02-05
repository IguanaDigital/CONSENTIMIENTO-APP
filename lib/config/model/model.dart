import 'dart:convert';

class Hacienda {
  final String id;
  final String name;
  final int aban8;
  final String? estado;

  Hacienda({
    required this.id,
    required this.name,
    required this.aban8,
    this.estado,
  });

  factory Hacienda.fromJson(Map<String, dynamic> json) {
    return Hacienda(
        id: json['id'],
        name: json['nombre'],
        aban8: json['aban8'],
        estado: json['estado']);
  }

  factory Hacienda.fromMap(Map<String, dynamic> map) {
    return Hacienda(
        id: map['id_hacienda'],
        name: map['name'],
        aban8: map['aban8'],
        estado: map['estado']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id_hacienda': id,
      'name': name,
      'aban8': aban8,
      'estado': estado,
    };
  }
}

class Dispositivo {
  final int id;
  final String identificador;
  final String nombre;
  final String estado;

  Dispositivo(
      {required this.id,
      required this.identificador,
      required this.estado,
      required this.nombre});

  factory Dispositivo.fromJson(Map<String, dynamic> json) {
    return Dispositivo(
        id: json['id'],
        identificador: json['identificador'],
        estado: json['estado'],
        nombre: json['nombre']);
  }
}

class Plantilla {
  final int id;
  final String titulo;
  final String contenidoC;
  final String contenidoV;
  final String estado;

  Plantilla(
      {required this.id,
      required this.titulo,
      required this.contenidoC,
      required this.contenidoV,
      required this.estado});

  factory Plantilla.fromJson(Map<String, dynamic> json) {
    return Plantilla(
        id: json['id'],
        titulo: json['titulo'],
        contenidoC: json['contenido'],
        contenidoV: json['contenido_video'],
        estado: json['estado'].toString());
  }

  factory Plantilla.fromMap(Map<String, dynamic> map) {
    return Plantilla(
      id: map['id_plantilla'],
      titulo: map['titulo'],
      contenidoC: map['contenidoC'],
      contenidoV: map['contenidoV'],
      estado: map['estado'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_plantilla': id,
      'titulo': titulo,
      'contenidoC': contenidoC,
      'contenidoV': contenidoV,
      'estado': estado
    };
  }
}

class Empleado {
  final int id;
  String name;
  String cedula;
  final String haciendaId;
  final String estado_encuesta;
  String empresa;
  final String id_zona;

  Empleado(
      {required this.id,
      required this.name,
      required this.haciendaId,
      required this.empresa,
      required this.cedula,
      required this.id_zona,
      required this.estado_encuesta});

  factory Empleado.fromJson(Map<String, dynamic> json) {
    final cedulaDecoded = utf8.decode(base64.decode(json['cedula']));
    final nombreDecoded = utf8.decode(base64.decode(json['nombre']));
    return Empleado(
        id: json['id'],
        name: nombreDecoded,
        haciendaId: json['id_hacienda'],
        empresa: json['id_empresa'],
        cedula: cedulaDecoded,
        estado_encuesta: json['estado'],
        id_zona: json['id_zona']);
  }
//aca no se crea el id
  Map<String, dynamic> toMap() {
    return {
      'id_empleado': id,
      'name': name,
      'cedula': cedula,
      'empresa': empresa,
      'hacienda_id': haciendaId,
      'estado': estado_encuesta,
      'id_zona': id_zona,
    };
  }

  factory Empleado.fromMap(Map<String, dynamic> map) {
    return Empleado(
        id: map['id_empleado'],
        name: map['name'],
        cedula: map['cedula'],
        empresa: map['empresa'],
        haciendaId: map['hacienda_id'],
        estado_encuesta: map['estado'],
        id_zona: map['id_zona']);
  }

  Empleado copyWithEstadoContratacion(String nuevoEstado, String nuevaFecha) {
    return Empleado(
        id: id,
        name: name,
        haciendaId: haciendaId,
        estado_encuesta: nuevoEstado,
        empresa: empresa,
        cedula: cedula,
        id_zona: id_zona);
  }
}

class EmpleadoLocal {
  final int id;
  final String name;
  final String cedula;
  final String empresa;
  final String estado_encuesta;
  final String hacienda_id;
  final String id_zona;
  bool seleccionado;

  EmpleadoLocal(
      {required this.id,
      required this.name,
      required this.cedula,
      required this.empresa,
      this.seleccionado = false,
      required this.hacienda_id,
      required this.estado_encuesta,
      required this.id_zona});

  factory EmpleadoLocal.fromMap(Map<String, dynamic> map) {
    return EmpleadoLocal(
        id: map['id_empleado'],
        name: map['name'],
        cedula: map['cedula'],
        empresa: map['empresa'],
        hacienda_id: map['hacienda_id'],
        estado_encuesta: map['estado'],
        id_zona: map['id_zona']);
  }
}

class Compania {
  final String id;
  final String nombre;
  final String? logo;
  final String? color_bg;
  final String? color_fg;
  final String? estado;

  Compania(
      {required this.id,
      required this.nombre,
      this.logo,
      this.color_bg,
      this.color_fg,
      this.estado});

  factory Compania.fromJson(Map<String, dynamic> json) {
    return Compania(
        id: json['id'] ?? '',
        nombre: json['nombre'] ?? '',
        logo: json['logo'] ?? '',
        color_bg: json['color_bg'],
        color_fg: json['color_fg'],
        estado: json['estado']);
  }

  Map<String, dynamic> toMap() {
    return {'id_compania': id, 'nombre': nombre, 'logo': logo};
  }

  factory Compania.fromMap(Map<String, dynamic> map) {
    return Compania(
        id: map['id_compania'], nombre: map['nombre'], logo: map['logo']);
  }
}

class Registro {
  final String nombre;
  final String grupo;
  bool seleccionado;

  Registro(
      {required this.nombre, required this.grupo, this.seleccionado = false});
}

class Consentimiento {
  final int? id;
  final int idEmpleado;
  final int? id_emp_zona_hac;
  final String? fecha;
  final String? hora;
  final String? estadoContratacion;
  final bool? aceptado;
  final double? lat;
  final double? lon;
  final String? pathIMG;
  final String? pathVIDEO;

  Consentimiento(
      {this.id,
      required this.idEmpleado,
      this.fecha,
      this.hora,
      this.id_emp_zona_hac,
      required this.estadoContratacion,
      this.aceptado,
      this.lat,
      this.pathIMG,
      this.pathVIDEO,
      this.lon});

  ///no se si lo usare
  /*  factory Consentimiento.fromJson(Map<String, dynamic> json) {
    return Consentimiento(
        id: json['Id'],
        idEmpleado: json['IdEmpleado'],
        fecha: json['Fecha'],
        hora: json['Hora'],
        estadoContratacion: json['EstadoContratacion'],
        aceptado: json['Aceptado']);
  }
  //es un to map
  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'IdEmpleado': idEmpleado,
      'Fecha': fecha,
      'Hora': hora,
      'EstadoContratacion': estadoContratacion,
      'Aceptado': aceptado,
    };
  } */

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_empleado': idEmpleado,
      'id_emp_zona_hac': id_emp_zona_hac,
      'fecha': fecha,
      'hora': hora,
      'estado_contratacion': estadoContratacion,
      'aceptado': aceptado,
      'lat': lat,
      'lon': lon,
      'path_img': pathIMG,
      'path_video': pathVIDEO
    };
  }

  factory Consentimiento.fromMap(Map<String, dynamic> map) {
    return Consentimiento(
        id: map['id'],
        idEmpleado: map['id_empleado'],
        estadoContratacion: map['estado_contratacion'],
        aceptado: map['aceptado'],
        fecha: map['fecha'],
        hora: map['hora'],
        lat: map['lat'],
        lon: map['lon'],
        pathIMG: map['path_img'],
        pathVIDEO: map['path_video'],
        id_emp_zona_hac: map['id_emp_zona_hac']);
  }

  Consentimiento copyWithConsentimiento() {
    return Consentimiento(
        id: id,
        idEmpleado: idEmpleado,
        estadoContratacion: estadoContratacion,
        aceptado: aceptado,
        fecha: fecha,
        hora: hora,
        lat: lat,
        lon: lon,
        pathIMG: pathIMG,
        pathVIDEO: pathVIDEO,
        id_emp_zona_hac: id_emp_zona_hac);
  }
}

class RespondeLogin {
  final String token;
  final List<Permiso> permisos;

  RespondeLogin({required this.token, required this.permisos});

  factory RespondeLogin.fromJson(Map<String, dynamic> json) {
    final List<dynamic> permisosList = json['permisos'];
    final List<Permiso> permisos =
        permisosList.map((data) => Permiso.fromJson(data)).toList();

    return RespondeLogin(
      token: json['token'],
      permisos: permisos,
    );
  }
}

class Permiso {
  final int id_permiso;
  final String idHacienda;
  final int idDispositivo;
  final int idEncuesta;

  final String estado;

  Permiso({
    required this.id_permiso,
    required this.idHacienda,
    required this.idDispositivo,
    required this.idEncuesta,
    required this.estado,
  });

  factory Permiso.fromJson(Map<String, dynamic> json) {
    return Permiso(
        idHacienda: json['id_hacienda'],
        idDispositivo: json['id_dispositivo'],
        idEncuesta: json['id_encuesta'],
        estado: json['estado'],
        id_permiso: json['id']);
  }
}

class ConsentimientoLocal {
  final int? id;
  final int idEmpleado;
  final int? id_emp_zona_hac;
  final DateTime? fecha;
  final String? hora;
  final String? estadoContratacion;
  final String? aceptado;
  final double? lat;
  final double? lon;
  final String? pathIMG;
  final String? pathVIDEO;
  bool seleccionado;

  ConsentimientoLocal(
      {this.id,
      required this.idEmpleado,
      this.fecha,
      this.hora,
      this.id_emp_zona_hac,
      required this.estadoContratacion,
      this.aceptado,
      this.lat,
      this.seleccionado = false,
      this.pathIMG,
      this.pathVIDEO,
      this.lon});

  ///no se si lo usare
  factory ConsentimientoLocal.fromJson(Map<String, dynamic> json) {
    return ConsentimientoLocal(
        id: json['Id'],
        idEmpleado: json['IdEmpleado'],
        fecha: DateTime.parse(json['Fecha']),
        hora: json['Hora'],
        estadoContratacion: json['EstadoContratacion'],
        aceptado: json['Aceptado'].toString());
  }
  //es un to map
  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'IdEmpleado': idEmpleado,
      'Fecha': fecha,
      'Hora': hora,
      'EstadoContratacion': estadoContratacion,
      'Aceptado': aceptado,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_empleado': idEmpleado,
      'id_emp_zona_hac': id_emp_zona_hac,
      'fecha': fecha,
      'hora': hora,
      'estado_contratacion': estadoContratacion,
      'aceptado': aceptado,
      'lat': lat,
      'lon': lon,
      'path_img': pathIMG,
      'path_video': pathVIDEO
    };
  }

  factory ConsentimientoLocal.fromMap(Map<String, dynamic> map) {
    return ConsentimientoLocal(
        id: map['id'],
        idEmpleado: map['id_empleado'],
        estadoContratacion: map['estado_contratacion'],
        aceptado: map['aceptado'],
        fecha: (map['fecha'] != null) ? DateTime.parse(map['fecha']) : null,
        hora: map['hora'],
        lat: map['lat'],
        lon: map['lon'],
        pathIMG: map['path_img'],
        pathVIDEO: map['path_video'],
        id_emp_zona_hac: map['id_emp_zona_hac']);
  }

  ConsentimientoLocal copyWithConsentimientoLocal() {
    return ConsentimientoLocal(
        id: id,
        idEmpleado: idEmpleado,
        estadoContratacion: estadoContratacion,
        aceptado: aceptado,
        fecha: fecha,
        hora: hora,
        lat: lat,
        lon: lon,
        pathIMG: pathIMG,
        pathVIDEO: pathVIDEO,
        id_emp_zona_hac: id_emp_zona_hac);
  }
}

class Encuesta {
  final int id_encuesta;
  final int id_plantilla;
  final int id_tipo_compania;
  final String nombre;
  final bool? habilitar_noaceptar;
  final String fecha_inicio;
  final String fecha_fin;
  final String estado;

  Encuesta({
    required this.id_encuesta,
    required this.id_plantilla,
    required this.estado,
    required this.id_tipo_compania,
    required this.nombre,
    this.habilitar_noaceptar,
    required this.fecha_inicio,
    required this.fecha_fin,
  });
//recibe de la api
  factory Encuesta.fromJson(Map<String, dynamic> json) {
    return Encuesta(
        id_encuesta: json['id'],
        id_plantilla: json['id_plantilla'],
        id_tipo_compania: json['id_tipo_campania'],
        nombre: json['nombre'],
        habilitar_noaceptar: json['habilitar_noaceptar'],
        fecha_inicio: json['fecha_inicio'],
        fecha_fin: json['fecha_fin'],
        estado: json['estado']);
  }
//recibe de la tabla
  factory Encuesta.fromMap(Map<String, dynamic> map) {
    return Encuesta(
        id_encuesta: map['id_encuesta'],
        id_plantilla: map['id_plantilla'],
        id_tipo_compania: map['id_tipo_compania'],
        nombre: map['nombre'],
        fecha_inicio: map['fecha_inicio'],
        fecha_fin: map['fecha_fin'],
        estado: map['estado']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id_encuesta': id_encuesta,
      'id_plantilla': id_plantilla,
      'id_tipo_compania': id_tipo_compania,
      'nombre': nombre,
      'fecha_inicio': fecha_inicio,
      'fecha_fin': fecha_fin,
      'estado': estado
    };
  }
}

class Keys {
  final String token;
  String keys;
  String iv;
  final int expire;

  Keys({
    required this.token,
    required this.keys,
    required this.expire,
    required this.iv,
  });

  factory Keys.fromJson(Map<String, dynamic> json) {
    return Keys(
        token: json['token'],
        keys: json['key'],
        expire: json['expires'],
        iv: json['iv']);
  }

  Map<String, dynamic> toMap() {
    return {'token': token, 'key': keys, 'expire': expire, 'iv': iv};
  }

  factory Keys.fromMap(Map<String, dynamic> map) {
    return Keys(
        token: map['token'],
        keys: map['key'],
        expire: map['expire'],
        iv: map['iv']);
  }
}
