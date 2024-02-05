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
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<double> _valueNotifier = ValueNotifier(0);
ValueNotifier<double> porcentajeNotifier = ValueNotifier<double>(0.0);
ValueNotifier<int> totalNotifier = ValueNotifier<int>(0);
ValueNotifier<int> aceptadosNotifier = ValueNotifier<int>(0);
ValueNotifier<int> noAceptadosNotifier = ValueNotifier<int>(0);

List<ValueNotifier<double>> _valueNotifiers = [];

final NetworkInfo _networkInfo = NetworkInfo();
final TextEditingController usuarioController = TextEditingController();
final TextEditingController claveController = TextEditingController();

String userName = '';
String deviceId = 'Cargando...';
String nameDevice = 'Cargando';
String networkStatus = 'Cargando...';

String identificadorAPI = '';
int porcentaje = 0;
Hacienda? hacienda;
Hacienda? selectedHacienda1;

int newPorcentaje = 0;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  GlobalKey<SliderDrawerState> _key = GlobalKey<SliderDrawerState>();
  @override
  initState() {
    context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
    context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
    context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
    selectedHacienda1 =
        context.read<StepCounterCubit>().state.haciendas.isNotEmpty
            ? context.read<StepCounterCubit>().state.haciendas[0]
            : null;

    context.read<StepCounterCubit>().actualizarFecha();
    loadNameFromSharedPreferences();
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
      context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
      context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
    });
    _loadDeviceInfo();
    _loadNetworkStatus();
    // Los nuevos valores

// Asegúrate de que haya suficientes valores en la lista de ValueNotifiers

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<StepCounterCubit>();
      context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
      context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
      context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
    });
  }

  Future<void> loadNameFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool('isLoggedIn', true);
      userName = prefs.getString('userName') ?? '';
      idEncuestaSP2 = prefs.getInt('idEncuestaSP')!;
    });
  }

  void _showPlantillaEmptyPopup(BuildContext context, StepCounterCubit cubit) {
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
                        Icons.warning_amber_rounded,
                        size: 45,
                        color: Color(0xFF1B478D),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                'La plantilla esta vacia',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold)),
                            /* Text(' los consentimientos.',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold)) ,*/
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            'Comunicate con tu administrador para que te asigne una plantilla.',
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
                                        borderRadius:
                                            BorderRadius.circular(8))),
                                onPressed: () {
                                  Navigator.pop(context);
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

  void _showSecondRegisterPopup(BuildContext context) {
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
                          Image.asset(
                            'assets/icons/alert.png',
                            width: 30,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 5, bottom: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('El equipo no se encuentra',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.bold)),
                                Text('registrado en el sistema',
                                    style: TextStyle(
                                        color: Colors.black,
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
                          Text(
                            'Por favor registra el dispositivo para continuar.',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 9.5,
                                fontFamily: 'Manrope'),
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
                                Navigator.pop(context);
                                _showThirdSendDataAPIPopup(context);
                                //_showMessageConfirm(context, cubit);
                              },
                              child: Text(
                                'Registrar',
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

                                //_showMessageConfirm(context, cubit);
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
                                _showThirdPopup(context);
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

  void _showThirdPopup(BuildContext context) {
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
              height: 100,
              child: Stack(children: [
                Positioned(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            size: 40,
                            Icons.warning_amber_rounded,
                            color: Color(0xff4147D5),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 5, bottom: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('¿Está seguro de salir del sistema?',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1B478D),
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.bold)),
                                Text('Se perderá lo avanzado.',
                                    style: TextStyle(
                                        fontSize: 12,
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
                                  //fixedSize: Size(80, 30),
                                  primary: Color(0xFF1B478D),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onPressed: () {
                                Navigator.pop(context);
                                //_showSecondPopup(context);
                                //_showMessageConfirm(context, cubit);
                              },
                              child: Text(
                                'NO',
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
                                /*  Navigator.pop(context); */

                                //_showMessageConfirm(context, cubit);
                              },
                              child: Text(
                                'SI',
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

  void _showCompletePopup(BuildContext context, StepCounterCubit cubit) {
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
                        Icons.warning_amber_rounded,
                        size: 45,
                        color: Color(0xFF1B478D),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                'Debes escoger una ubicación',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold)),
                            /* Text(' los consentimientos.',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold)) ,*/
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            've a la pantalla de gestion de datos para escoger la ubicación',
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
                                        borderRadius:
                                            BorderRadius.circular(8))),
                                onPressed: () {
                                  Navigator.pop(context);
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
    final widthP = MediaQuery.of(context).size;
    final heightP = MediaQuery.of(context).size;

    return BlocBuilder<StepCounterCubit, StepCounterState>(
      builder: (context, state) {
///////////////////////////////////////////
        final state = context.watch<StepCounterCubit>().state;

        ////////////////////////////////////////
        final cubit = context.read<StepCounterCubit>();
        final porcentajePorHacienda =
            context.read<StepCounterCubit>().state.porcentajeEmpleados;
        ///////////////////////////////////////////////////////////
        final haciendass = context.read<StepCounterCubit>().state.haciendas;
        //////////////////////////////////////////////////////////////
        for (int i = 0; i < porcentajePorHacienda.length; i++) {
          porcentaje = porcentajePorHacienda[i];
          hacienda = haciendass[i];

          print("Hacienda: ${hacienda!.name}, Porcentaje: $porcentaje%");
        }
        //////////////////////////////////////////////////////////////////
        _valueNotifiers =
            context.read<StepCounterCubit>().state.haciendas.map((hacienda) {
          return ValueNotifier(0.0);
          //////////////////////////////////////////////////////////////
        }).toList();
        return Scaffold(
            backgroundColor: const Color(0xfff8f8f8),
            body: SliderDrawer(
              key: _key,
              appBar: SliderAppBar(
                  appBarColor: Color(0xfff8f8f8),
                  title: Column(
                    children: [
                      Text('Hola, $userName',
                          style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF207DBC))),
                      Text(
                        'Puedes visulizar el estado de las confirmaciones',
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            fontFamily: 'Manrope',
                            color: Color(0xFF979797)),
                      )
                    ],
                  )),
              slider: SingleChildScrollView(
                child: Container(
                  color: const Color(0xffffffff),
                  width: widthP.width,
                  height: heightP.height,
                  child: Padding(
                    padding: EdgeInsets.only(top: heightP.height / 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: heightP.height / 32,
                              left: widthP.width / 12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                  context, RouteList.dashboard);
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.home_filled,
                                  color: Colors.red,
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Text(
                                  'Dashboard',
                                  style: TextStyle(
                                      color: Color(0xff207DBC),
                                      fontFamily: 'Manrope',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: heightP.height / 32,
                              left: widthP.width / 12),
                          child: GestureDetector(
                            onTap: () {
                              if (cubit.state.lat == null) {
                                _showCompletePopup(context, cubit);
                                print('vacio la lat y lon');
                              } else if (!cubit.state.plantilla.isEmpty) {
                                print('plantilla no vacio');
                                if (cubit.state.contenidoC.isEmpty) {
                                  _showPlantillaEmptyPopup(context, cubit);
                                } else {
                                  Navigator.pushNamed(
                                      context, RouteList.consentimiento);
                                }
                              } else {
                                _showPlantillaEmptyPopup(context, cubit);
                                print('plantilla vacia');
                              }
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.edit_note_sharp,
                                  color: Colors.red,
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Text(
                                  'Consentimiento',
                                  style: TextStyle(
                                      color: Color(0xff207DBC),
                                      fontFamily: 'Manrope',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: heightP.height / 32,
                              left: widthP.width / 12),
                          child: GestureDetector(
                            onTap: () {
                              // if (cubit.state.consentimientoL.length >= 2) {
                              Navigator.pushNamed(
                                  context, RouteList.management_data);
                              /*   } else {
                                _showInvalidNavigatorPopup(context, cubit);
                                null;
                              } */
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.dataset_outlined,
                                  color: Colors.red,
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Text(
                                  'Gestión de Datos',
                                  style: TextStyle(
                                      color: Color(0xff207DBC),
                                      fontFamily: 'Manrope',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: heightP.height / 32,
                              left: widthP.width / 12),
                          child: BlocBuilder<ConnectionStatusCubit,
                              ConnectionStatus>(
                            builder: (context, status) {
                              return GestureDetector(
                                onTap: () async {
                                  selectedHacienda = null;
                                  selectedHacienda1 = null;
                                  if (status != ConnectionStatus.online) {
                                    print('no hay net 2.0');
                                  } else {
                                    cubit.resetState();
                                    cubit.borrarTablasSQL();
                                    // cubit.DROPTablasSQL();
                                    print('hay net 2.0');
                                    cubit.logout();
                                  }
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    RouteList.verify,
                                    (route) => false,
                                  );

                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  prefs.setBool('isLoggedIn', false);
                                },
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.logout_outlined,
                                      color: Colors.red,
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Text(
                                      'Cerrar Sesión',
                                      style: TextStyle(
                                          color: Color(0xff207DBC),
                                          fontFamily: 'Manrope',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              left: widthP.width / 12,
                              top: heightP.height / 2 + 100),
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.pushNamed(context, RouteList.about);
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.red,
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Text(
                                  'About',
                                  style: TextStyle(
                                      color: Color(0xff207DBC),
                                      fontFamily: 'Manrope',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: Container(
                margin: EdgeInsets.only(top: heightP.height / 14),
                width: widthP.width,
                height: heightP.height,
                color: const Color(0xfff8f8f8),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: heightP.height / 22),
                        child: Container(
                          height: widthP.width / 3.2,
                          width: heightP.height / 2 + 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.2), // Color de la sombra
                                spreadRadius:
                                    -2, // Cuánto se extiende la sombra
                                blurRadius: 4, // Cuánto se difumina la sombra
                                offset: Offset(0,
                                    1), // Desplazamiento de la sombra (positivo hacia abajo para simular elevación)
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 10, left: 18),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Progreso Haciendas',
                                      style: TextStyle(
                                          color: Color(0xff207DBC),
                                          fontSize: 17,
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    context
                                        .read<StepCounterCubit>()
                                        .cargarEmpleadosDesdeSQL();
                                  },
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: cubit.state.haciendas.length,
                                    itemBuilder: (context, index) {
                                      final hacienda =
                                          cubit.state.haciendas[index];
                                      final valueNotifier =
                                          _valueNotifiers[index];
                                      final nuevosValores =
                                          cubit.state.porcentajeEmpleados;
                                      if (index < nuevosValores.length) {
                                        valueNotifier.value =
                                            nuevosValores[index].toDouble();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          height: heightP.height,
                                          width: widthP.width / 3 + 30,
                                          decoration: BoxDecoration(
                                            color: Color(0xFFF8F8F8),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 10,
                                                  right: 10,
                                                  top: 10,
                                                  bottom: 5,
                                                ),
                                                child:
                                                    DashedCircularProgressBar(
                                                  height: heightP.height,
                                                  width: widthP.width / 6,
                                                  valueNotifier: valueNotifier,
                                                  progress: valueNotifier.value,
                                                  maxProgress: 100,
                                                  foregroundColor:
                                                      Color(0xff6EEB83),
                                                  backgroundColor:
                                                      const Color(0xffeeeeee),
                                                  foregroundStrokeWidth: 11,
                                                  backgroundStrokeWidth: 10,
                                                  animation: false,
                                                  child: Center(
                                                    child:
                                                        ValueListenableBuilder(
                                                      valueListenable:
                                                          valueNotifier,
                                                      builder: (_, double value,
                                                              __) =>
                                                          Text(
                                                        '${value.toInt()}%',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 15),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  overflow: TextOverflow.fade,
                                                  hacienda
                                                      .name, // Nombre de la hacienda
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontFamily: 'Manrope',
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: heightP.height / 22),
                        child: Container(
                          height: widthP.width / 2 + 40,
                          width: heightP.height / 2 + 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: -2,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 13, left: 18, right: 6),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        context
                                            .read<StepCounterCubit>()
                                            .cargarEmpleadosDesdeSQL();
                                        context
                                            .read<StepCounterCubit>()
                                            .cargarEmpleadosDesdeSQL();
                                        context
                                            .read<StepCounterCubit>()
                                            .cargarEmpleadosDesdeSQL();
                                      },
                                      child: Text('Cumplimiento',
                                          style: TextStyle(
                                              color: Color(0xff207DBC),
                                              fontSize: 20,
                                              fontFamily: 'Manrope',
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    SizedBox(
                                      width: widthP.width / 2 - 40,
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context
                                      .read<StepCounterCubit>()
                                      .cargarEmpleadosDesdeSQL();
                                },
                                child: DropdownButton<Hacienda>(
                                  value: selectedHacienda1,
                                  onChanged: (Hacienda? newValue) {
                                    setState(() {
                                      //print('aqui');
                                      selectedHacienda1 = newValue;
                                      // Calcula el nuevo porcentaje y actualiza el ValueNotifier.
                                      int index = state.haciendas
                                          .indexOf(selectedHacienda1!);
                                      double nuevoPorcentaje = index != -1
                                          ? state.porcentajeEmpleados[index]
                                              .toDouble()
                                          : 0.0;
                                      porcentajeNotifier.value =
                                          nuevoPorcentaje;
                                      /////////////////////////////////////////////
                                      int nuevoTotalEmpleados = index != -1
                                          ? state.totalEmpleados[index]
                                          : 0;
                                      totalNotifier.value = nuevoTotalEmpleados;
                                      ////////////////////////////////////////////
                                      int aceptados = index != -1
                                          ? state.porcentajeAceptados[index]
                                          : 0;
                                      aceptadosNotifier.value = aceptados;
                                      int noAceptados =
                                          nuevoTotalEmpleados - aceptados;
                                      noAceptadosNotifier.value = noAceptados;
                                    });
                                  },
                                  items: state.haciendas
                                      .map<DropdownMenuItem<Hacienda>>(
                                          (Hacienda hacienda) {
                                    return DropdownMenuItem<Hacienda>(
                                      onTap: () {
                                        context
                                            .read<StepCounterCubit>()
                                            .cargarEmpleadosDesdeSQL();
                                      },
                                      value: hacienda,
                                      child: Text(hacienda.name),
                                    );
                                  }).toList(),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    top: heightP.height / 52,
                                    right: 20,
                                    left: 20,
                                    bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    DashedCircularProgressBar(
                                      height: 180,
                                      width: 180,
                                      valueNotifier: porcentajeNotifier,
                                      progress: porcentajeNotifier.value,
                                      maxProgress: 100,
                                      foregroundColor: Color(0xff1B478D),
                                      backgroundColor: const Color(0xffeeeeee),
                                      foregroundStrokeWidth: 15,
                                      backgroundStrokeWidth: 14,
                                      animation: false,
                                      child:
                                          //Center(child: Text('${porcentaje}'))
                                          Center(
                                        child: ValueListenableBuilder(
                                          valueListenable: porcentajeNotifier,
                                          builder: (_, double value, __) =>
                                              Text(
                                            '${value.toInt()}%',
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                    ),

                                    //TAGS

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                              color: Color(0xff1B478D),
                                              borderRadius:
                                                  BorderRadius.circular(17.3)),
                                          width: widthP.width / 3,
                                          height: heightP.height / 29,
                                          child: Center(
                                              child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Total',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontFamily: 'Manrope')),
                                              Text(
                                                  selectedHacienda1 != null
                                                      ? totalNotifier.value
                                                          .toString()
                                                      : "0",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontFamily: 'Manrope'))
                                            ],
                                          )),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 8, bottom: 2),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Aceptados',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xffff555770),
                                                    fontSize: 20,
                                                    fontFamily: 'Manrope'),
                                              ),
                                              const SizedBox(
                                                width: 20,
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                    color: Color(0xFF7ECB6B),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            17.3)),
                                                width: widthP.width / 10,
                                                height: heightP.height / 29,
                                                child: Center(
                                                    child: Text(
                                                        selectedHacienda1 != null
                                                            ? aceptadosNotifier
                                                                .value
                                                                .toString()
                                                            : "0",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontFamily:
                                                                'Manrope'))),
                                              )
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 7, bottom: 2),
                                          child: Row(
                                            children: [
                                              const Text(
                                                'Pendientes',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xffff555770),
                                                    fontSize: 20,
                                                    fontFamily: 'Manrope'),
                                              ),
                                              const SizedBox(
                                                width: 15,
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFE36D6D),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            17.3)),
                                                width: widthP.width / 10,
                                                height: heightP.height / 29,
                                                child: Center(
                                                    child: Text(
                                                        selectedHacienda1 !=
                                                                null
                                                            ? noAceptadosNotifier
                                                                .value
                                                                .toString()
                                                            : "0",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontFamily:
                                                                'Manrope'))),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      //WarningWidgetCubit(),
                    ],
                  ),
                ),
              ),
            ));
      },
    );
  }
}
