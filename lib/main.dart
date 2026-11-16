import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // Este archivo fue generado por flutterfire configure

void main() async {
  // 1. Asegurar que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inicializar Firebase con las opciones de tu plataforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catálogo de Películas',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const PantallaPeliculas(),
    );
  }
}

class PantallaPeliculas extends StatefulWidget {
  const PantallaPeliculas({super.key});

  @override
  State<PantallaPeliculas> createState() => _PantallaPeliculasState();
}

class _PantallaPeliculasState extends State<PantallaPeliculas> {
  // Referencia a la colección "peliculas" en Firestore
  final CollectionReference peliculas = FirebaseFirestore.instance.collection('peliculas');
  
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _generoController = TextEditingController();
  final TextEditingController _anioController = TextEditingController();

  // FUNCIÓN CLAVE: Agregar película a Firebase Firestore
  Future<void> agregarPelicula() async {
    if (_tituloController.text.isEmpty) return;

    await peliculas.add({
      'titulo': _tituloController.text,
      'genero': _generoController.text,
      'anio': int.tryParse(_anioController.text) ?? 0,
      'fecha_creacion': FieldValue.serverTimestamp(),
    });

    // Limpiar campos después de guardar
    _tituloController.clear();
    _generoController.clear();
    _anioController.clear();

    // Mostrar confirmación al usuario
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Película agregada exitosamente a Firebase!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Películas'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Formulario para agregar datos
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título de la película',
                        prefixIcon: Icon(Icons.movie),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _generoController,
                      decoration: const InputDecoration(
                        labelText: 'Género',
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _anioController,
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: agregarPelicula,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Agregar a Firebase'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Películas guardadas en la nube:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // Leer películas en tiempo real desde Firebase
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: peliculas.orderBy('fecha_creacion', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No hay películas aún. ¡Agrega una!'),
                    );
                  }
                  
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_movies, color: Colors.deepPurple, size: 40),
                          title: Text(
                            data['titulo'] ?? 'Sin título',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${data['genero']} • ${data['anio']}'),
                          isThreeLine: false,
                        ),
                      );
                    },
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