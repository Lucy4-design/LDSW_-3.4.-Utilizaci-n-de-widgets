import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catálogo de Películas',
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const AuthWrapper(),
    );
  }
}

// ==========================================
// 1. PANTALLA DE INICIO / AUTENTICACIÓN
// ==========================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const MainScreen(); // Usuario logueado
        }
        return const LoginScreen(); // Usuario no logueado
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  String _error = '';

  Future<void> _submit() async {
    setState(() => _error = '');
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Error de autenticación');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenido')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_filter, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock)), obscureText: true),
            if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: Text(_isLogin ? 'Ingresar' : 'Registrarse')),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión'),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. PANTALLA PRINCIPAL CON MENÚ SUPERIOR
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [CatalogScreen(), AdminScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Películas'),
        actions: [
          // Menú en la parte superior
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              if (value == 'catalogo') setState(() => _currentIndex = 0);
              if (value == 'admin') setState(() => _currentIndex = 1);
              if (value == 'logout') FirebaseAuth.instance.signOut();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'catalogo', child: Row(children: [Icon(Icons.movie), SizedBox(width: 10), Text('Catálogo')])),
              const PopupMenuItem(value: 'admin', child: Row(children: [Icon(Icons.admin_panel_settings), SizedBox(width: 10), Text('Administración')])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 10), Text('Cerrar Sesión', style: TextStyle(color: Colors.red))])),
            ],
          )
        ],
      ),
      body: _screens[_currentIndex],
    );
  }
}

// ==========================================
// 3. PANTALLA DE CATÁLOGO
// ==========================================
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final collection = FirebaseFirestore.instance.collection('peliculas');
    return StreamBuilder<QuerySnapshot>(
      stream: collection.orderBy('fecha_creacion', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No hay películas en el catálogo.'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(data['url_imagen'] ?? 'https://via.placeholder.com/50', width: 50, height: 75, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 50)),
                ),
                title: Text(data['titulo'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${data['genero']} • ${data['anio']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(movieId: id, data: data))),
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 4. PANTALLA DE DESCRIPCIÓN DETALLADA
// ==========================================
class DetailScreen extends StatelessWidget {
  final String movieId;
  final Map<String, dynamic> data;
  const DetailScreen({super.key, required this.movieId, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de la Película')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(data['url_imagen'] ?? 'https://via.placeholder.com/400x200', fit: BoxFit.cover, width: double.infinity, height: 250, errorBuilder: (_, _, _) => Container(height: 250, color: Colors.grey, child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white)))),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['titulo'] ?? 'Sin título', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Chip(label: Text(data['anio']?.toString() ?? 'N/A')),
                    const SizedBox(width: 8),
                    Chip(label: Text(data['genero'] ?? 'N/A'), backgroundColor: Colors.deepPurple.shade100),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Director:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(data['director'] ?? 'Desconocido', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text('Sinopsis:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(data['sinopsis'] ?? 'Sin descripción disponible.', style: const TextStyle(fontSize: 16, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. PANTALLA DE ADMINISTRACIÓN (Alta y Baja)
// ==========================================
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  final _directorCtrl = TextEditingController();
  final _generoCtrl = TextEditingController();
  final _sinopsisCtrl = TextEditingController();
  final _imagenCtrl = TextEditingController();
  bool _isLoading = false;

  final collection = FirebaseFirestore.instance.collection('peliculas');

  Future<void> _addMovie() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await collection.add({
      'titulo': _tituloCtrl.text,
      'anio': int.tryParse(_anioCtrl.text) ?? 0,
      'director': _directorCtrl.text,
      'genero': _generoCtrl.text,
      'sinopsis': _sinopsisCtrl.text,
      'url_imagen': _imagenCtrl.text,
      'fecha_creacion': FieldValue.serverTimestamp(),
    });
    _formKey.currentState!.reset();
    _tituloCtrl.clear(); _anioCtrl.clear(); _directorCtrl.clear(); _generoCtrl.clear(); _sinopsisCtrl.clear(); _imagenCtrl.clear();
    setState(() => _isLoading = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Película agregada exitosamente'), backgroundColor: Colors.green));
  }

  Future<void> _deleteMovie(String id) async {
    await collection.doc(id).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Película eliminada'), backgroundColor: Colors.red));
  }

  // ==========================================
  // REQUISITO: SOLICITUDES EN HTTP
  // ==========================================
  Future<void> _fetchFromAPI() async {
    setState(() => _isLoading = true);
    try {
      // ✅ URL ACTUALIZADA: Esta versión de la API SÍ permite conexiones desde la web (CORS)
      final response = await http.get(Uri.parse('https://ghibliapi.vercel.app/films'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final randomMovie = data[0]; // Toma la primera película como ejemplo
        
        await collection.add({
          'titulo': randomMovie['title'],
          'anio': int.tryParse(randomMovie['release_date']) ?? 0,
          'director': randomMovie['director'],
          'genero': 'Animación / Fantasía',
          'sinopsis': randomMovie['description'],
          'url_imagen': randomMovie['image'],
          'fecha_creacion': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Película importada desde API (HTTP) exitosamente!'), backgroundColor: Colors.blue)
          );
        }
      } else {
        throw Exception('Error en la respuesta HTTP: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error HTTP: $e'), backgroundColor: Colors.red)
        );
      }
    }
    setState(() => _isLoading = false);
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchFromAPI,
            icon: const Icon(Icons.cloud_download),
            label: const Text('Cargar película desde API (HTTP)'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
          ),
          const SizedBox(height: 16),
          const Text('Dar de Alta una Película', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(controller: _tituloCtrl, decoration: const InputDecoration(labelText: 'Título'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  TextFormField(controller: _anioCtrl, decoration: const InputDecoration(labelText: 'Año'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  TextFormField(controller: _directorCtrl, decoration: const InputDecoration(labelText: 'Director'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  TextFormField(controller: _generoCtrl, decoration: const InputDecoration(labelText: 'Género'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  TextFormField(controller: _sinopsisCtrl, decoration: const InputDecoration(labelText: 'Sinopsis'), maxLines: 3, validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  TextFormField(controller: _imagenCtrl, decoration: const InputDecoration(labelText: 'URL de la imagen'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _isLoading ? null : _addMovie, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text('Guardar Película')),
                  const SizedBox(height: 24),
                  const Text('Películas Registradas (Dar de Baja)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: collection.orderBy('fecha_creacion', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(data['titulo']),
                            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteMovie(doc.id)),
                          );
                        },
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}