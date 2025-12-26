import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// ═══════════════════════════════════════════════════════════════════════════
/// IlkYilbasimiz - Firebase Auth + Firestore + Storage
/// 
/// Fotoğraflar Firebase Storage'a yüklenir, URL'leri Firestore'da saklanır.
/// ═══════════════════════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCg9rnnAc4_wImrHP9Fd9jY6joDk4W6pfg',
      appId: '1:849678696768:web:6ea247d53872e041783aa5',
      messagingSenderId: '849678696768',
      projectId: 'ilkyilbasimiz',
      storageBucket: 'ilkyilbasimiz.firebasestorage.app',
    ),
  );
  
  runApp(const IlkYilbasimizApp());
}

// ═══════════════════════════════════════════════════════════════════════════
// ANA UYGULAMA
// ═══════════════════════════════════════════════════════════════════════════

class IlkYilbasimizApp extends StatelessWidget {
  const IlkYilbasimizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İlk Yılbaşımız',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE11D48), width: 2),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTH WRAPPER
// ═══════════════════════════════════════════════════════════════════════════

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFE11D48))),
          );
        }
        if (snapshot.hasData) return const KokinaHome();
        return const LoginScreen();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'Bir hata oluştu. Tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password': return 'Şifre yanlış. Tekrar deneyin.';
      case 'invalid-email': return 'Geçersiz e-posta adresi.';
      case 'invalid-credential': return 'E-posta veya şifre hatalı.';
      default: return 'Giriş yapılamadı. Bilgilerinizi kontrol edin.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ...List.generate(25, (index) => const _Snowflake()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("🎄", style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 16),
                    const Text("İlk Yılbaşımız", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text("Sadece bizim için...", style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.6), fontStyle: FontStyle.italic)),
                    const SizedBox(height: 48),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'E-posta', hintStyle: TextStyle(color: Colors.white38), prefixIcon: Icon(Icons.email_outlined, color: Colors.white38)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Şifre', hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      onSubmitted: (_) => _signIn(),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 14))),
                        ]),
                      ),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8, shadowColor: const Color(0xFFE11D48).withOpacity(0.4)),
                        child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Giriş Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text("💕 B & B 💕", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KOKINA HOME
// ═══════════════════════════════════════════════════════════════════════════

class KokinaHome extends StatefulWidget {
  const KokinaHome({super.key});

  @override
  State<KokinaHome> createState() => _KokinaHomeState();
}

class _KokinaHomeState extends State<KokinaHome> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isTextVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..forward().then((_) { if (mounted) setState(() => _isTextVisible = true); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _signOut() async => await FirebaseAuth.instance.signOut();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          ...List.generate(40, (index) => const _Snowflake()),
          Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenSize.height),
                child: FittedBox(
                  fit: BoxFit.scaleDown, alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 10),
                        SizedBox(width: 380, height: 500, child: CustomPaint(painter: KokinaPainter(animation: _controller))),
                        const SizedBox(height: 20),
                        Row(mainAxisSize: MainAxisSize.min, children: [_buildRestartButton(), const SizedBox(width: 12), _buildGalleryButton()]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40, right: 16,
            child: AnimatedOpacity(opacity: _isTextVisible ? 1.0 : 0.0, duration: const Duration(milliseconds: 500),
              child: IconButton(onPressed: _signOut, icon: const Icon(Icons.logout, color: Colors.white54), tooltip: 'Çıkış Yap')),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => AnimatedOpacity(
    opacity: _isTextVisible ? 1.0 : 0.0, duration: const Duration(milliseconds: 2000),
    child: const Column(children: [
      Text("B💗B", style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8, shadows: [Shadow(color: Color(0xFFE11D48), blurRadius: 30)])),
      SizedBox(height: 10),
      Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("\"Eskiler Kokina şans getirir derler;\nbenim bu hayattaki en büyük şansım sensin.\"", textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, color: Color(0xFFFCA5A5), height: 1.5))),
    ]),
  );

  Widget _buildRestartButton() => AnimatedOpacity(
    opacity: _isTextVisible ? 1.0 : 0.0, duration: const Duration(milliseconds: 1000),
    child: ElevatedButton.icon(
      onPressed: _controller.isAnimating ? null : () { setState(() { _isTextVisible = false; _controller.reset(); _controller.forward().then((_) { if (mounted) setState(() => _isTextVisible = true); }); }); },
      icon: const Icon(Icons.refresh, size: 18), label: const Text("Tekrar"),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF374151), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
    ),
  );

  Widget _buildGalleryButton() => AnimatedOpacity(
    opacity: _isTextVisible ? 1.0 : 0.0, duration: const Duration(milliseconds: 1000),
    child: ElevatedButton.icon(
      onPressed: _isTextVisible ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryPage())) : null,
      icon: const Icon(Icons.photo_library, size: 18), label: const Text("Anılarımıza Yolculuk"),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// GALLERY PAGE - Firebase Storage URL'leri ile fotoğraf gösterimi
// ═══════════════════════════════════════════════════════════════════════════

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).pop());
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Anılarımız 💕'), backgroundColor: const Color(0xFF0B0F19), elevation: 0),
      backgroundColor: const Color(0xFF0B0F19),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('fotograflar').orderBy('yuklenmeTarihi', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48)));
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.photo_album_outlined, size: 80, color: Colors.white24),
              SizedBox(height: 16),
              Text('Henüz anı yok.\nİlk fotoğrafı eklemek için + butonuna tıkla!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16)),
            ]));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final imageUrl = data['url'] as String?;
              final storagePath = data['storagePath'] as String?;

              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        if (imageUrl != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImage(imageUrl: imageUrl)));
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(color: Colors.white10, child: const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48), strokeWidth: 2)));
                                },
                                errorBuilder: (context, error, stackTrace) => Container(color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24)),
                              )
                            : Container(color: Colors.white10, child: const Icon(Icons.image_not_supported, color: Colors.white24)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: () => _showDeleteConfirmation(context, doc.id, storagePath),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _pickAndUploadImage(context), backgroundColor: const Color(0xFFE11D48), child: const Icon(Icons.add_a_photo)),
    );
  }

  /// Silme onay dialogu - Hem Firestore hem Storage'dan siler
  void _showDeleteConfirmation(BuildContext context, String docId, String? storagePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Anıyı Sil', style: TextStyle(color: Colors.white)),
        content: const Text('Bu anıyı silmek istediğine emin misin?\nBu işlem geri alınamaz.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Önce Storage'dan sil
                if (storagePath != null) {
                  await FirebaseStorage.instance.ref(storagePath).delete();
                }
                // Sonra Firestore'dan sil
                await FirebaseFirestore.instance.collection('fotograflar').doc(docId).delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anı silindi 🗑️'), backgroundColor: Color(0xFF374151)));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Sil', style: TextStyle(color: Color(0xFFE11D48))),
          ),
        ],
      ),
    );
  }

  /// Firebase Storage'a yükle, URL'i Firestore'a kaydet
  Future<void> _pickAndUploadImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 70);
      if (image == null) return;

      if (context.mounted) {
        showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48))));
      }

      // Benzersiz dosya adı oluştur
      final String fileName = 'anlar/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      // Platforma göre yükle
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await storageRef.putFile(File(image.path));
      }

      // Download URL al
      final String downloadUrl = await storageRef.getDownloadURL();

      // Firestore'a kaydet (URL ve Storage path)
      await FirebaseFirestore.instance.collection('fotograflar').add({
        'url': downloadUrl,
        'storagePath': fileName,
        'yuklenmeTarihi': FieldValue.serverTimestamp(),
        'yukleyenKullanici': FirebaseAuth.instance.currentUser?.email,
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anı başarıyla eklendi! 💕'), backgroundColor: Color(0xFFE11D48)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FULL SCREEN IMAGE - Tam ekran görünüm ve zoom
// ═══════════════════════════════════════════════════════════════════════════

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      extendBodyBehindAppBar: true,
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5, maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48)));
            },
            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 80)),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KOKINA PAINTER
// ═══════════════════════════════════════════════════════════════════════════

class KokinaPainter extends CustomPainter {
  final Animation<double> animation;
  KokinaPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final center = Offset(size.width / 2, size.height - 40);
    
    final stemPaint = Paint()..color = const Color(0xFF3E2723)..strokeWidth = 5.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final leafPaint = Paint()..color = const Color(0xFF133213)..style = PaintingStyle.fill;

    final List<Map<String, Offset>> stems = [
      {'c1': Offset(center.dx - 40, center.dy - 120), 'c2': Offset(center.dx + 40, center.dy - 250), 'e': Offset(center.dx, center.dy - 380)},
      {'c1': Offset(center.dx - 60, center.dy - 100), 'c2': Offset(center.dx - 80, center.dy - 220), 'e': Offset(center.dx - 70, center.dy - 350)},
      {'c1': Offset(center.dx + 60, center.dy - 100), 'c2': Offset(center.dx + 80, center.dy - 220), 'e': Offset(center.dx + 70, center.dy - 350)},
      {'c1': Offset(center.dx - 90, center.dy - 80), 'c2': Offset(center.dx - 130, center.dy - 180), 'e': Offset(center.dx - 120, center.dy - 300)},
      {'c1': Offset(center.dx + 90, center.dy - 80), 'c2': Offset(center.dx + 130, center.dy - 180), 'e': Offset(center.dx + 120, center.dy - 300)},
      {'c1': Offset(center.dx - 140, center.dy - 60), 'c2': Offset(center.dx - 200, center.dy - 140), 'e': Offset(center.dx - 180, center.dy - 240)},
      {'c1': Offset(center.dx + 140, center.dy - 60), 'c2': Offset(center.dx + 200, center.dy - 140), 'e': Offset(center.dx + 180, center.dy - 240)},
    ];

    for (var s in stems) {
      final path = Path()..moveTo(center.dx, center.dy)..cubicTo(s['c1']!.dx, s['c1']!.dy, s['c2']!.dx, s['c2']!.dy, s['e']!.dx, s['e']!.dy);
      ui.PathMetrics metrics = path.computeMetrics();
      for (ui.PathMetric metric in metrics) {
        canvas.drawPath(metric.extractPath(0, metric.length * math.min(t * 1.6, 1.0)), stemPaint);
      }
      if (t > 0.25) {
        for (int i = 1; i <= 8; i++) {
          if (t > 0.25 + (i * 0.07)) {
            final pos = _calculateBezierPoint(i / 9, center, s['c1']!, s['c2']!, s['e']!);
            _drawLeaf(canvas, pos, (i % 2 == 0 ? 0.8 : -0.8), leafPaint);
          }
        }
      }
      if (t > 0.8) {
        _drawBerryCluster(canvas, s['e']!, 15);
        _drawBerryCluster(canvas, _calculateBezierPoint(0.6, center, s['c1']!, s['c2']!, s['e']!), 10);
      }
    }
    if (t > 0.9) _drawBerryCluster(canvas, center, 20);
  }

  void _drawLeaf(Canvas canvas, Offset pos, double angle, Paint paint) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    final leaf = Path()..moveTo(0, 0)..quadraticBezierTo(15, -15, 0, -35)..quadraticBezierTo(-15, -15, 0, 0);
    canvas.drawPath(leaf, paint);
    canvas.restore();
  }

  void _drawBerryCluster(Canvas canvas, Offset pos, int count) {
    final rand = math.Random(pos.hashCode);
    for (int i = 0; i < count; i++) {
      final offset = Offset(pos.dx + (rand.nextDouble() - 0.5) * 50, pos.dy + (rand.nextDouble() - 0.5) * 50);
      final paint = Paint()..shader = ui.Gradient.radial(offset, 8, [const Color(0xFFFF6B6B), const Color(0xFFD11212)]);
      canvas.drawCircle(offset, 8.5, paint);
    }
  }

  Offset _calculateBezierPoint(double t, Offset p0, Offset p1, Offset p2, Offset p3) {
    final u = 1 - t;
    return Offset(
      math.pow(u, 3) * p0.dx + 3 * math.pow(u, 2) * t * p1.dx + 3 * u * math.pow(t, 2) * p2.dx + math.pow(t, 3) * p3.dx,
      math.pow(u, 3) * p0.dy + 3 * math.pow(u, 2) * t * p1.dy + 3 * u * math.pow(t, 2) * p2.dy + math.pow(t, 3) * p3.dy,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// SNOWFLAKE
// ═══════════════════════════════════════════════════════════════════════════

class _Snowflake extends StatelessWidget {
  const _Snowflake();
  @override
  Widget build(BuildContext context) {
    final r = math.Random();
    return Positioned(top: r.nextDouble() * 1000, left: r.nextDouble() * 500,
      child: Opacity(opacity: r.nextDouble() * 0.4 + 0.1, child: Icon(Icons.ac_unit, color: Colors.white, size: r.nextDouble() * 12 + 6)));
  }
}