import 'dart:io';

import 'package:consentimiento/config/model/model.dart';
import 'package:consentimiento/cubit/connection_status_cubit.dart';
import 'package:consentimiento/cubit/step_counter_cubit.dart';
import 'package:consentimiento/config/route_list.dart';
import 'package:consentimiento/presentation/screens/about.dart';
import 'package:consentimiento/presentation/screens/consentimiento_screen.dart';
import 'package:consentimiento/presentation/screens/dashboard_screen.dart';
import 'package:consentimiento/presentation/screens/login_screen.dart';
import 'package:consentimiento/presentation/screens/manag_data_screen.dart';
import 'package:consentimiento/presentation/screens/verifiy_screen.dart';
import 'package:consentimiento/utils/check_internet_connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

String deviceId = 'Cargando...';
String networkStatus = 'Cargando...';
String nameDevice = 'Cargando';
final NetworkInfo _networkInfo = NetworkInfo();
final internetChecker = CheckInternetConnection();
Hacienda? selectedHacienda;
int idEncuestaSP2 = 0;

void main() async {
  HttpOverrides.global = MyHttpOverrides(); // Configura la validación SSL
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  final logFile = await _setupLogger();
  final logger = Logger(
    printer: PrettyPrinter(),
    output: FileOutput(file: logFile),
  );

  runApp(
    MultiBlocProvider(
        providers: [
          BlocProvider<ConnectionStatusCubit>(
              create: (context) => ConnectionStatusCubit()),
          BlocProvider(create: (context) {
            return StepCounterCubit(context);
          }),
        ],
        child: MyApp(
          logger: logger,
          isLoggedIn: isLoggedIn,
        )),
  );
}

Future<File> _setupLogger() async {
  final directory = await getApplicationDocumentsDirectory();
  final logFile = File('${directory.path}/app.log'); // Nombre del archivo
  return logFile;
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final Logger logger;
  const MyApp({super.key, required this.isLoggedIn, required this.logger});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    _handleLocationPermission();
    context.read<StepCounterCubit>().loadDataDispositivo();
    context.read<StepCounterCubit>().loadConsentimientoLocalData();
    context.read<StepCounterCubit>().cargarHaciendasDesdeSQL();
    context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
    context.read<StepCounterCubit>().cargarKeysDesdeSQL();
    context.read<StepCounterCubit>().cargarPlantillaDesdeSQL();
    context.read<StepCounterCubit>().cargarEncuestaToSQL();
    context.read<StepCounterCubit>().cargarCompaniasDesdeSQL();
    context.read<StepCounterCubit>().buscarIdPlantillas();
    context.read<StepCounterCubit>().actualizarFecha();
    context.read<StepCounterCubit>().contadorEmpleadosAceptados();
    demo();
    widget.logger.d('Log message with 2 methods');

    widget.logger.i('Info message');

    widget.logger.w('Just a warning!');

    widget.logger.e('Error! Something bad happened', error: 'Test Error');

    widget.logger.t({'key': 5, 'value': 'something'});
    super.initState();

    checkSessionExpiry();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> checkSessionExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    context.read<StepCounterCubit>().cargarKeysDesdeSQL();
    //final expire = context.read<StepCounterCubit>().state.key.expire;
    final expire = prefs.getInt('expire');
    print('el tiempo en minuto a expirar: $expire');

    final loginTime = prefs.getInt('loginTime');

    if (loginTime != null) {
      final currentTime = DateTime.now();
      final difference = currentTime
          .difference(DateTime.fromMillisecondsSinceEpoch(loginTime));
      final minutesPassed = difference.inMinutes;

      if (minutesPassed >= expire!) {
        print('expiro sesion');
        // El tiempo de sesión ha expirado, cierra la sesión
        prefs.setBool(
            'isLoggedIn', false); // Marca al usuario como desconectado
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) =>
                LoginScreen())); // Redirige a la pantalla de inicio de sesión
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006AB2)),
        useMaterial3: true,
      ),

      initialRoute: widget.isLoggedIn ? RouteList.dashboard : RouteList.verify,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case (RouteList.consentimiento):
            return MaterialPageRoute(
                builder: (_) => const ConsentimientoScreen());
          case (RouteList.dashboard):
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case (RouteList.management_data):
            return MaterialPageRoute(
                builder: (_) => const ManagementDataScreen());
          case (RouteList.verify):
            return MaterialPageRoute(builder: (_) => VerifyScreen());
          case (RouteList.login):
            return MaterialPageRoute(builder: (_) => LoginScreen());
          case (RouteList.about):
            return MaterialPageRoute(builder: (_) => About());
          default:
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
        }
      },
      //home: LocationPage(),
      home: const DashboardScreen(),
    );
  }
}

var logger = Logger(
  printer: PrettyPrinter(),
);

var loggerNoStack = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

void demo() {
  logger.d('Log message with 2 methods');

  loggerNoStack.i('Info message');

  loggerNoStack.w('Just a warning!');

  logger.e('Error! Something bad happened', error: 'Test Error');

  loggerNoStack.t({'key': 5, 'value': 'something'});

  Logger(printer: SimplePrinter(colors: true)).t('boom');
}

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String? _currentAddress;
  Position? _currentPosition;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Page")),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('LAT: ${_currentPosition?.latitude ?? ""}'),
              Text('LNG: ${_currentPosition?.longitude ?? ""}'),
              Text('ADDRESS: ${_currentAddress ?? ""}'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _getCurrentPosition,
                child: const Text("Get Current Location"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
