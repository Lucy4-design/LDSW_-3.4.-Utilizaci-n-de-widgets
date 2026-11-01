import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catálogo de Películas',
      debugShowCheckedModeBanner: false, // Elimina la etiqueta roja de DEBUG
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PASO 1: Widget de diseño (Layout Widget)
      // Stack nos permite superponer elementos uno encima del otro.
      body: Stack(
        fit: StackFit.expand, // Obliga al Stack a ocupar toda la pantalla disponible
        children: [
          
          // PASO 2 y 3: Widgets visibles agregados al Stack
          
          // 1. WIDGET IMAGE: Imagen de fondo
          // Usamos Image.network para cargar una imagen de internet sin configurar assets locales aún.
          Image.network(
            'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=1000&auto=format&fit=crop',
            fit: BoxFit.cover, // Clave: hace que la imagen cubra todo el espacio sin deformarse
          ),
          
          // Capa de oscurecimiento (UX Pro Tip): 
          // Un Container semitransparente para garantizar que el texto blanco sea legible sobre cualquier imagen.
          Container(
            color: Colors.black.withOpacity(0.6),
          ),

          // 2. WIDGET COLUMN (dentro de un Center): Para organizar el contenido verticalmente
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente
              crossAxisAlignment: CrossAxisAlignment.center, // Centra horizontalmente
              children: [
                
                // 3. WIDGET ICON: Ícono representativo de la aplicación
                const Icon(
                  Icons.local_movies, // Ícono de cine/película de la librería de Material
                  size: 80.0,
                  color: Colors.white,
                ),
                
                const SizedBox(height: 20), // Espacio en blanco separador
                
                // 4. WIDGET TEXT: Nombre de la aplicación
                const Text(
                  'CineSync',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0, // Espaciado entre letras para elegancia
                  ),
                ),
                
                const SizedBox(height: 10), // Espacio en blanco separador
                
                // 5. WIDGET TEXT: Mensaje de bienvenida / Criterio de evaluación "Hello World"
                const Text(
                  'Hello World',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70, // Un blanco ligeramente transparente para jerarquía visual
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}