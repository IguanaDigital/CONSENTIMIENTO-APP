import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:consentimiento/cubit/connection_status_cubit.dart';
import 'package:consentimiento/cubit/step_counter_cubit.dart';
import 'package:consentimiento/presentation/screens/dashboard_screen.dart';
import 'package:consentimiento/utils/check_internet_connection.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:flutter/Material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

final NetworkInfo _networkInfo = NetworkInfo();
String? _currentAddress;
Position? _currentPosition;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    _loadDeviceInfo();
    _loadNetworkStatus();
    super.initState();
  }

  Future<void> _loadDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    setState(() {
      deviceId = androidInfo.model;
      nameDevice = androidInfo.id;
    });
  }

  _loadNetworkStatus() async {
    if (Platform.isAndroid) {
      print('Checking Android permissions');
      var status = await Permission.location.status;
      // Blocked?
      if (status.isRestricted || status.isDenied || status.isRestricted) {
        // Ask the user to unblock
        if (await Permission.location.request().isGranted) {
          // Either the permission was already granted before or the user just granted it.
          print('Location permission granted');
        } else {
          print('Location permission not granted');
        }
      } else {
        print('Permission already granted (previous execution?)');
      }
    }
    var connectivityResult = await (Connectivity().checkConnectivity());
    final wifiName = await _networkInfo.getWifiName();
    setState(() {
      networkStatus = wifiName.toString();
      print('-----------------');
      print(networkStatus);
      print(deviceId);
    });
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
    final ProgressDialog _progressDialog = ProgressDialog(
      context,
      isDismissible: true, // No se puede descartar mientras se muestra
    );
    final cubit = context.read<StepCounterCubit>();
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          Row(
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Color(0xff6EEB83).withOpacity(
                      0.4), // Puedes ajustar la opacidad y el color aquí
                  BlendMode.colorBurn,
                ),
                child: Container(
                    padding:
                        EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 1),
                    width: size.width / 2,
                    height: size.height,
                    child: Image.asset(
                      'assets/image/bananos.png',
                      /* width: size.width,
                      height: size.height, */
                    )),
              ),
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: size.width / 2, // Ancho deseado

                      child: Image.asset(
                        'assets/image/logo-reybanpac 1.png',
                        scale: 1,
                      ),
                    ),
                    Container(
                        width: size.width / 2 - 15, // Ancho deseado
                        height: size.height / 3,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8, left: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              /* const Padding(
                                padding: EdgeInsets.only(left: 40),
                                child: Row(
                                  children: [
                                    Text(
                                      'Usuario',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF695C5C),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 14,
                              ),
                              Container(
                                height: MediaQuery.of(context).size.height / 24,
                                width:
                                    MediaQuery.of(context).size.width / 2 + 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFFF4F4F4),
                                  border: Border.all(
                                      color: const Color(
                                          0x66898989)), // Puedes personalizar el borde
                                ),
                                child: TextField(
                                  controller: context
                                      .read<StepCounterCubit>()
                                      .state
                                      .usuarioController,
                                  decoration: const InputDecoration(
                                    hintText: 'Ingresar usuario',
                                    hintStyle: TextStyle(
                                        color: Color(0xFFCDD1E0),
                                        fontFamily: 'Manrope',
                                        fontSize: 13),
                                    border: InputBorder
                                        .none, // Elimina el borde del TextField
                                    contentPadding: EdgeInsets.all(
                                        12.5), // Añade relleno para el texto
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 25,
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 40),
                                child: Row(
                                  children: [
                                    Text(
                                      'Contraseña',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF695C5C),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 14,
                              ),
                              Container(
                                height: MediaQuery.of(context).size.height / 24,
                                width:
                                    MediaQuery.of(context).size.width / 2 + 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFFF4F4F4),
                                  border: Border.all(
                                      color: const Color(
                                          0x66898989)), // Puedes personalizar el borde
                                ),
                                child: TextField(
                                  obscureText: true,
                                  controller: context
                                      .read<StepCounterCubit>()
                                      .state
                                      .claveController,
                                  decoration: const InputDecoration(
                                    hintText: 'Ingresar contraseña',
                                    hintStyle: TextStyle(
                                        color: Color(0xFFCDD1E0),
                                        fontFamily: 'Manrope',
                                        fontSize: 13),
                                    border: InputBorder
                                        .none, // Elimina el borde del TextField
                                    contentPadding: EdgeInsets.all(
                                        12.5), // Añade relleno para el texto
                                  ),
                                ),
                              ), */
                              SizedBox(
                                height: 80,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    BlocBuilder<ConnectionStatusCubit,
                                        ConnectionStatus>(
                                      builder: (context, status) {
                                        return ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              //fixedSize: Size(80, 30),
                                              primary: Color(0xFF1B478D),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8))),
                                          onPressed: () async {
                                            _getCurrentPosition();
                                            print(
                                                'coordenadas: ${_currentPosition?.latitude} y de lon: ${_currentPosition?.longitude}');
                                            if (status !=
                                                ConnectionStatus.online) {
                                              print('no hay net 2.0');
                                              _showInvalidCompletePopup(
                                                  context, cubit);
                                            } else {
                                              _progressDialog.show();
                                              String usuario =
                                                  usuarioController.text;
                                              String clave =
                                                  claveController.text;
                                              String nameUser = context
                                                  .read<StepCounterCubit>()
                                                  .state
                                                  .usuarioController
                                                  .text;
                                              String namePassword = context
                                                  .read<StepCounterCubit>()
                                                  .state
                                                  .claveController
                                                  .text;

                                              print(deviceId);

                                              cubit.signIn(usuario, clave,
                                                  context, cubit);
                                              SharedPreferences prefs =
                                                  await SharedPreferences
                                                      .getInstance();
                                              //prefs.setBool('isLoggedIn', true);
                                              await prefs.setString(
                                                  'userName', nameUser);
                                              int loginTime = DateTime.now()
                                                      .millisecondsSinceEpoch ~/
                                                  1000;
                                              prefs.setInt(
                                                  'loginTime', loginTime);
                                              context
                                                  .read<StepCounterCubit>()
                                                  .state
                                                  .usuarioController
                                                  .clear();

                                              context
                                                  .read<StepCounterCubit>()
                                                  .state
                                                  .claveController
                                                  .clear();

                                              _progressDialog.hide();
                                              print('hay net 2.0');
                                            }
                                          },
                                          child: Text(
                                            'INGRESAR',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 9.5,
                                                fontFamily: 'Manrope'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ))
                  ],
                ),
              )
            ],
          )
        ]),
      ),
    );
  }
}

void _showInvalidCompletePopup(BuildContext context, StepCounterCubit cubit) {
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
            width: 100,
            height: 220,
            child: Stack(children: [
              Positioned(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 45,
                      color: Color(0xFF1B478D),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              'Se ha producido un error',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.bold)),
                          Text(' no hay conexion a internt',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          'Intenta enviarlo cuando tengas conexion a internet.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.normal)),
                    ),
                    SizedBox(
                      height: 40,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            height: 50,
                            child: ElevatedButton(
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
                                    fontSize: 9.5,
                                    fontFamily: 'Manrope'),
                              ),
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
