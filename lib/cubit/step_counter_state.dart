part of 'step_counter_cubit.dart';

class StepCounterState extends Equatable {
  final int nextStep;
  final BuildContext context;
  final Hacienda? selectedHacienda;
  final Empleado? selectedEmpleado;
  final List<Hacienda> haciendas;
  final List<Empleado> empleados;
  final List<Registro> registros;
  final List<Plantilla> plantilla;
  final List<Compania>? compania;
  final List<Dispositivo>? dispositivo;
  final List<EmpleadoLocal> empleadoL;
  final int dia;
  final String mes;
  final int anio;
  final TimeOfDay hora;
  final List<RespondeLogin>? responseLogin;
  final List<String> idsHaciendas;
  final List<int> idsEncuestas;
  final TextEditingController usuarioController;
  final TextEditingController claveController;
  final List<ConsentimientoLocal> consentimientoL;
  final List<Encuesta> encuestas;
  final List<Permiso> permisos;
  final String titulo;
  final String contenidoC;
  final String contenidoV;
  final String? estadoPlantilla;
  final List<int> porcentajeEmpleados;
  final List<int> porcentajeAceptados;
  final List<int> totalEmpleados;
  final Keys key;
  final List<String> respondeIds;
  final double? lat;
  final double? lon;

  StepCounterState({
    required this.nextStep,
    required this.encuestas,
    required this.permisos,
    required this.titulo,
    required this.contenidoC,
    required this.contenidoV,
    this.estadoPlantilla,
    required this.context,
    this.selectedHacienda,
    this.selectedEmpleado,
    required this.haciendas,
    required this.empleados,
    required this.registros,
    required this.plantilla,
    required this.empleadoL,
    this.compania,
    required this.dia,
    required this.mes,
    required this.anio,
    required this.hora,
    this.responseLogin,
    this.dispositivo,
    required this.idsHaciendas,
    required this.idsEncuestas,
    required this.usuarioController,
    required this.claveController,
    required this.consentimientoL,
    required this.porcentajeEmpleados,
    required this.totalEmpleados,
    required this.key,
    required this.porcentajeAceptados,
    required this.respondeIds,
    this.lat,
    this.lon,
  });

  factory StepCounterState.initial(BuildContext context) {
    return StepCounterState(
        key: Keys(
          token: '',
          keys: 'keys',
          expire: 0,
          iv: '',
        ),
        respondeIds: [],
        usuarioController: TextEditingController(),
        claveController: TextEditingController(),
        dia: 0,
        mes: '',
        anio: 0,
        hora: TimeOfDay(hour: 0, minute: 0),
        nextStep: 0,
        context: context,
        empleadoL: [],
        consentimientoL: [],
        dispositivo: [],
        compania: [],
        plantilla: [],
        porcentajeAceptados: [],
        haciendas: [],
        empleados: [],
        registros: [],
        idsHaciendas: [],
        idsEncuestas: [],
        porcentajeEmpleados: [],
        encuestas: [],
        permisos: [],
        totalEmpleados: [],
        titulo: '',
        contenidoC: '',
        contenidoV: '');
  }

  @override
  List<Object?> get props => [
        nextStep,
        context,
        selectedHacienda,
        selectedEmpleado,
        haciendas,
        empleados,
        registros,
        plantilla,
        compania,
        dispositivo,
        empleadoL,
        mes,
        anio,
        dia,
        hora,
        responseLogin,
        idsHaciendas,
        usuarioController,
        claveController,
        consentimientoL,
        encuestas,
        permisos,
        titulo,
        contenidoC,
        contenidoV,
        estadoPlantilla,
        idsEncuestas,
        porcentajeEmpleados,
        porcentajeAceptados,
        totalEmpleados,
        key,
        respondeIds,
        lat,
        lon
      ];

  StepCounterState copyWith(
      {int? nextStep,
      Hacienda? selectedHacienda,
      Empleado? selectedEmpleado,
      List<Plantilla>? plantilla,
      List<Hacienda>? haciendas,
      List<Empleado>? empleados,
      List<Compania>? compania,
      List<EmpleadoLocal>? empleadoL,
      List<Dispositivo>? dispositivo,
      DateTime? fecha,
      int? dia,
      String? mes,
      int? anio,
      TimeOfDay? hora,
      List<RespondeLogin>? responseLogin,
      List<Registro>? registros,
      List<String>? idsHaciendas,
      List<int>? idsEncuestas,
      List<ConsentimientoLocal>? consentimientoL,
      TextEditingController? usuarioController,
      TextEditingController? claveController,
      List<Encuesta>? encuestas,
      List<Permiso>? permisos,
      String? titulo,
      String? contenidoC,
      String? contenidoV,
      String? estadoPlantilla,
      List<int>? porcentajeEmpleados,
      List<int>? porcentajeAceptados,
      List<int>? totalEmpleados,
      Keys? key,
      List<String>? respondeIds,
      double? lat,
      double? lon}) {
    print('Vista actual');
    print(nextStep.toString());
    return StepCounterState(
        usuarioController: usuarioController ?? this.usuarioController,
        claveController: claveController ?? this.claveController,
        mes: mes ?? this.mes,
        anio: anio ?? this.anio,
        dia: dia ?? this.dia,
        hora: hora ?? this.hora,
        nextStep: nextStep ?? this.nextStep,
        context: context,
        consentimientoL: consentimientoL ?? this.consentimientoL,
        responseLogin: responseLogin ?? this.responseLogin,
        compania: compania ?? this.compania,
        plantilla: plantilla ?? this.plantilla,
        dispositivo: dispositivo ?? this.dispositivo,
        empleadoL: empleadoL ?? this.empleadoL,
        selectedHacienda: selectedHacienda ?? this.selectedHacienda,
        selectedEmpleado: selectedEmpleado ?? this.selectedEmpleado,
        registros: registros ?? this.registros,
        haciendas: haciendas ?? this.haciendas,
        empleados: empleados ?? this.empleados,
        idsHaciendas: idsHaciendas ?? this.idsHaciendas,
        encuestas: encuestas ?? this.encuestas,
        permisos: permisos ?? this.permisos,
        titulo: titulo ?? this.titulo,
        contenidoC: contenidoC ?? this.contenidoC,
        contenidoV: contenidoV ?? this.contenidoV,
        estadoPlantilla: estadoPlantilla ?? this.estadoPlantilla,
        idsEncuestas: idsEncuestas ?? this.idsEncuestas,
        porcentajeEmpleados: porcentajeEmpleados ?? this.porcentajeEmpleados,
        porcentajeAceptados: porcentajeAceptados ?? this.porcentajeAceptados,
        totalEmpleados: totalEmpleados ?? this.totalEmpleados,
        key: key ?? this.key,
        respondeIds: respondeIds ?? this.respondeIds,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon);
  }
}
