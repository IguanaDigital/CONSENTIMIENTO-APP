/* import 'package:consentimiento/cubit/connection_status_cubit.dart';
import 'package:consentimiento/utils/check_internet_connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WarningWidgetCubit extends StatelessWidget {
  const WarningWidgetCubit({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConnectionStatusCubit(),
      child: BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
          builder: (context, status) {
        return Visibility(
          visible: status != ConnectionStatus.online,
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 60,
            color: Colors.red,
            child: Row(
              children: [
                const Icon(Icons.wifi_off),
                const SizedBox(width: 8),
                const Text('No hay conexión a internet'),
              ],
            ),
          ),
        );
      }),
    );
  }
}
 */
import 'package:consentimiento/cubit/connection_status_cubit.dart';
import 'package:consentimiento/utils/check_internet_connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WarningWidgetCubit extends StatelessWidget {
  const WarningWidgetCubit({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
      builder: (context, status) {
        if (status != ConnectionStatus.online) {
          // No hay conexión a Internet, muestra el cuadro de diálogo
          WidgetsBinding.instance!.addPostFrameCallback((_) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                  content: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: Colors.white),
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
                                Icons
                                    .signal_wifi_connected_no_internet_4_rounded,
                                //color: Color(0xff4147D5),
                                color: Color(0xFF1B478D),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text('No hay internet',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF1B478D),
                                                fontFamily: 'Manrope',
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                            'El dispositivo se encuentra sin red',
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: Color(0xFF1B478D),
                                                fontFamily: 'Manrope',
                                                fontWeight: FontWeight.bold)),
                                        Text('puedes operar offline',
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: Color(0xFF1B478D),
                                                fontFamily: 'Manrope',
                                                fontWeight: FontWeight.bold))
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 30,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          primary: Color(0xFF1B478D),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8))),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        //Navigator.pop(context);
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
          });
        }
        return Container(); // El contenido normal del widget cuando hay conexión
      },
    );
  }
}
