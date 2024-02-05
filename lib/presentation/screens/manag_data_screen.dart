import 'package:consentimiento/cubit/connection_status_cubit.dart';
import 'package:consentimiento/cubit/step_counter_cubit.dart';
import 'package:consentimiento/utils/check_internet_connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorful_tab/flutter_colorful_tab.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

bool sendingConsent = false;
bool latlon = false;
String? _currentAddress;
Position? _currentPosition;

class ManagementDataScreen extends StatefulWidget {
  const ManagementDataScreen({super.key});

  @override
  State<ManagementDataScreen> createState() => _ManagementDataScreenState();
}

class _ManagementDataScreenState extends State<ManagementDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool visible = false;

  @override
  void initState() {
    context.read<StepCounterCubit>().loadConsentimientoLocalData();
    _tabController = TabController(vsync: this, length: 2);
    _tabController.addListener(() {
      // Verificar si estamos en el segundo TabItem
      if (_tabController.index == 1) {
        setState(() {
          visible = true;
        });
      } else {
        setState(() {
          visible = false;
        });
      }
    });
    super.initState();
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

  Widget _pageView(int index, StepCounterCubit cubit) {
    if (index == 0) {
      return Container(
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Cantidad')),
                ],
                rows: [
                  DataRow(cells: [
                    DataCell(Text('Haciendas')),
                    DataCell(Text(cubit.state.haciendas.length.toString())),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Empleados')),
                    DataCell(Text(cubit.state.empleados.length.toString())),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Plantillas')),
                    DataCell(Text(cubit.state.plantilla.length.toString())),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Encuestas')),
                    DataCell(Text(cubit.state.encuestas.length.toString())),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Compañias')),
                    DataCell(Text(cubit.state.compania!.length.toString())),
                  ]),
                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Text(
                  'Nota: Configurar Ubicacion para extraer Latitud y Longitud',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.width * 0.025,
                      fontFamily: 'Manrope'),
                ),
              ],
            ),
            SizedBox(
              height: 15,
            ),
            Visibility(
                visible: cubit.state.lat == null,
                child: Text(
                  'Darle click al boton',
                  style: TextStyle(),
                )),
            Visibility(
                visible: cubit.state.lat != null,
                child: Text('LAT: ${cubit.state.lat}')),
            Visibility(
                visible: cubit.state.lon != null,
                child: Text('LON: ${cubit.state.lon}')),
            /*  Text('LAT: ${_currentPosition?.latitude ?? ""}'),
            Text('LNG: ${_currentPosition?.longitude ?? ""}'), */
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  primary: Color(0xFF1B478D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () async {
                _getCurrentPosition();
                setState(() {
                  latlon = true;
                });
                await Future.delayed(Duration(seconds: 2));

                setState(() {
                  latlon = false;
                });
                print(
                    'coordenadas: ${_currentPosition?.latitude} y de lon: ${_currentPosition?.longitude}');
                cubit.insertlatlon(
                    _currentPosition!.latitude, _currentPosition!.longitude);
              },
              child: latlon
                  ? Container(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 4.0,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      "Obtener la ubicacion actual",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Manrope',
                      ),
                    ),
            )
          ],
        ),
/*         DataTable(
          columns: [
            DataColumn(label: Text('Seleccionar')),
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Cantidad')),
          ],
          rows: [
            DataRow(selected: true, cells: [
              DataCell(
                Checkbox(
                  value: cubit.state.consentimientoL[index].seleccionado,
                  onChanged: (isSelected) {
                    setState(() {
                      cubit.toggleSeleccionConsentimientoLoca(
                          cubit.state.consentimientoL[index]);
                    });
                  },
                ),
              ),
              DataCell(Text('haciendas')),
              DataCell(Text(cubit.state.haciendas.length.toString())),
              /*  DataCell(Text('Empleados')),
              DataCell(Text(cubit.state.empleados.length.toString())), */
            ]),
          ],
        ), */
      );
    } else if (index == 1) {
      // Puedes hacer lo mismo para la segunda pestaña si es necesario.
      if (cubit.state.consentimientoL.length >= 1) {
        return Container(
          child: DataTable(
            columns: [
              DataColumn(label: Text('Seleccionar')),
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Cantidad')),
            ],
            rows: [
              DataRow(selected: true, cells: [
                DataCell(
                  Checkbox(
                    value: cubit.state.consentimientoL[index - 1].seleccionado,
                    onChanged: (isSelected) {
                      setState(() {
                        cubit.toggleSeleccionConsentimientoLoca(
                            cubit.state.consentimientoL[index - 1]);
                      });
                    },
                  ),
                ),
                DataCell(Text('Consentimientos')),
                DataCell(Text(cubit.state.consentimientoL.length.toString())),
              ]),
            ],
          ),
        );
      } else {
        return Text('No hay datos disponibles');
      }
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StepCounterCubit, StepCounterState>(
      builder: (context, state) {
        final cubit = context.read<StepCounterCubit>();
        return Scaffold(
          appBar: AppBar(),
          body: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                ColorfulTabBar(
                  tabs: [
                    TabItem(
                      color: Color(0xFF1B478D),
                      title: Text('Datos descargados'),
                      unselectedColor: Color(0xFF9AAFC0),
                    ),
                    TabItem(
                      color: Color(0xFF1B478D),
                      title: Text('Cargar datos'),
                      unselectedColor: Color(0xFF9AAFC0),
                    ),
                  ],
                  controller: _tabController,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children:
                        List.generate(2, (index) => _pageView(index, cubit)),
                  ),
                ),
                SizedBox(height: 20.0),
                Visibility(
                  visible: visible,
                  child: SizedBox(
                    height: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          height: 50,
                          child: BlocBuilder<ConnectionStatusCubit,
                              ConnectionStatus>(
                            builder: (context, status) {
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  primary:
                                      cubit.state.consentimientoL.length > 0
                                          ? Color(0xFF1B478D)
                                          : Colors.grey,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  setState(() {
                                    sendingConsent = true;
                                  });
                                  final cubit =
                                      context.read<StepCounterCubit>();
                                  final consentimientosAEnviar = cubit
                                      .state.consentimientoL
                                      .where((consentimiento) =>
                                          consentimiento.id != 0)
                                      .toList();
                                  await cubit.SendDataConsentimientos(
                                      consentimientosAEnviar);

                                  // Simulación de un retardo para mostrar el indicador de carga.
                                  await Future.delayed(Duration(seconds: 2));

                                  setState(() {
                                    sendingConsent = false;
                                  });

                                  if (status != ConnectionStatus.online) {
                                    print('no hay net 2.0');
                                    _showInvalidCompletePopup(context, cubit);
                                  } else {
                                    _showCompletePopup(context, cubit);
                                    print('hay net 2.0');
                                  }

                                  // Mostrar el cuadro de diálogo de confirmación.
                                },
                                child: sendingConsent
                                    ? Container(
                                        height: 30,
                                        width: 30,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 4.0,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Enviar consentimiento',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontFamily: 'Manrope',
                                        ),
                                      ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
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
                      Icons.check_circle_outline,
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
                              'Se ha enviado correctamente',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.bold)),
                          Text(' los consentimientos.',
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
                          'cuando se envien los consentimientos ya no estaran disponibles',
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
                                cubit.deleteAllConsentimientos();
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
