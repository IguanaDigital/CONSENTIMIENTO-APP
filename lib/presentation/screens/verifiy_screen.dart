import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:consentimiento/config/model/model.dart';
import 'package:consentimiento/config/route_list.dart';
import 'package:consentimiento/cubit/connection_status_cubit.dart';
import 'package:consentimiento/cubit/step_counter_cubit.dart';
import 'package:consentimiento/main.dart';
import 'package:consentimiento/presentation/widgets/warning_widget.dart';
import 'package:consentimiento/utils/check_internet_connection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/Material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

bool verificado_msg_yes = false;
bool verificado_msg_no = false;
bool ocultar_msg_one = false;
final NetworkInfo _networkInfo = NetworkInfo();
String? _currentAddress;
Position? _currentPosition;

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _loadNetworkStatus();
    ocultar_msg_one = true;
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

  void _verify(StepCounterCubit cubit) {
    final dispositivos = context.read<StepCounterCubit>().state.dispositivo!;
    bool seEncontroCoincidencia = false;

    for (var dispositivo in dispositivos) {
      if (dispositivo.identificador == deviceId) {
        // Encuentras una coincidencia, dispositivo.identificador es igual a cadenaDeseada
        print("Coincidencia encontrada: ${dispositivo.identificador}");
        seEncontroCoincidencia = true;
      }
    }

    if (seEncontroCoincidencia) {
      // Se encontró al menos una coincidencia
      print("Se encontró al menos una coincidencia.");
      setState(() {
        verificado_msg_yes = true;
        //ocultar_msg_one = true;
      });
      // _showLoginPopUp(context, cubit);
    } else {
      setState(() {
        verificado_msg_no = true;
        //ocultar_msg_one = true;
      });
      // No se encontraron coincidencias
      print("No Se encontró ninguna coincidencia.");
    }
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

  void _showThirdSendDataAPIPopup(BuildContext context) {
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
              width: 60,
              height: 170,
              child: Stack(children: [
                Positioned(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('La siguiente información se enviará',
                                    style: TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 11,
                                        color: Color(0xFF1B478D),
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    'al sistema administrador para el registro.',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF1B478D),
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Red Wifi: ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 9.5,
                                        fontFamily: 'Manrope'),
                                  ),
                                  Text(
                                    networkStatus,
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                        fontSize: 9.5,
                                        fontFamily: 'Manrope'),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Código: ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 9.5,
                                        fontFamily: 'Manrope'),
                                  ),
                                  Text(
                                    deviceId,
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                        fontSize: 9.5,
                                        fontFamily: 'Manrope'),
                                  ),
                                  Text(
                                    nameDevice,
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                        fontSize: 9.5,
                                        fontFamily: 'Manrope'),
                                  ),
                                ],
                              )
                            ],
                          )
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
                                  //fixedSize: Size(80, 30),
                                  primary: Color(0xFF1B478D),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onPressed: () {
                                //

                                context
                                    .read<StepCounterCubit>()
                                    .SendDataDispositivo(deviceId, nameDevice,
                                        context, networkStatus);
                              },
                              child: Text(
                                'Aceptar',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontFamily: 'Manrope'),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  //fixedSize: Size(80, 30),
                                  primary: Color(0xFFDFE4EB),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
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

  @override
  Widget build(BuildContext context) {
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
              Visibility(
                visible: ocultar_msg_one == true,
                child: Container(
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
                      SizedBox(
                        height: 60,
                      ),
                      Container(
                        width: size.width / 2 - 14, // Ancho deseado
                        height: size.height / 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                                textAlign: TextAlign.center,
                                'Debes verificar si el dispositivo esta en el sistema',
                                style: TextStyle(
                                    height: 1.2,
                                    fontSize: 16,
                                    color: Color(0xFF207DBC),
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold)),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              textAlign: TextAlign.center,
                              'Por favor verifica el dispositivo para continuar.',
                              style: TextStyle(
                                  color: Color(0xFF207DBC).withOpacity(0.9),
                                  fontSize: 11,
                                  fontFamily: 'Manrope'),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              height: 30,
                              child: IgnorePointer(
                                ignoring:
                                    verificado_msg_yes || verificado_msg_no,
                                child: BlocBuilder<ConnectionStatusCubit,
                                    ConnectionStatus>(
                                  builder: (context, status) {
                                    return ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          //fixedSize: Size(80, 30),
                                          primary: verificado_msg_yes ||
                                                  verificado_msg_no
                                              ? Colors.grey.shade300
                                              : Color(0xFF1B478D),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8))),
                                      onPressed: () {
                                        if (status != ConnectionStatus.online) {
                                          _showInvalidVerifyPopup(
                                              context, cubit);
                                        } else {
                                          _verify(cubit);
                                        }
                                      },
                                      child: Text(
                                        'Verificar',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontFamily: 'Manrope'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 60,
                            ),
                            Visibility(
                                visible: verificado_msg_yes == true,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Column(
                                    children: [
                                      Text(
                                        textAlign: TextAlign.center,
                                        'El dispositivo ya se verifico correctamente, puede acceder a Iniciar Sesión',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            height: 1.2,
                                            color: Colors.green.shade300,
                                            fontFamily: 'Manrope',
                                            fontSize: 16),
                                      ),
                                      SizedBox(
                                        height: 20,
                                      ),
                                      SizedBox(
                                        height: 30,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              //fixedSize: Size(80, 30),
                                              primary: Color(0xFF1B478D),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8))),
                                          onPressed: () {
                                            Navigator.pushReplacementNamed(
                                                context, RouteList.login);
                                          },
                                          child: Text(
                                            'Continuar',
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
                                )),
                            Visibility(
                                visible: verificado_msg_no == true,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 25),
                                  child: Column(
                                    children: [
                                      Text(
                                        textAlign: TextAlign.center,
                                        'El dispositivo no esta registrado',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            height: 1,
                                            color: Colors.red,
                                            fontFamily: 'Manrope',
                                            fontSize: 11),
                                      ),
                                      SizedBox(height: 10),
                                      SizedBox(
                                        height: 30,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              //fixedSize: Size(80, 30),
                                              primary: Color(0xFF1B478D),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8))),
                                          onPressed: () {
                                            _showThirdSendDataAPIPopup(context);
                                          },
                                          child: Text(
                                            'Registrar Dispositivo',
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
                                ))
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          )
        ]),
      ),
    );
  }
}

void _showInvalidVerifyPopup(BuildContext context, StepCounterCubit cubit) {
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
