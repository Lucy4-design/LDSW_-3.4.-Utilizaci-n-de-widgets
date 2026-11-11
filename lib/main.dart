import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 1. Importamos el paquete HTTP
import 'dart:convert'; // 2. Importamos para convertir JSON a objetos Dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consumo de API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      home: const PokemonScreen(),
    );
  }
}

// 3. Usamos StatefulWidget porque el estado de la pantalla cambiará 
// (de "cargando" a "mostrando datos" o "error").
class PokemonScreen extends StatefulWidget {
  const PokemonScreen({super.key});

  @override
  State<PokemonScreen> createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  // 4. Función asíncrona que hace la petición a Internet
  Future<Map<String, dynamic>> fetchPokemon() async {
    // Hacemos la petición GET a la URL de la PokéAPI (Pikachu)
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/pikachu'));

    // 5. Verificamos si la respuesta fue exitosa (Código 200)
    if (response.statusCode == 200) {
      // Si es exitosa, decodificamos el texto JSON a un Map de Dart
      return jsonDecode(response.body);
    } else {
      // Si falla (ej. sin internet), lanzamos una excepción
      throw Exception('Fallo al cargar los datos del Pokémon');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos desde Internet'),
        backgroundColor: Colors.redAccent,
      ),
      // 6. FutureBuilder: El widget mágico que maneja los 3 estados de una petición
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchPokemon(), // Le decimos qué función asíncrona ejecutar
        builder: (context, snapshot) {
          // ESTADO A: Aún está cargando los datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          // ESTADO B: Ocurrió un error
          else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            );
          } 
          // ESTADO C: Los datos llegaron correctamente
          else if (snapshot.hasData) {
            final pokemon = snapshot.data!;
            
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Imagen obtenida de la URL que nos dio la API
                  Image.network(
                    pokemon['sprites']['front_default'],
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  // Nombre capitalizado (ej: "Pikachu")
                  Text(
                    pokemon['name'].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Mostramos un dato numérico (ej: altura)
                  Text(
                    'Altura: ${pokemon['height']} decímetros',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          // Estado por defecto (no debería alcanzarse)
          return const Center(child: Text('Sin datos'));
        },
      ),
    );
  }
}