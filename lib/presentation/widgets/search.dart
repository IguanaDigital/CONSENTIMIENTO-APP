import 'package:consentimiento/config/model/model.dart';
import 'package:flutter/Material.dart';

class EmpleadoSearchDelegate extends SearchDelegate<Empleado> {
  final List<Empleado> empleados;

  EmpleadoSearchDelegate(this.empleados);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(
            context, empleados.isNotEmpty ? empleados.first : null as Empleado);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = empleados
        .where((empleado) =>
            empleado.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    /* final results = empleados
        .where((empleado) =>
            empleado.name.toLowerCase().contains(query.toLowerCase()))
        .toList(); */

    return ListView(
      children: results.map((empleado) {
        return ListTile(
          title: Text(empleado.name),
          onTap: () {
            close(context, empleado);
          },
        );
      }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = empleados
        .where((empleado) =>
            empleado.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      child: ListView(
        itemExtent: 50,
        children: results.map((empleado) {
          return ListTile(
            title: Text(
              empleado.name,
              style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            subtitle: Text(
              empleado.empresa,
              style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.normal,
                  fontSize: 14),
            ),
            onTap: () {
              close(context, empleado);
            },
          );
        }).toList(),
      ),
    );
  }
}
