// lib/features/doctors/presentation/pages/doctors_page.dart

import 'package:flutter/material.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({Key? key}) : super(key: key);

  @override
  _DoctorsPageState createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  final _searchController = TextEditingController();
  List<String> _results = []; // Aquí podrías usar un modelo Doctor real

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim().toLowerCase();
    // TODO: reemplaza por llamada real a tu repositorio de doctores
    setState(() {
      _results = (['Dr. Ana Pérez', 'Dr. Luis Gómez', 'Dra. Carla Ruiz']
            .where((name) => name.toLowerCase().contains(query))
            .toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar doctor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Campo de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nombre del doctor',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _onSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
            const SizedBox(height: 16),
            // Resultados
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final name = _results[i];
                        return ListTile(
                          title: Text(name),
                          trailing: ElevatedButton(
                            onPressed: () {
                              // TODO: lógica para “vincular” o agendar cita
                            },
                            child: const Text('Seleccionar'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
