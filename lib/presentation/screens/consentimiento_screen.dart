import 'dart:convert';
import 'dart:io';
import 'package:consentimiento/config/model/model.dart';
import 'package:consentimiento/config/route_list.dart';
import 'package:consentimiento/main.dart';
import 'package:consentimiento/presentation/widgets/search.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:camera/camera.dart';
import 'package:consentimiento/cubit/step_counter_cubit.dart';
import 'package:consentimiento/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'package:video_player/video_player.dart';
import 'package:sqflite/sqflite.dart';

String logoEncontrado = '';
PageController _pageController = PageController();
int _currentPage = 0;
/* late VideoPlayerController _videoPlayerController; */
String fileOut = "";
var filePath;
var fileIMG;
bool isDropdownSelected = false;
Empleado? selectedEmpleado;
bool _isSearching = false;
XFile? videoFile;
//firma
bool _isSignatureEmpty = true;
bool _isSigning = false;
bool _isContainerVisible = true;
final SignatureController _controller = SignatureController(
  penStrokeWidth: 4,
  penColor: Colors.black,
  exportBackgroundColor: Colors.white,
);
/////

String? selectedHaciendaId;
List<Empleado> filteredEmpleados = [];

class ConsentimientoScreen extends StatefulWidget {
  const ConsentimientoScreen({super.key});

  @override
  State<ConsentimientoScreen> createState() => _ConsentimientoScreenState();
}

class _ConsentimientoScreenState extends State<ConsentimientoScreen> {
  late final List<Hacienda> hacienda;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    isDropdownSelected = false;
    context.read<StepCounterCubit>().actualizarFecha();
    loadIdEncuestaFromSharedPreferences();
    context.read<StepCounterCubit>().loadConsentimientoLocalData();
    context.read<StepCounterCubit>().buscarIdPlantillas();
  }

  Future<void> loadIdEncuestaFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idEncuestaSP2 = prefs.getInt('idEncuestaSP')!;
    });
  }

  @override
  void dispose() {
    // _disposeVideoPlayer();
    _pageController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return BlocBuilder<StepCounterCubit, StepCounterState>(
      builder: (context, state) {
        final cubit = context.read<StepCounterCubit>();
        final empresas = cubit.state.compania;
        final empleados = cubit.state.empleados;

        for (final empleado in empleados) {
          final idEmpresa = empleado.empresa;
          final empresa = empresas!.firstWhere(
            (compania) => compania.id == idEmpresa,
            orElse: () => Compania(id: '', nombre: '', logo: ''),
          );

          if (empresa.id != '') {
            logoEncontrado = empresa.logo!;
            break;
          }
        }
        for (final empleado in empleados) {
          final idEmpresa = empleado.empresa;
          final empresa = empresas!.firstWhere(
            (compania) => compania.id == idEmpresa,
            orElse: () => Compania(id: '', nombre: '', logo: ''),
          );

          if (empresa.id != '') {
            print(
                'El empleado ${empleado.name} trabaja en la empresa ${empresa.nombre}');
          }
        }
        empleados.forEach((empleado) {
          final empresa = empresas!.firstWhere(
            (compania) => compania.id == empleado.empresa,
            orElse: () => Compania(id: '', nombre: '', logo: ''),
          );

          if (empresa.id != '') {
            empleado.empresa = empresa.nombre;
          }
        });
        return Scaffold(
          backgroundColor: Color(0xfff8f8f8),
          body: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: MediaQuery.of(context).size.width / 20,
                          left: MediaQuery.of(context).size.width / 20,
                          top: 50),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.only(right: 8, left: 8),
                              height: 40,
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    width: 1.8,
                                    color: cubit.state.nextStep >= 1
                                        ? Colors.grey
                                        : Color(0xFF9AAFC0)),
                              ),
                              child: IgnorePointer(
                                ignoring: cubit.state.nextStep >= 1,
                                child: DropdownButton<Hacienda>(
                                  icon: Icon(
                                    size: 40,
                                    Icons.arrow_drop_down_rounded,
                                    color: cubit.state.nextStep >= 1
                                        ? Colors.grey
                                        : Color(0xFF1B478D),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  elevation: 1,
                                  dropdownColor: Color(0xFF9AAFC0),
                                  underline: Container(),
                                  hint: const Text(
                                    'Selecciona una hacienda',
                                    style: TextStyle(
                                        color: Color(0xFF1B478D),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Manrope'),
                                  ),
                                  value:
                                      state.haciendas.contains(selectedHacienda)
                                          ? selectedHacienda
                                          : selectedHacienda,
                                  onChanged: (Hacienda? hacienda) {
                                    setState(() {
                                      selectedHacienda = hacienda!;
                                      if (selectedEmpleado != null) {
                                        selectedEmpleado = null;
                                      }
                                      cubit.selectHacienda(hacienda);
                                      selectedHaciendaId = hacienda.id;
                                    });
                                  },
                                  items:
                                      state.haciendas.toSet().map((hacienda) {
                                    return DropdownMenuItem<Hacienda>(
                                      value: hacienda,
                                      child: Text(
                                        textAlign: TextAlign.center,
                                        hacienda.name,
                                        style: TextStyle(
                                            color: cubit.state.nextStep >= 1
                                                ? Colors.grey
                                                : Color(0xFF1B478D),
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Manrope'),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 40,
                              width: MediaQuery.of(context).size.width / 3 + 50,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: const Color(0xFFF4F4F4),
                                  border: Border.all(
                                      width: 1.8,
                                      color: cubit.state.nextStep >= 1
                                          ? Colors.grey
                                          : Color(0xFF9AAFC0))),
                              child: IgnorePointer(
                                ignoring: cubit.state.nextStep >= 1,
                                child: Center(
                                  child: TextField(
                                    readOnly: true,
                                    onTap: () async {
                                      final empleado =
                                          await showSearch<Empleado>(
                                        context: context,
                                        delegate: EmpleadoSearchDelegate(state
                                            .empleados
                                            .where((empleado) =>
                                                empleado.haciendaId ==
                                                    selectedHacienda!.id &&
                                                empleado.estado_encuesta != "A")
                                            .toSet()
                                            .toList()),
                                      );
                                      if (empleado != null) {
                                        setState(() {
                                          isDropdownSelected = true;

                                          selectedEmpleado = empleado;

                                          cubit.selectEmpleado2(empleado);
                                        });
                                      } else {}
                                    },
                                    decoration: InputDecoration(
                                      hintText: selectedEmpleado?.name ??
                                          'Selecciona un empleado',
                                      hintStyle: TextStyle(
                                          color: cubit.state.nextStep >= 1
                                              ? Colors.grey
                                              : Color(0xFF1B478D),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Manrope'),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(
                                          11), // Añade relleno para el texto
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildStepIndicators(cubit),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 7,
                    child: PageView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      controller: _pageController,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        final pagesStep = _steps(context);
                        return pagesStep[index];
                      },
                      onPageChanged: (index) {
                        setState(() {
                          index = cubit.state.nextStep;
                        });
                      },
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 1, horizontal: 20),
                      child: TobackDashboard()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

List<Widget> _steps(BuildContext context) {
  return [StepOne(), CameraPage(), SignaturePage()];
}

void _showMessageConfirmFinish(BuildContext context, StepCounterCubit cubit,
    Hacienda selectedHacienda1, Empleado selectedEmpleado1) {
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<StepCounterCubit, StepCounterState>(
          builder: (context, state) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(13))),
              contentPadding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
              content: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: Colors.white),
                width: 60,
                height: 120,
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
                              Icons.check_circle_outline_sharp,
                              color: Color(0XFF6EEB83),
                              size: 40,
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 1),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('Consentimiento',
                                      style: TextStyle(
                                          color: Color(0xFF207DBC),
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.normal)),
                                  Text('Aceptada',
                                      style: TextStyle(
                                          color: Color(0xFF207DBC),
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                //fixedSize: Size(80, 30),
                                primary: Color(0xff006AB2),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            onPressed: () {
                              cubit.llenarYInsertarConsentimiento(
                                  selectedHacienda1,
                                  selectedEmpleado1,
                                  fileIMG.path,
                                  filePath);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                context
                                    .read<StepCounterCubit>()
                                    .cargarEmpleadosDesdeSQL();
                                context
                                    .read<StepCounterCubit>()
                                    .cargarEmpleadosDesdeSQL();
                                context
                                    .read<StepCounterCubit>()
                                    .cargarEmpleadosDesdeSQL();
                              });
                              filePath = '';
                              fileOut = '';
                              fileIMG = '';
                              videoFile = null;
                              _isContainerVisible = true;

                              _controller.clear();
                              Navigator.pop(context);
                              _pageController.jumpToPage(cubit.state.nextStep);
                            },
                            child: Text(
                              'SIGUIENTE',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                      left: MediaQuery.of(context).size.width / 2 + 10,
                      top: MediaQuery.of(context).size.height / 17,
                      child: Transform.rotate(
                        angle: -7.0,
                        child: Icon(
                          Icons.edit_calendar_outlined,
                          size: 75,
                          color: Colors.grey.shade300,
                        ),
                      )),
                ]),
              ),
            );
          },
        );
      });
}

void _showMessageConfirm(BuildContext context) {
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(13))),
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
                          Icons.check_circle_outline_sharp,
                          color: Color(0XFF6EEB83),
                          size: 40,
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Grabación',
                                  style: TextStyle(
                                      color: Color(0xFF207DBC),
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.normal)),
                              Text('Aceptada',
                                  style: TextStyle(
                                      color: Color(0xFF207DBC),
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            //fixedSize: Size(80, 30),
                            primary: Color(0xff006AB2),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        onPressed: () {
                          Navigator.pop(context);
                          //_disposeVideoPlayer();
                          //_showMessageConfirm(context, cubit);
                        },
                        child: Text(
                          'SIGUIENTE',
                          style: TextStyle(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                  left: MediaQuery.of(context).size.width / 2 + 10,
                  top: MediaQuery.of(context).size.height / 17,
                  child: Transform.rotate(
                    angle: -7.0,
                    child: Icon(
                      Icons.movie_outlined,
                      size: 75,
                      color: Colors.grey.shade300,
                    ),
                  )),
            ]),
          ),
        );
      });
}

class TobackDashboard extends StatefulWidget {
  const TobackDashboard({super.key});

  @override
  State<TobackDashboard> createState() => _TobackDashboardState();
}

class _TobackDashboardState extends State<TobackDashboard> {
  @override
  Widget build(BuildContext context) {
    void _clearSignature() {
      _controller.clear();
      setState(() {
        _isSignatureEmpty = true;
        _isSigning = false;
        _isContainerVisible = true;
      });
    }

    void _deleteVideo() {
      final file = File(fileOut);
      if (file.existsSync()) {
        file.deleteSync();

        setState(() {
          fileOut = '';
        });
      }
      Navigator.of(context).pop(); // Cerrar el diálogo
    }

    void _deleteSignature() async {
      if (fileIMG != null && await fileIMG.exists()) {
        try {
          await fileIMG.delete();
          setState(() {
            _isSignatureEmpty = true;
            _isSigning = false;
          });
          print('Firma eliminada.');
        } catch (e) {
          print('Error al eliminar la firma: $e');
        }
      } else {
        print('No se encontró la firma para eliminar.');
      }
    }

    return BlocBuilder<StepCounterCubit, StepCounterState>(
      builder: (context, state) {
        final cubit = context.read<StepCounterCubit>();
        return GestureDetector(
          onTap: () {
            //state!.selectedEmpleado = null;
            selectedEmpleado = null;
            //fileOut = '';
            //_disposeVideoPlayer();
            context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
            context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
            context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
            cubit.resetStep();

            _deleteVideo();
            _deleteSignature();
            _clearSignature();
            setState(() {
              _isContainerVisible = false;
              _isSigning = false;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          },
          child: Row(
            children: [
              Text(
                'Volver al dashboard',
                style: TextStyle(
                    fontSize: 17,
                    color: Color(0XFF0F50F7),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget buttonNext(BuildContext context, StepCounterCubit cubit) {
  return SizedBox(
    width: 150,
    height: 40,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
          //fixedSize: Size(80, 30),
          primary: Color(0xff006AB2),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      onPressed: () {
        context.read<StepCounterCubit>().actualizarFecha();
        if (cubit.state.nextStep < 3) {
          cubit.passStep();
          print('step:${cubit.state.nextStep}');
          _pageController.nextPage(
            duration: Duration(milliseconds: 500),
            curve: Curves.decelerate,
          );
        }
      },
      child: Text(
        'ACEPTO',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    ),
  );
}

class ButtonFinish extends StatefulWidget {
  const ButtonFinish({super.key});

  @override
  State<ButtonFinish> createState() => _ButtonFinishState();
}

class _ButtonFinishState extends State<ButtonFinish> {
  Future<void> _saveToGallery(StepCounterCubit cubit, XFile videoFile) async {
    String dia = cubit.state.dia.toString();
    String mes = cubit.state.mes.toString();
    String year = cubit.state.anio.toString();
    String fecha = '$dia-$mes-$year.';
    final videoBytes = await videoFile.readAsBytes();
    final base64String = base64Encode(videoBytes);

    final appDocumentsDirectory = await getExternalStorageDirectory();
    final timestamp = '${cubit.state.selectedEmpleado!.id}_${fecha}_video';
    final fileName = '.$timestamp.txt'; // Cambia la extensión a .txt
    final directory = Directory('${appDocumentsDirectory!.path}/.videos');
    if (!await directory.exists()) {
      await directory.create();
      // Crear el archivo .nomedia para ocultar el directorio en la galería
      final nomediaFile = File('${directory.path}/.nomedia');
      nomediaFile.createSync();
    }
    filePath = '${directory.path}/$fileName';

    // Guarda el video convertido en Base64 en un archivo .txt
    final txtFile = File(filePath);
    await txtFile.writeAsString(base64String);
    setState(() {
      fileOut = filePath;
    });
    print('Video convertido en Base64 y guardado en archivo .txt: $filePath');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StepCounterCubit, StepCounterState>(
      builder: (context, state) {
        final cubit = context.read<StepCounterCubit>();
        return SizedBox(
          height: 50,
          width: 200,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                //fixedSize: Size(80, 30),
                primary: Color(0xff006AB2),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              //Va el resto de la logica
              context.read<StepCounterCubit>().actualizarFecha();
              if (cubit.state.nextStep < 3) {
                _saveToGallery(cubit, videoFile!);
                _pageController.jumpToPage(cubit.state.nextStep);
                _showMessageConfirmFinish(
                    context, cubit, selectedHacienda!, selectedEmpleado!);
                if (selectedEmpleado != null) {
                  cubit.marcarEmpleadoAceptado(selectedEmpleado!);
                  cubit.insertarEmpleado(selectedEmpleado!);
                  cubit.marcarEmpleadoAceptado2(selectedEmpleado!.id);

                  //_disposeVideoPlayer();
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
                  context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
                  context.read<StepCounterCubit>().cargarEmpleadosDesdeSQL();
                });

                setState(() {
                  isDropdownSelected = false;
                });

                cubit.resetStep();
                selectedEmpleado = null;
                cubit.resetEmpleado(selectedEmpleado);

                /* cubit.state.selectedEmpleado = null; */
                //print('estado: ${selectedEmpleado!.estado_contratacion}');
              }
            },
            child: Text(
              'FINALIZAR PROCESO',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        );
      },
    );
  }
}

Widget buttonPrevious(BuildContext context, StepCounterCubit cubit) {
  return SizedBox(
    height: 30,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
          //fixedSize: Size(80, 30),
          primary: Color(0xff006AB2),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      onPressed: () {
        if (cubit.state.nextStep < 3) {
          cubit.previusStep();
          _pageController.previousPage(
            duration: Duration(milliseconds: 500),
            curve: Curves.decelerate,
          );
        }
      },
      child: Text(
        'ATRAS',
        style: TextStyle(color: Colors.white, fontSize: 8),
      ),
    ),
  );
}

List<Widget> _buildStepIndicators(StepCounterCubit cubit) {
  List<Widget> indicators = [];
  List<String> label = ['CONSENTIMIENTO', 'VIDEO', 'FIRMA'];
  for (int i = 0; i < 3; i++) {
    indicators.add(
      Container(
        height: 70,
        child: Column(
          children: [
            Container(
              width: 100,
              height: 30,
              margin: EdgeInsets.only(bottom: 5, left: 30, right: 30),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == cubit.state.nextStep
                      ? Color(0xff1B478D)
                      : Color(0xffCFCFCF)),
              child: Center(
                child: Container(
                  width: 25,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == cubit.state.nextStep
                        ? Color(0xfff8f8f8)
                        : Color(0xfff8f8f8),
                  ),
                  child: Center(
                    child: Text(
                      (i + 1).toString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w900,
                        color: i == cubit.state.nextStep
                            ? Color(0xff1B478D)
                            : Color(0xffCFCFCF),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                label[i],
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w900,
                  color: i == cubit.state.nextStep
                      ? Color(0xff1B478D)
                      : Color(0xffCFCFCF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  return indicators;
}

class StepOne extends StatefulWidget {
  const StepOne({super.key});

  @override
  State<StepOne> createState() => _StepOneState();
}

class _StepOneState extends State<StepOne> {
  bool isChecked = false;
  @override
  Widget build(BuildContext context) {
    final widthP = MediaQuery.of(context).size;
    final heightP = MediaQuery.of(context).size;
    return BlocBuilder<StepCounterCubit, StepCounterState>(
      builder: (context, state) {
        final cubit = context.read<StepCounterCubit>();
        String text;
        String textfinal;
        String dia = cubit.state.dia.toString();
        String mes = cubit.state.mes.toString();
        String year = cubit.state.anio.toString();
        String hora = cubit.state.hora.format(context);
        String fecha = '$dia de $mes de $year.';
        String cedula = selectedEmpleado?.cedula ?? '';
        String empresa = selectedEmpleado?.empresa ?? '';
        text = cubit.state.contenidoC.toString();
        List<int> bytes = base64.decode(logoEncontrado.split('.').last);

        textfinal =
            text.replaceAll("@nombre_empleado", selectedEmpleado?.name ?? '');
        textfinal = textfinal.replaceAll('@HORA', '');
        textfinal = textfinal.replaceAll('@HORA', '');
        textfinal = textfinal.replaceAll('@FECHA_DIA', fecha);
        textfinal = textfinal.replaceAll('@FECHA_DIA', fecha);
        textfinal = textfinal.replaceAll('@cedula_empleado', cedula);
        textfinal = textfinal.replaceAll('@cedula_empleado', cedula);
        textfinal = textfinal.replaceAll('@empresa', empresa);
        textfinal = textfinal.replaceAll('@empresa', empresa);
        if (text.isEmpty) print('no hay');
        return SizedBox(
          width: widthP.width,
          height: heightP.height / 6,
          child: Column(children: [
            Container(
                width: widthP.width / 2 + 220,
                height: heightP.height / 2,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          cubit.state.titulo.toString(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xff182844)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 13, bottom: 13),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              bytes == ''
                                  ? Image.memory(Uint8List.fromList(bytes))
                                  : Container()
                            ],
                          ),
                        ),
                        Text(
                          textAlign: TextAlign.justify,
                          textfinal,
                          style: const TextStyle(fontSize: 15),
                        )
                      ],
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.2), // Color de la sombra
                      spreadRadius: -3, // Cuánto se extiende la sombra
                      blurRadius: 3, // Cuánto se difumina la sombra
                      offset: Offset(-1,
                          2), // Desplazamiento de la sombra (positivo hacia abajo para simular elevación)
                    ),
                  ],
                )),
            SizedBox(height: 35.0),
            SizedBox(
              width: widthP.width / 2 + 100,
              child: Row(
                children: [
                  Container(
                    width: 20.5,
                    height: 20.5,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isChecked
                            ? Color(0xff0E67FD)
                            : Colors.grey.shade300, // Color del borde
                        width: 2.1, // Ancho del borde
                      ),
                      borderRadius: BorderRadius.circular(
                          5.0), // Ajusta el radio del borde
                      color: Colors.white, // Establece el fondo blanco
                    ),
                    child: Checkbox(
                      visualDensity: VisualDensity(horizontal: 2, vertical: 1),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: Colors.white,
                      checkColor: Color(0xff0E67FD),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0)),
                      side: BorderSide(
                          color: isChecked ? Color(0xff0E67FD) : Colors.white,
                          width: 2.2),
                      value: isChecked,
                      onChanged: (newValue) {
                        setState(() {
                          isChecked = newValue!;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isChecked = !isChecked;
                      });
                    },
                    child: Text(
                      'He leido en su totalidad el documento',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isChecked ? Color(0xff0E67FD) : Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  right: widthP.width / 3 + 20,
                  left: widthP.width / 3 + 20,
                  top: 70),
              child: Visibility(
                  visible: isChecked && isDropdownSelected,
                  child: buttonNext(context, cubit)),
            )
          ]),
        );
      },
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  VideoPlayerController? _videoPlayerController;
  bool _isLoading = true;
  late CameraController _cameraController;
  bool _isRecording = false;
  late String contenidoVideo;

  Future<void> _initVideoPlayer() async {
    if (_videoPlayerController != null) {
      //_cameraController.dispose();
      _videoPlayerController!.pause();
      _videoPlayerController!.dispose();
    }

    _videoPlayerController = VideoPlayerController.file(File(fileOut));
    await _videoPlayerController!.initialize();
    await _videoPlayerController!.setLooping(true);
    await _videoPlayerController!.play();
  }

  Future<void> _initCamera() async {
    if (_isLoading == false) {
      _disposeVideoPlayer();
    }

    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front);
      _cameraController = CameraController(front, ResolutionPreset.max);
      await _cameraController.initialize();

      setState(() => _isLoading = false);
    } catch (e) {
      print("Error al inicializar la cámara: $e");
      setState(() => _isLoading = false);
    }
  }

  void _deleteVideo() {
    final file = File(fileOut);
    if (file.existsSync()) {
      file.deleteSync();

      setState(() {
        fileOut = '';
      });
    }
    Navigator.of(context).pop();
  }

  Future<void> _recordVideo(StepCounterCubit cubit) async {
    if (_isRecording) {
      videoFile = await _cameraController.stopVideoRecording();
      setState(() => _isRecording = false);
      final appDocumentsDirectory = await getExternalStorageDirectory();
      print('ubi0:$appDocumentsDirectory ');

      final newFile = File(videoFile!.path);

      print('ubi2: $newFile');
      setState(() {
        fileOut = videoFile!.path;
      });
      _showVideoPreviewDialog(context, videoFile!);
    } else {
      await _cameraController.prepareForVideoRecording();
      await _cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
        print('fileout: $fileOut');
      });
    }
  }

  void _disposeVideoPlayer() {
    if (_videoPlayerController != null) {
      // _cameraController.dispose();
      _videoPlayerController!.pause();
      _videoPlayerController!.dispose();
    }
  }

  void _showVideoPreviewDialog(BuildContext context, XFile videoFile) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<StepCounterCubit, StepCounterState>(
          builder: (context, state) {
            final cubit = context.read<StepCounterCubit>();
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(13))),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                title: const Text(
                  'Vista Previa',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                content: FutureBuilder(
                  future: _initVideoPlayer(),
                  builder: (context, state) {
                    if (state.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                            height: MediaQuery.of(context).size.height,
                            width: 600,
                            child: VideoPlayer(_videoPlayerController!)),
                      );
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      // await _cameraController.dispose();
                      _disposeVideoPlayer();
                      _deleteVideo();
                      //Navigator.of(context).pop(); // Cerrar el diálogo
                    },
                    child: const Text(
                      'ELIMINAR',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 24,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          //fixedSize: Size(80, 30),
                          primary: Color(0xff006AB2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      onPressed: () async {
                        _disposeVideoPlayer();
                        _videoPlayerController!.pause();
                        _videoPlayerController!.dispose();
                        // _saveToGallery(cubit, videoFile);
                        cubit.passStep();
                        _isContainerVisible = true;
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.decelerate,
                        );

                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'ACEPTAR GRABACION',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Manrope'),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initVideoPlayer();
    contenidoVideo = context.read<StepCounterCubit>().state.contenidoV;
  }

  @override
  void dispose() {
    //_cameraController.dispose();
    _videoPlayerController!.pause();
    _videoPlayerController!.dispose();
    _disposeVideoPlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return BlocBuilder<StepCounterCubit, StepCounterState>(
        builder: (context, state) {
          final cubit = context.read<StepCounterCubit>();
          String text;
          String textfinal;
          String dia = cubit.state.dia.toString();
          String mes = cubit.state.mes;
          String year = cubit.state.anio.toString();
          String empresa = cubit.state.selectedEmpleado!.empresa;

          text = cubit.state.contenidoV.toString();
          textfinal = text.replaceAll(
              "[nombre apellido 1]", selectedEmpleado?.name ?? '');
          textfinal = textfinal.replaceAll('[DIA]', dia);
          textfinal = textfinal.replaceAll('[DIA]', dia);
          textfinal = textfinal.replaceAll('[MES]', mes);
          textfinal = textfinal.replaceAll('[MES]', mes);
          textfinal = textfinal.replaceAll('[ANIO]', year);
          textfinal = textfinal.replaceAll('[ANIO]', year);
          textfinal = textfinal.replaceAll('[empresa]', empresa);
          textfinal = textfinal.replaceAll('[empresa]', empresa);
          /*     textfinal = textfinal.replaceAll(
              '[empresa]', selectedEmpleado?.empresa ?? '');
              textfinal = textfinal.replaceAll(
              '[empresa]', selectedEmpleado?.empresa ?? ''); */

          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                top: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                        width: MediaQuery.of(context).size.width / 2 + 150,
                        height: MediaQuery.of(context).size.height / 2 + 50,
                        child: CameraPreview(_cameraController)),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height / 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: FloatingActionButton(
                        backgroundColor: Colors.white,
                        child: _isRecording
                            ? Icon(
                                Icons.stop,
                                color: Colors.red,
                                size: 40,
                              )
                            : Icon(
                                Icons.circle,
                                color: Colors.red,
                                size: 50,
                              ),
                        //child: Icon(_isRecording ? Icons.stop : Icons.circle),
                        onPressed: () {
                          //_showVideoPreviewDialog(context);
                          _recordVideo(cubit);
                        }),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height / 2 + 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    height: MediaQuery.of(context).size.height / 9.5,
                    width: MediaQuery.of(context).size.width / 2 + 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.2), // Color de la sombra
                          spreadRadius: -3, // Cuánto se extiende la sombra
                          blurRadius: 3, // Cuánto se difumina la sombra
                          offset: Offset(-1,
                              2), // Desplazamiento de la sombra (positivo hacia abajo para simular elevación)
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              textAlign: TextAlign.justify,
                              textfinal,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}

class SignaturePage extends StatefulWidget {
  const SignaturePage({super.key});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  VideoPlayerController? _videoPlayerController;
  Uint8List? _signatureBytes;

  Future<void> _saveSignature() async {
    _signatureBytes = await _controller.toPngBytes();
    setState(() {
      _isSignatureEmpty = _signatureBytes == null;
    });

    if (!_isSignatureEmpty) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Vista Previa de Firma'),
          content: Image.memory(
            _signatureBytes!,
            width: 400,
            height: 200,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearSignature();
              },
              child: Text(
                'Cancelar',
                style: TextStyle(fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () {
                _confirmSaveSignature();
                Navigator.of(context).pop();
              },
              child: Text(
                'Guardar',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposeVideoPlayer();
    super.dispose();
  }

  void _disposeVideoPlayer() {
    _videoPlayerController!.pause();
    _videoPlayerController!.dispose();
  }

/*   void _confirmSaveSignature() async {
    final cubit = context.read<StepCounterCubit>();
    String dia = cubit.state.dia.toString();
    String mes = cubit.state.mes.toString();
    String year = cubit.state.anio.toString();
    String fecha = '$dia-$mes-$year.';

    final result = await Permission.manageExternalStorage.request();
    if (result.isGranted) {
      final directory = await getExternalStorageDirectory();
      final fileName =
          '${cubit.state.selectedEmpleado!.id}_${fecha}_img.png'; // Cambia 'mi_firma.png' al nombre que desees

      fileIMG = File('${directory!.path}/$fileName');
      await fileIMG.writeAsBytes(Uint8List.fromList(_signatureBytes!));
      /* final path = await ImageGallerySaver.saveImage(
        Uint8List.fromList(_signatureBytes!),
      ); */
      print(fileIMG);
      setState(() {
        _isContainerVisible = false;
      });
      print('Imagen guardada en $fileIMG');
    }
  } */

  void _confirmSaveSignature() async {
    final cubit = context.read<StepCounterCubit>();
    String dia = cubit.state.dia.toString();
    String mes = cubit.state.mes.toString();
    String year = cubit.state.anio.toString();
    String fecha = '$dia-$mes-$year.';

    final result = await Permission.manageExternalStorage.request();
    if (result.isGranted) {
      final directory = await getExternalStorageDirectory();
      final imgDirectory = Directory('${directory!.path}/.img');

      if (!await imgDirectory.exists()) {
        await imgDirectory.create();
        // Opcional: Crea un archivo ".nomedia" para ocultar el directorio en la galería.
        final nomediaFile = File('${imgDirectory.path}/.nomedia');
        nomediaFile.createSync();
      }

      final fileName = '${cubit.state.selectedEmpleado!.id}_${fecha}_img.txt';
      fileIMG = File('${imgDirectory.path}/$fileName');

      // Convierte los bytes de la imagen en una cadena Base64
      String base64Image = base64Encode(Uint8List.fromList(_signatureBytes!));

      // Guarda la cadena Base64 en el archivo .txt
      await fileIMG.writeAsString(base64Image);

      setState(() {
        _isContainerVisible = false;
      });
    }
  }

  void _clearSignature() {
    _controller.clear();
    setState(() {
      _isSignatureEmpty = true;
      _isSigning = false;
    });
  }

  void _startSigning() {
    setState(() {
      _isSigning = true;
    });
  }

  void _showImagePopup(StepCounterCubit cubit) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(13))),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        title: Text(
          'Firma Guardada',
          style: TextStyle(
              fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          height: MediaQuery.of(context).size.height / 10,
          width: MediaQuery.of(context).size.height / 10,
          child: Image.memory(
            _signatureBytes!,
            width: 500,
            height: 500,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              setState(() {
                //_isContainerVisible = true;
              });
              //cubit.resetStep();
              Navigator.of(context).pop();
            },
            child: Text('CERRAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _initVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(fileOut));
    await _videoPlayerController!.initialize();
    await _videoPlayerController!.setLooping(true);
    await _videoPlayerController!.play();
  }

  void _showVideoPopup(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<StepCounterCubit, StepCounterState>(
          builder: (context, state) {
            final cubit = context.read<StepCounterCubit>();
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(13))),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                title: const Text(
                  'Vista Previa',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                content: FutureBuilder(
                  future: _initVideoPlayer(),
                  builder: (context, state) {
                    if (state.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                            height: MediaQuery.of(context).size.height,
                            width: 500,
                            child: VideoPlayer(_videoPlayerController!)),
                      );
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      _disposeVideoPlayer();
                      Navigator.of(context).pop(); // Cerrar el diálogo
                    },
                    child: const Text(
                      'CERRAR',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
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
        final cubit = context.read<StepCounterCubit>();
        String text;
        String textfinal;
        String dia = cubit.state.dia.toString();
        String mes = cubit.state.mes.toString();
        String year = cubit.state.anio.toString();
        String hora = cubit.state.hora.format(context);
        String fecha = '$dia de $mes de $year.';
        String cedula = selectedEmpleado?.cedula ?? '';
        String empresa = selectedEmpleado?.empresa ?? '';

        List<int> bytes = base64.decode(logoEncontrado.split('.').last);

        text = cubit.state.contenidoC.toString();
        textfinal =
            text.replaceAll("@nombre_empleado", selectedEmpleado?.name ?? '');
        textfinal = textfinal.replaceAll('@HORA', '');
        textfinal = textfinal.replaceAll('@HORA', '');
        textfinal = textfinal.replaceAll('@FECHA_DIA', fecha);
        textfinal = textfinal.replaceAll('@FECHA_DIA', fecha);
        textfinal = textfinal.replaceAll('@cedula_empleado', cedula);
        textfinal = textfinal.replaceAll('@cedula_empleado', cedula);
        textfinal = textfinal.replaceAll('@empresa', empresa);
        textfinal = textfinal.replaceAll('@empresa', empresa);

        return SizedBox(
          width: widthP.width,
          height: heightP.height,
          child: Column(children: [
            Container(
                width: widthP.width / 2 + 220,
                height: heightP.height / 2,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          cubit.state.titulo.toString(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xff182844)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 13, bottom: 13),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              bytes == ''
                                  ? Image.memory(Uint8List.fromList(bytes))
                                  : Container()
                            ],
                          ),
                        ),
                        Text(
                          textAlign: TextAlign.justify,
                          textfinal,
                          style: const TextStyle(fontSize: 15),
                        )
                      ],
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.2), // Color de la sombra
                      spreadRadius: -3, // Cuánto se extiende la sombra
                      blurRadius: 3, // Cuánto se difumina la sombra
                      offset: Offset(-1,
                          2), // Desplazamiento de la sombra (positivo hacia abajo para simular elevación)
                    ),
                  ],
                )),
            const SizedBox(height: 5.0),
            if (_isContainerVisible)
              Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: widthP.width / 10, vertical: 5),
                  child: Column(
                    children: [
                      GestureDetector(
                        onPanStart: (_) {
                          _startSigning();
                        },
                        child: Container(
                          width: widthP.width,
                          height: heightP.height / 6 - 10,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.0), // Color de la sombra
                                spreadRadius:
                                    -3, // Cuánto se extiende la sombra
                                blurRadius: 3, // Cuánto se difumina la sombra
                                offset: Offset(-1,
                                    2), // Desplazamiento de la sombra (positivo hacia abajo para simular elevación)
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text('Firma aqui',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                      fontFamily: 'Manrope',
                                      fontSize: 11)),
                              Container(
                                width: widthP.width,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: GestureDetector(
                                    onPanStart: (_) {
                                      _startSigning();
                                    },
                                    child: Signature(
                                      height: heightP.height / 10,
                                      width: widthP.width / 2 + 100,
                                      controller: _controller,
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              //  if (_isSigning)
                              IconButton(
                                icon: Icon(Icons.check),
                                onPressed: _saveSignature,
                              ),
                              // if (_isSigning)
                              IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: _clearSignature,
                              ),
                            ],
                          ))
                    ],
                  ))
            else
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _showVideoPopup(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10)),
                            width: widthP.width / 3 + 10,
                            height: heightP.height / 16,
                            child: const Center(
                                child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Ver Grabación',
                                  style: TextStyle(
                                      fontSize: 17,
                                      color: Colors.white,
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.bold),
                                ),
                                Icon(
                                  size: 28,
                                  Icons.videocam_outlined,
                                  color: Colors.white,
                                )
                              ],
                            )),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _showImagePopup(cubit);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10)),
                            width: widthP.width / 3,
                            height: heightP.height / 16,
                            child: const Center(
                                child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Ver Firma',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  Icons.mode_edit_outline_outlined,
                                  color: Colors.white,
                                  size: 28,
                                )
                              ],
                            )),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(35.0),
                      child: GestureDetector(
                        child: ButtonFinish(),
                        onTap: () {
                          setState(() {
                            _isContainerVisible = true;
                          });
                        },
                      ),
                    )
                  ],
                ),
              )
          ]),
        );
      },
    );
  }
}
