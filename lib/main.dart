import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'productos.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ota_update/ota_update.dart';

// Versión local de la aplicación
const String kAppVersion = "1.5.3";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCzUZ7YBAUMgG-iuMhXqzoqyfKEJi-iC9M",
      appId: "1:822787207011:android:403933ab204bb6c5bcad56",
      messagingSenderId: "822787207011",
      projectId: "soe-cosmeticos",
    ),
  );
  runApp(const SoeApp());
}

// ==========================================
// ALMACENAMIENTO SEGURO (ANDROID KEYSTORE AES-256)
// ==========================================
const _storage = FlutterSecureStorage();

Future<void> guardarCredencialesSeguras({
  required String usuario,
  required String clave,
  required String nombre,
  required String rol,
  required bool recordar,
}) async {
  if (recordar) {
    await _storage.write(key: 'soe_usuario', value: usuario);
    await _storage.write(key: 'soe_clave', value: clave);
    await _storage.write(key: 'soe_nombre', value: nombre);
    await _storage.write(key: 'soe_rol', value: rol);
    await _storage.write(key: 'soe_recordar', value: 'true');
  } else {
    await _storage.deleteAll();
  }
}

Future<Map<String, String?>> leerCredencialesSeguras() async {
  final usuario = await _storage.read(key: 'soe_usuario');
  final clave = await _storage.read(key: 'soe_clave');
  final nombre = await _storage.read(key: 'soe_nombre');
  final rol = await _storage.read(key: 'soe_rol');
  final recordar = await _storage.read(key: 'soe_recordar');
  return {
    'usuario': usuario,
    'clave': clave,
    'nombre': nombre,
    'rol': rol,
    'recordar': recordar,
  };
}

void confirmarSalidaApp(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Salir de la app'),
      content: const Text('¿Estás seguro de que deseas cerrar la aplicación?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
          onPressed: () {
            Navigator.pop(ctx);
            SystemNavigator.pop();
          },
          child: const Text('Salir', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// Comparador semántico de versiones (ej: 1.5.2 < 1.5.3)
bool esVersionMenor(String versionActual, String versionRequerida) {
  try {
    List<int> parseV(String v) => v.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> act = parseV(versionActual);
    List<int> req = parseV(versionRequerida);
    int maxLen = act.length > req.length ? act.length : req.length;
    for (int i = 0; i < maxLen; i++) {
      int a = i < act.length ? act[i] : 0;
      int r = i < req.length ? req[i] : 0;
      if (a < r) return true;
      if (a > r) return false;
    }
    return false;
  } catch (_) {
    return false;
  }
}

// Formateador estándar de fecha y hora
String formatearFechaHora(dynamic timestamp) {
  if (timestamp == null) return "Sin fecha";
  DateTime fecha;
  if (timestamp is Timestamp) {
    fecha = timestamp.toDate();
  } else if (timestamp is DateTime) {
    fecha = timestamp;
  } else {
    return "Sin fecha";
  }
  int hora = fecha.hour;
  String periodo = hora >= 12 ? 'PM' : 'AM';
  int hora12 = hora > 12 ? hora - 12 : (hora == 0 ? 12 : hora);
  String d = fecha.day.toString().padLeft(2, '0');
  String m = fecha.month.toString().padLeft(2, '0');
  String y = fecha.year.toString();
  String min = fecha.minute.toString().padLeft(2, '0');
  return "$d/$m/$y ${hora12.toString().padLeft(2, '0')}:$min $periodo";
}

// Correlativos atómicos en Firestore
Future<int> _obtenerSiguienteNumeroPedido() async {
  final docRef = FirebaseFirestore.instance.collection('contadores').doc('pedidos');
  return await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(docRef);
    int siguiente = 1;
    if (snapshot.exists && snapshot.data() != null && snapshot.data()!['correlativo'] != null) {
      siguiente = (snapshot.data()!['correlativo'] as num).toInt() + 1;
    }
    transaction.set(docRef, {'correlativo': siguiente}, SetOptions(merge: true));
    return siguiente;
  });
}

Future<String> _generarCodigoCliente() async {
  final docRef = FirebaseFirestore.instance.collection('contadores').doc('clientes');
  int siguiente = await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(docRef);
    int valor = 1;
    if (snapshot.exists && snapshot.data() != null && snapshot.data()!['correlativo'] != null) {
      valor = (snapshot.data()!['correlativo'] as num).toInt() + 1;
    }
    transaction.set(docRef, {'correlativo': valor}, SetOptions(merge: true));
    return valor;
  });
  return "CLSOE-${siguiente.toString().padLeft(3, '0')}";
}

// ==========================================
// REPORTES EXCEL
// ==========================================
Future<void> exportarReporteExcel({
  required BuildContext context,
  String? filtroVendedorCodigo,
  String? filtroClienteRif,
  String tituloReporte = "Ventas_Globales",
}) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando reporte Excel completo...')),
    );

    Query query = FirebaseFirestore.instance.collection('pedidos');
    if (filtroVendedorCodigo != null && filtroVendedorCodigo.isNotEmpty) {
      query = query.where('vendedor_codigo', isEqualTo: filtroVendedorCodigo);
    }
    if (filtroClienteRif != null && filtroClienteRif.isNotEmpty) {
      query = query.where('cliente_rif', isEqualTo: filtroClienteRif);
    }

    QuerySnapshot snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay ventas registradas con este criterio')),
        );
      }
      return;
    }

    List<QueryDocumentSnapshot> docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      Timestamp? tA = dataA['fecha'] as Timestamp?;
      Timestamp? tB = dataB['fecha'] as Timestamp?;
      if (tA == null && tB == null) return 0;
      if (tA == null) return 1;
      if (tB == null) return -1;
      return tB.compareTo(tA);
    });

    var excel = Excel.createExcel();
    Sheet sheet = excel['Ventas'];
    excel.setDefaultSheet('Ventas');

    sheet.appendRow([
      TextCellValue('N° PEDIDO'),
      TextCellValue('FECHA'),
      TextCellValue('ESTATUS'),
      TextCellValue('CÓD. CLIENTE'),
      TextCellValue('RIF / CÉDULA'),
      TextCellValue('CLIENTE'),
      TextCellValue('DIRECCIÓN'),
      TextCellValue('OBSERVACIONES'),
      TextCellValue('CÓD. VENDEDOR'),
      TextCellValue('VENDEDOR'),
      TextCellValue('PRODUCTOS'),
      TextCellValue('CAJAS'),
      TextCellValue('BARRAS'),
      TextCellValue('TOTAL (\$)'),
    ]);

    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String fechaVenta = formatearFechaHora(data['fecha']);

      List<dynamic> productosLista = (data['productos'] as List<dynamic>?) ?? [];
      String productosTexto = productosLista
          .map((p) => "${p['nombre']} (x${p['cantidad']})")
          .join(" | ");

      sheet.appendRow([
        TextCellValue(data['numero_pedido']?.toString() ?? '#0000'),
        TextCellValue(fechaVenta),
        TextCellValue(data['estatus']?.toString() ?? 'Procesado'),
        TextCellValue(data['codigo_cliente']?.toString() ?? 'S/C'),
        TextCellValue(data['cliente_rif']?.toString() ?? 'N/A'),
        TextCellValue(data['cliente']?.toString() ?? 'N/A'),
        TextCellValue(data['direccion']?.toString() ?? 'N/A'),
        TextCellValue(data['observaciones']?.toString() ?? ''),
        TextCellValue(data['vendedor_codigo']?.toString() ?? 'N/A'),
        TextCellValue(data['vendedor']?.toString() ?? 'N/A'),
        TextCellValue(productosTexto),
        TextCellValue(data['total_cajas']?.toString() ?? '0'),
        TextCellValue(data['total_barras']?.toString() ?? '0'),
        TextCellValue(data['total_pagar']?.toString() ?? '0'),
      ]);
    }

    var fileBytes = excel.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Reporte_$tituloReporte.xlsx');
    await file.writeAsBytes(fileBytes!);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Reporte de ventas SOE: $tituloReporte',
      subject: 'Reporte de ventas SOE: $tituloReporte',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar Excel: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

Future<void> exportarRankingProductos(BuildContext context) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analizando top de productos...')),
    );

    final snapshot = await FirebaseFirestore.instance.collection('pedidos').get();
    if (snapshot.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay pedidos registrados')),
        );
      }
      return;
    }

    Map<String, int> unidadesPorProducto = {};
    Map<String, double> facturacionPorProducto = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final productos = (data['productos'] as List<dynamic>?) ?? [];
      for (var p in productos) {
        String nombre = p['nombre']?.toString() ?? 'Desconocido';
        int cantidad = (p['cantidad'] as num?)?.toInt() ?? 0;
        double subtotal = (p['subtotal'] as num?)?.toDouble() ?? 0.0;

        unidadesPorProducto[nombre] = (unidadesPorProducto[nombre] ?? 0) + cantidad;
        facturacionPorProducto[nombre] = (facturacionPorProducto[nombre] ?? 0.0) + subtotal;
      }
    }

    var ranking = unidadesPorProducto.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var excel = Excel.createExcel();
    Sheet sheet = excel['Top_Productos'];
    excel.setDefaultSheet('Top_Productos');

    sheet.appendRow([
      TextCellValue('POSICIÓN'),
      TextCellValue('PRODUCTO'),
      TextCellValue('UNIDADES VENDIDAS'),
      TextCellValue('TOTAL FACTURADO (\$)'),
    ]);

    int pos = 1;
    for (var item in ranking) {
      double total$ = facturacionPorProducto[item.key] ?? 0.0;
      sheet.appendRow([
        TextCellValue('#$pos'),
        TextCellValue(item.key),
        TextCellValue(item.value.toString()),
        TextCellValue(total$.toStringAsFixed(2)),
      ]);
      pos++;
    }

    var fileBytes = excel.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Top_Productos_SOE.xlsx');
    await file.writeAsBytes(fileBytes!);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Top de Productos - SOE Cosméticos',
      subject: 'Top de Productos - SOE Cosméticos',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar Top: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

Future<void> exportarRankingVendedores(BuildContext context) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consolidando ventas por vendedor...')),
    );

    final snapshot = await FirebaseFirestore.instance.collection('pedidos').get();
    if (snapshot.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay pedidos registrados')),
        );
      }
      return;
    }

    Map<String, Map<String, dynamic>> metricasVendedor = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      String codigo = data['vendedor_codigo']?.toString() ?? 'Sin_codigo';
      String nombre = data['vendedor']?.toString() ?? 'Sin_nombre';
      double totalPagar = (data['total_pagar'] as num?)?.toDouble() ?? 0.0;
      int barras = (data['total_barras'] as num?)?.toInt() ?? 0;
      int cajas = (data['total_cajas'] as num?)?.toInt() ?? 0;

      if (!metricasVendedor.containsKey(codigo)) {
        metricasVendedor[codigo] = {
          'nombre': nombre,
          'total_dinero': 0.0,
          'total_pedidos': 0,
          'total_barras': 0,
          'total_cajas': 0,
        };
      }

      metricasVendedor[codigo]!['total_dinero'] += totalPagar;
      metricasVendedor[codigo]!['total_pedidos'] += 1;
      metricasVendedor[codigo]!['total_barras'] += barras;
      metricasVendedor[codigo]!['total_cajas'] += cajas;
    }

    var ranking = metricasVendedor.entries.toList()
      ..sort((a, b) => (b.value['total_dinero'] as double).compareTo(a.value['total_dinero'] as double));

    var excel = Excel.createExcel();
    Sheet sheet = excel['Top_Vendedores'];
    excel.setDefaultSheet('Top_Vendedores');

    sheet.appendRow([
      TextCellValue('POSICIÓN'),
      TextCellValue('VENDEDOR'),
      TextCellValue('CÓDIGO'),
      TextCellValue('TOTAL FACTURADO (\$)'),
      TextCellValue('N° PEDIDOS'),
      TextCellValue('TOTAL CAJAS'),
      TextCellValue('TOTAL BARRAS'),
    ]);

    int pos = 1;
    for (var item in ranking) {
      final v = item.value;
      sheet.appendRow([
        TextCellValue('#$pos'),
        TextCellValue(v['nombre'].toString()),
        TextCellValue(item.key),
        TextCellValue((v['total_dinero'] as double).toStringAsFixed(2)),
        TextCellValue(v['total_pedidos'].toString()),
        TextCellValue(v['total_cajas'].toString()),
        TextCellValue(v['total_barras'].toString()),
      ]);
      pos++;
    }

    var fileBytes = excel.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Top_Vendedores_SOE.xlsx');
    await file.writeAsBytes(fileBytes!);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Top de Vendedores - SOE Cosméticos',
      subject: 'Top de Vendedores - SOE Cosméticos',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar Top: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class SoeApp extends StatelessWidget {
  const SoeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOE Cosméticos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// PANTALLA 0: LOGIN CON CONTROL DE ACTUALIZACIÓN OTA
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  bool _ocultarClave = true;
  bool _recordarSesion = true;
  bool _cargando = false;
  bool _iniciando = true;
  bool _bloqueadoRemoto = false;
  String _mensajeBloqueo = "";
  String _urlDescarga = "";
  bool _descargandoActualizacion = false;
  String _progresoDescarga = "0";

  @override
  void initState() {
    super.initState();
    _verificarControlRemotoYCredenciales();
  }

  Future<void> _verificarControlRemotoYCredenciales() async {
    try {
      final configDoc = await FirebaseFirestore.instance.collection('configuracion').doc('app').get();
      if (configDoc.exists && configDoc.data() != null) {
        final data = configDoc.data()!;
        String versionMinima = (data['version_minima'] ?? data['version minima'] ?? '1.5.3').toString();
        dynamic bloqueoVal = data['bloqueo_general'] ?? data['bloqueo general'];
        bool bloqueoGeneral = bloqueoVal == true;
        String urlDescarga = (data['url_descarga'] ?? data['url descarga'] ?? '').toString();

        String mensaje = (data['mensaje_bloqueo'] ?? data['mensaje bloqueo'] ?? (bloqueoVal is String ? bloqueoVal : null) ??
            'Actualización obligatoria disponible. Por favor instala la nueva versión para continuar.').toString();

        if (bloqueoGeneral || esVersionMenor(kAppVersion, versionMinima)) {
          if (mounted) {
            setState(() {
              _bloqueadoRemoto = true;
              _mensajeBloqueo = mensaje;
              _urlDescarga = urlDescarga;
              _iniciando = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Verificación remota omitida (modo offline): $e");
    }

    try {
      final credenciales = await leerCredencialesSeguras();
      if (mounted) {
        setState(() {
          if (credenciales['recordar'] == 'true') {
            _usuarioCtrl.text = credenciales['usuario'] ?? '';
            _claveCtrl.text = credenciales['clave'] ?? '';
            _recordarSesion = true;
          }
          _iniciando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _iniciando = false);
    }
  }

  Future<void> _iniciarActualizacionOta() async {
    if (_urlDescarga.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay enlace de descarga configurado en el servidor.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _descargandoActualizacion = true;
      _progresoDescarga = "0";
    });

    try {
      OtaUpdate()
          .execute(_urlDescarga, destinationFilename: 'soe_app_update.apk')
          .listen(
        (OtaEvent event) {
          if (!mounted) return;
          setState(() {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                _progresoDescarga = event.value ?? "0";
                break;
              case OtaStatus.INSTALLING:
                _descargandoActualizacion = false;
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
                _descargandoActualizacion = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Descarga ya en progreso')),
                );
                break;
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                _descargandoActualizacion = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Permiso denegado para instalar aplicaciones')),
                );
                break;
              case OtaStatus.INTERNAL_ERROR:
              case OtaStatus.DOWNLOAD_ERROR:
              default:
                _descargandoActualizacion = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al descargar actualización (${event.status})')),
                );
                break;
            }
          });
        },
        onError: (error) {
          if (mounted) {
            setState(() => _descargandoActualizacion = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error en la descarga: $error')),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _descargandoActualizacion = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fallo al iniciar descarga: $e')),
        );
      }
    }
  }

  Future<void> _iniciarSesion() async {
    String usuarioInput = _usuarioCtrl.text.trim();
    String claveInput = _claveCtrl.text.trim();

    if (usuarioInput.isEmpty || claveInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa usuario y contraseña')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('usuario', isEqualTo: usuarioInput)
          .where('clave', isEqualTo: claveInput)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        String nombreVendedor = userData['nombre']?.toString() ?? usuarioInput;
        String codigoVendedor = userData['usuario']?.toString() ?? usuarioInput;
        String rol = userData['rol']?.toString().toLowerCase() ?? 'vendedor';

        await guardarCredencialesSeguras(
          usuario: codigoVendedor,
          clave: claveInput,
          nombre: nombreVendedor,
          rol: rol,
          recordar: _recordarSesion,
        );

        if (!mounted) return;

        bool terminosAceptados = userData['terminos_aceptados'] == true;

        if (!terminosAceptados) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TerminosCondicionesScreen(
                docIdUsuario: snapshot.docs.first.id,
                nombreUsuario: nombreVendedor,
                codigoUsuario: codigoVendedor,
                rolUsuario: rol,
              ),
            ),
          );
          return;
        }

        if (rol == 'desarrollador' || rol == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboardScreen(
                nombreUsuario: nombreVendedor,
                codigoUsuario: codigoVendedor,
                rolUsuario: rol,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FormularioScreen(
                nombreUsuario: nombreVendedor,
                codigoUsuario: codigoVendedor,
                rolUsuario: rol,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario o contraseña incorrectos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_iniciando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    if (_bloqueadoRemoto) {
      double progresoNum = (double.tryParse(_progresoDescarga) ?? 0) / 100.0;

      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_security_update_rounded, size: 85, color: Colors.pink),
                const SizedBox(height: 20),
                const Text(
                  'ACTUALIZACIÓN DISPONIBLE',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.pink.shade200),
                  ),
                  child: Text(
                    _mensajeBloqueo,
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  'Versión instalada: v$kAppVersion',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                if (_descargandoActualizacion) ...[
                  LinearProgressIndicator(
                    value: progresoNum > 0 ? progresoNum : null,
                    color: Colors.pink,
                    backgroundColor: Colors.pink.shade100,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Descargando: $_progresoDescarga%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                  ),
                ] else if (_urlDescarga.isNotEmpty) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text(
                      'ACTUALIZAR AHORA',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: _iniciarActualizacionOta,
                  ),
                ],

                const SizedBox(height: 15),
                OutlinedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.power_settings_new, color: Colors.grey),
                  label: const Text('SALIR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  onPressed: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Salir de la app',
            icon: const Icon(Icons.power_settings_new, color: Colors.pink),
            onPressed: () => confirmarSalidaApp(context),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 10.0),
                    child: Column(
                      children: [
                        const Spacer(),
                        Image.asset(
                          'assets/images/logo_completo.jpg',
                          height: 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.spa,
                            size: 80,
                            color: Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 30),

                        TextField(
                          controller: _usuarioCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Código / Usuario',
                            prefixIcon: Icon(Icons.person_outline, color: Colors.pink),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _claveCtrl,
                          obscureText: _ocultarClave,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.pink),
                            suffixIcon: IconButton(
                              icon: Icon(_ocultarClave ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _ocultarClave = !_ocultarClave),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Checkbox(
                              value: _recordarSesion,
                              activeColor: Colors.pink,
                              onChanged: (val) {
                                setState(() => _recordarSesion = val ?? true);
                              },
                            ),
                            const Text(
                              'Recordar en este teléfono',
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _cargando ? null : _iniciarSesion,
                          child: _cargando
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'INGRESAR',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),

                        const Spacer(),
                        const Text(
                          'Desarrollado por Guillefox',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v$kAppVersion',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA: TÉRMINOS LEGALES Y CONFIDENCIALIDAD
// ==========================================
class TerminosCondicionesScreen extends StatefulWidget {
  final String docIdUsuario;
  final String nombreUsuario;
  final String codigoUsuario;
  final String rolUsuario;

  const TerminosCondicionesScreen({
    super.key,
    required this.docIdUsuario,
    required this.nombreUsuario,
    required this.codigoUsuario,
    required this.rolUsuario,
  });

  @override
  State<TerminosCondicionesScreen> createState() => _TerminosCondicionesScreenState();
}

class _TerminosCondicionesScreenState extends State<TerminosCondicionesScreen> {
  bool _aceptoTerminos = false;
  bool _procesando = false;

  Future<void> _confirmarAceptacion() async {
    if (!_aceptoTerminos) return;

    setState(() => _procesando = true);

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(widget.docIdUsuario).update({
        'terminos_aceptados': true,
        'version_terminos': 'v1.0',
        'fecha_aceptacion_terminos': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('auditoria_legal').add({
        'evento': 'ACEPTACION_CONTRATO_CONFIDENCIALIDAD',
        'usuario_codigo': widget.codigoUsuario,
        'usuario_nombre': widget.nombreUsuario,
        'rol': widget.rolUsuario,
        'version_contrato': 'v1.0',
        'fecha': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      if (widget.rolUsuario == 'desarrollador' || widget.rolUsuario == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboardScreen(
              nombreUsuario: widget.nombreUsuario,
              codigoUsuario: widget.codigoUsuario,
              rolUsuario: widget.rolUsuario,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FormularioScreen(
              nombreUsuario: widget.nombreUsuario,
              codigoUsuario: widget.codigoUsuario,
              rolUsuario: widget.rolUsuario,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registrando aceptación: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Acuerdo Legal y Confidencialidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.pink.shade100,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Salir',
            icon: const Icon(Icons.power_settings_new, color: Colors.pink),
            onPressed: () => confirmarSalidaApp(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.gavel, color: Colors.amber.shade900),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Lectura y aceptación obligatoria para el uso de las herramientas comerciales de SOE Cosméticos.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const SingleChildScrollView(
                    child: Text(
                      'TÉRMINOS DE USO, POLÍTICA DE PRIVACIDAD Y ACUERDO DE CONFIDENCIALIDAD COMERCIAL\n'
                      'SOE COSMÉTICOS — VERSIÓN 1.0\n\n'
                      '1. PROPIEDAD Y OBJETO DEL SISTEMA\n'
                      'Esta aplicación móvil y sus bases de datos son propiedad exclusiva de SOE Cosméticos. Su uso está estrictamente reservado para fines de gestión comercial autorizada. Queda terminantemente prohibido su uso personal, derivado o ajeno a las actividades comerciales encomendadas.\n\n'
                      '2. SECRETO COMERCIAL Y PROTECCIÓN DE DATOS\n'
                      'El usuario reconoce expresamente que toda la información accesible a través de esta aplicación —incluyendo sin limitación: nombres de clientes, registros de RIF, direcciones, números de contacto, historiales de compra, volúmenes de venta, condiciones crediticias, catálogo y políticas de precios— constituye Secreto Comercial e Información Confidencial de SOE Cosméticos.\n\n'
                      'Queda expresamente prohibida la copia, reproducción, captura sistemática, extracción masiva, transferencia a terceros, comercialización o utilización de dicha información en beneficio propio o de terceros ajenos a la empresa. Dicha conducta acarreará responsabilidades civiles y penales con base en la Ley Especial Contra los Delitos Informáticos y normativas vigentes sobre competencia desleal.\n\n'
                      '3. CUSTODIA Y RESPONSABILIDAD DE CREDENCIALES\n'
                      'El código de usuario y la contraseña asignados son de uso personal e intransferible. El usuario asume plena responsabilidad por todas las transacciones, modificaciones de datos y pedidos cargados bajo sus credenciales. En caso de extravío, sustracción del dispositivo móvil o sospecha de acceso no autorizado, el usuario debe notificar inmediatamente a Administración.\n\n'
                      '4. NATURALEZA PROVISIONAL DE LOS PEDIDOS\n'
                      'Los pedidos generados mediante la aplicación corresponden exclusivamente a órdenes de preventa y notas de entrega provisionales. La formalización definitiva, asignación de inventario y despacho están sujetas a la validación de crédito y conciliación de cobranza por parte del departamento administrativo de SOE Cosméticos.\n\n'
                      '5. REGISTRO Y AUDITORÍA DE ACTIVIDADES\n'
                      'El usuario consiente de forma expresa que sus accesos, pedidos emitidos, modificaciones de estatus y hora exacta de operaciones quedan almacenados en registros de auditoría inmutables para fines de seguridad operativa y control contable.',
                      style: TextStyle(fontSize: 12.5, height: 1.45, color: Colors.black87),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _aceptoTerminos,
                    activeColor: Colors.pink,
                    onChanged: (val) {
                      setState(() => _aceptoTerminos = val ?? false);
                    },
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'He leído íntegramente, comprendo y acepto sin reservas los Términos de Uso y el Acuerdo de Confidencialidad de SOE Cosméticos.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _aceptoTerminos ? Colors.pink : Colors.grey.shade400,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: (_aceptoTerminos && !_procesando) ? _confirmarAceptacion : null,
                child: _procesando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'CONFIRMAR Y CONTINUAR',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA: PANEL ADMINISTRATIVO / DESARROLLADOR
// ==========================================
class AdminDashboardScreen extends StatelessWidget {
  final String nombreUsuario;
  final String codigoUsuario;
  final String rolUsuario;

  const AdminDashboardScreen({
    super.key,
    required this.nombreUsuario,
    required this.codigoUsuario,
    required this.rolUsuario,
  });

  void _cerrarSesion(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _mostrarFiltroVendedor(BuildContext context) async {
    final snapshot = await FirebaseFirestore.instance.collection('usuarios').get();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Vendedor'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: snapshot.docs.map((doc) {
              final data = doc.data();
              return ListTile(
                title: Text(data['nombre'] ?? 'Sin nombre'),
                subtitle: Text("Código: ${data['usuario']}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  exportarReporteExcel(
                    context: context,
                    filtroVendedorCodigo: data['usuario'],
                    tituloReporte: "Vendedor_${data['usuario']}",
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _mostrarFiltroCliente(BuildContext context) {
    final rifFiltroCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reporte por Cliente'),
        content: TextField(
          controller: rifFiltroCtrl,
          decoration: const InputDecoration(
            labelText: 'RIF / Cédula del Cliente',
            hintText: 'Ej: J-12345678',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () {
              String rif = rifFiltroCtrl.text.trim().toUpperCase();
              if (rif.isNotEmpty) {
                Navigator.pop(ctx);
                exportarReporteExcel(
                  context: context,
                  filtroClienteRif: rif,
                  tituloReporte: "Cliente_$rif",
                );
              }
            },
            child: const Text('Descargar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool esDev = rolUsuario == 'desarrollador';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(esDev ? 'Panel Desarrollador' : 'Panel de Administración', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink.shade100,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout, color: Colors.pink),
            onPressed: () => _cerrarSesion(context),
          ),
          IconButton(
            tooltip: 'Salir de la app',
            icon: const Icon(Icons.power_settings_new, color: Colors.pink),
            onPressed: () => confirmarSalidaApp(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.pink.shade100,
                      child: Icon(esDev ? Icons.terminal : Icons.admin_panel_settings, size: 32, color: Colors.pink),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombreUsuario, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Código: $codigoUsuario', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              esDev ? 'DESARROLLADOR' : 'ADMINISTRADOR',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.pink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('CONTROL Y DESPACHO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
              label: const Text('PEDIDOS Y PAGOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GestionPedidosScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.manage_accounts, color: Colors.white),
              label: const Text('GESTIÓN DE USUARIOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GestionUsuariosScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.groups_outlined, color: Colors.white),
              label: const Text('GESTIÓN DE CLIENTES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GestionClientesScreen()),
                );
              },
            ),
            const SizedBox(height: 25),

            const Text('REPORTES Y RANKINGS EXCEL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade600,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.leaderboard, color: Colors.white),
              label: const Text('TOP DE PRODUCTOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => exportarRankingProductos(context),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.emoji_events, color: Colors.white),
              label: const Text('TOP DE VENDEDORES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => exportarRankingVendedores(context),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.table_chart, color: Colors.white),
              label: const Text('REPORTE DE VENTAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => exportarReporteExcel(context: context, tituloReporte: "Global"),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.teal)),
                    icon: const Icon(Icons.badge, color: Colors.teal),
                    label: const Text('POR VENDEDOR', style: TextStyle(color: Colors.teal, fontSize: 12)),
                    onPressed: () => _mostrarFiltroVendedor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.indigo)),
                    icon: const Icon(Icons.person, color: Colors.indigo),
                    label: const Text('POR CLIENTE', style: TextStyle(color: Colors.indigo, fontSize: 12)),
                    onPressed: () => _mostrarFiltroCliente(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Divider(),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                side: const BorderSide(color: Colors.pink, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_shopping_cart, color: Colors.pink),
              label: const Text('CREAR NUEVO PEDIDO', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FormularioScreen(
                      nombreUsuario: nombreUsuario,
                      codigoUsuario: codigoUsuario,
                      rolUsuario: rolUsuario,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA: CONTROL DE PEDIDOS Y PAGOS (CON FILTRO DE VISIBILIDAD)
// ==========================================
class GestionPedidosScreen extends StatefulWidget {
  const GestionPedidosScreen({super.key});

  @override
  State<GestionPedidosScreen> createState() => _GestionPedidosScreenState();
}

class _GestionPedidosScreenState extends State<GestionPedidosScreen> {
  String _filtroEstatus = 'pendientes';

  Color _colorEstatus(String estatus) {
    switch (estatus) {
      case 'Despachado':
        return Colors.blue.shade700;
      case 'Pagado':
        return Colors.green.shade700;
      default:
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos y Pagos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink.shade100,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'pendientes',
                        label: Text('Pendientes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        icon: Icon(Icons.pending_actions, size: 16),
                      ),
                      ButtonSegment(
                        value: 'todos',
                        label: Text('Todos', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.list_alt, size: 16),
                      ),
                      ButtonSegment(
                        value: 'pagados',
                        label: Text('Pagados', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.check_circle_outline, size: 16),
                      ),
                    ],
                    selected: {_filtroEstatus},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _filtroEstatus = newSelection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: Colors.pink.shade100,
                      selectedForegroundColor: Colors.pink.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pedidos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay pedidos registrados'));
                }

                List<QueryDocumentSnapshot> docs = snapshot.data!.docs.toList();

                if (_filtroEstatus == 'pendientes') {
                  docs = docs.where((d) {
                    final st = (d.data() as Map<String, dynamic>)['estatus']?.toString() ?? 'Procesado';
                    return st != 'Pagado';
                  }).toList();
                } else if (_filtroEstatus == 'pagados') {
                  docs = docs.where((d) {
                    final st = (d.data() as Map<String, dynamic>)['estatus']?.toString() ?? 'Procesado';
                    return st == 'Pagado';
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _filtroEstatus == 'pendientes'
                            ? '🎉 ¡No hay pedidos pendientes por cobrar!'
                            : 'No hay pedidos en esta categoría',
                        style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  Timestamp? tA = dataA['fecha'] as Timestamp?;
                  Timestamp? tB = dataB['fecha'] as Timestamp?;
                  if (tA == null && tB == null) return 0;
                  if (tA == null) return 1;
                  if (tB == null) return -1;
                  return tB.compareTo(tA);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    String estatusActual = data['estatus']?.toString() ?? 'Procesado';
                    String cliente = data['cliente']?.toString() ?? 'N/A';
                    String rif = data['cliente_rif']?.toString() ?? 'N/A';
                    String codCliente = data['codigo_cliente']?.toString() ?? 'S/C';
                    String vendedor = data['vendedor']?.toString() ?? 'N/A';
                    String numPedido = data['numero_pedido']?.toString() ?? '#${(index + 1).toString().padLeft(4, '0')}';
                    double total = (data['total_pagar'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.pink.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(numPedido, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          cliente,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('RIF: $rif | Cód: $codCliente | Vendedor: $vendedor', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Estatus:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: _colorEstatus(estatusActual).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _colorEstatus(estatusActual)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: ['Procesado', 'Despachado', 'Pagado'].contains(estatusActual) ? estatusActual : 'Procesado',
                                      icon: Icon(Icons.arrow_drop_down, color: _colorEstatus(estatusActual)),
                                      style: TextStyle(color: _colorEstatus(estatusActual), fontWeight: FontWeight.bold),
                                      items: const [
                                        DropdownMenuItem(value: 'Procesado', child: Text('🟡 Procesado')),
                                        DropdownMenuItem(value: 'Despachado', child: Text('🔵 Despachado')),
                                        DropdownMenuItem(value: 'Pagado', child: Text('🟢 Pagado')),
                                      ],
                                      onChanged: (nuevo) async {
                                        if (nuevo != null && nuevo != estatusActual) {
                                          await FirebaseFirestore.instance.collection('pedidos').doc(doc.id).update({
                                            'estatus': nuevo,
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PANTALLA: GESTIÓN DE CLIENTES
// ==========================================
class GestionClientesScreen extends StatelessWidget {
  const GestionClientesScreen({super.key});

  void _mostrarEditarCliente(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final codigoCtrl = TextEditingController(text: data['codigo_cliente'] ?? '');
    final nombreCtrl = TextEditingController(text: data['nombre'] ?? '');
    final direccionCtrl = TextEditingController(text: data['direccion'] ?? '');
    final vendedorCodCtrl = TextEditingController(text: data['vendedor_codigo'] ?? '');
    final vendedorNomCtrl = TextEditingController(text: data['vendedor_nombre'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Cliente (${data['rif']})'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codigoCtrl,
                decoration: const InputDecoration(labelText: 'Código Único Cliente (Ej: CLSOE-001)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre / Razón Social', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: direccionCtrl,
                decoration: const InputDecoration(labelText: 'Dirección de Despacho', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: vendedorCodCtrl,
                decoration: const InputDecoration(labelText: 'Código Vendedor Asignado', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: vendedorNomCtrl,
                decoration: const InputDecoration(labelText: 'Nombre Vendedor Asignado', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('clientes').doc(doc.id).update({
                'codigo_cliente': codigoCtrl.text.trim(),
                'nombre': nombreCtrl.text.trim(),
                'direccion': direccionCtrl.text.trim(),
                'vendedor_codigo': vendedorCodCtrl.text.trim(),
                'vendedor_nombre': vendedorNomCtrl.text.trim(),
              });
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cliente actualizado exitosamente')),
                );
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink.shade100,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay clientes registrados'));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.store, color: Colors.blue),
                ),
                title: Text(data['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Cód: ${data['codigo_cliente'] ?? 'S/C'} | RIF: ${data['rif']}\nVendedor: ${data['vendedor_nombre'] ?? 'N/A'}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Modificar Cliente',
                  onPressed: () => _mostrarEditarCliente(context, doc),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// PANTALLA: GESTIÓN DE USUARIOS
// ==========================================
class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  void _mostrarEdicionUsuario(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nombreCtrl = TextEditingController(text: data['nombre'] ?? '');
    final usuarioCtrl = TextEditingController(text: data['usuario'] ?? '');
    final claveCtrl = TextEditingController(text: data['clave'] ?? '');
    String rolSeleccionado = data['rol'] ?? 'vendedor';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Editar: ${data['nombre']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre y Apellido', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usuarioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Usuario / Código',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: claveCtrl,
                    decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ['vendedor', 'admin', 'desarrollador'].contains(rolSeleccionado) ? rolSeleccionado : 'vendedor',
                    decoration: const InputDecoration(labelText: 'Rol del Usuario', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                      DropdownMenuItem(value: 'desarrollador', child: Text('Desarrollador')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => rolSeleccionado = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance.collection('usuarios').doc(doc.id).delete();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
                  }
                },
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('usuarios').doc(doc.id).update({
                    'nombre': nombreCtrl.text.trim(),
                    'usuario': usuarioCtrl.text.trim().toLowerCase(),
                    'clave': claveCtrl.text.trim(),
                    'rol': rolSeleccionado,
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario actualizado')));
                  }
                },
                child: const Text('Guardar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarCrearUsuario() {
    final nombreCtrl = TextEditingController();
    final usuarioCtrl = TextEditingController();
    final claveCtrl = TextEditingController();
    String rolSeleccionado = 'vendedor';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nuevo Usuario'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre y Apellido', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usuarioCtrl,
                    decoration: const InputDecoration(labelText: 'Código / Usuario (Único)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: claveCtrl,
                    decoration: const InputDecoration(labelText: 'Contraseña Inicial', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: rolSeleccionado,
                    decoration: const InputDecoration(labelText: 'Rol Asignado', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                      DropdownMenuItem(value: 'desarrollador', child: Text('Desarrollador')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => rolSeleccionado = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                onPressed: () async {
                  String nombre = nombreCtrl.text.trim();
                  String usuario = usuarioCtrl.text.trim().toLowerCase();
                  String clave = claveCtrl.text.trim();

                  if (nombre.isEmpty || usuario.isEmpty || clave.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todos los campos son requeridos')));
                    return;
                  }

                  final existe = await FirebaseFirestore.instance.collection('usuarios').where('usuario', isEqualTo: usuario).get();
                  if (existe.docs.isNotEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El usuario/código ya existe')));
                    }
                    return;
                  }

                  await FirebaseFirestore.instance.collection('usuarios').add({
                    'nombre': nombre,
                    'usuario': usuario,
                    'clave': clave,
                    'rol': rolSeleccionado,
                  });

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Usuario $nombre creado')));
                  }
                },
                child: const Text('Crear', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink.shade100,
        actions: [
          IconButton(
            tooltip: 'Crear Usuario',
            icon: const Icon(Icons.person_add, color: Colors.pink),
            onPressed: _mostrarCrearUsuario,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados'));
          }

          var docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              String rol = data['rol'] ?? 'vendedor';

              IconData iconRol = Icons.person;
              Color colorRol = Colors.grey.shade700;
              if (rol == 'desarrollador') {
                iconRol = Icons.terminal;
                colorRol = Colors.purple;
              } else if (rol == 'admin') {
                iconRol = Icons.admin_panel_settings;
                colorRol = Colors.pink;
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorRol.withOpacity(0.15),
                  child: Icon(iconRol, color: colorRol),
                ),
                title: Text(data['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Código: ${data['usuario']} | Rol: $rol'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.pink),
                  tooltip: 'Editar Datos',
                  onPressed: () => _mostrarEdicionUsuario(doc),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.pink,
        onPressed: _mostrarCrearUsuario,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Nuevo Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ==========================================
// PANTALLA 1: FORMULARIO DEL CLIENTE
// ==========================================
class FormularioScreen extends StatefulWidget {
  final String nombreUsuario;
  final String codigoUsuario;
  final String rolUsuario;

  const FormularioScreen({
    super.key,
    required this.nombreUsuario,
    required this.codigoUsuario,
    required this.rolUsuario,
  });

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final _formKey = GlobalKey<FormState>();

  final nombreCtrl = TextEditingController();
  final rifCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final observacionesCtrl = TextEditingController();

  List<Map<String, dynamic>> _clientesExistentes = [];
  bool _validandoCliente = false;

  @override
  void initState() {
    super.initState();
    _cargarClientesParaAutocompletado();
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    rifCtrl.dispose();
    direccionCtrl.dispose();
    observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarClientesParaAutocompletado() async {
    try {
      Query query = FirebaseFirestore.instance.collection('clientes');
      if (widget.rolUsuario == 'vendedor') {
        query = query.where('vendedor_codigo', isEqualTo: widget.codigoUsuario);
      }
      final snap = await query.get();
      if (mounted) {
        setState(() {
          _clientesExistentes = snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      debugPrint("Error cargando clientes: $e");
    }
  }

  void _mostrarSelectorClientesModal() {
    final searchFilterCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchFilterCtrl.text.trim().toLowerCase();
            final filtrados = _clientesExistentes.where((cli) {
              final nom = (cli['nombre'] ?? '').toString().toLowerCase();
              final r = (cli['rif'] ?? '').toString().toLowerCase();
              return nom.contains(query) || r.contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Seleccionar Cliente',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Card(
                      color: Colors.pink.shade50,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.pink, width: 1.5),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.pink,
                          child: Icon(Icons.person_add, color: Colors.white),
                        ),
                        title: const Text(
                          '➕ REGISTRAR CLIENTE NUEVO',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                        ),
                        subtitle: const Text('Limpiar campos para escribir un cliente nuevo desde cero'),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            nombreCtrl.clear();
                            rifCtrl.clear();
                            direccionCtrl.clear();
                            observacionesCtrl.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: searchFilterCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Buscar en mis clientes...',
                        prefixIcon: Icon(Icons.search, color: Colors.pink),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) => setModalState(() {}),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: filtrados.isEmpty
                          ? const Center(
                              child: Text('No hay clientes registrados con este nombre', style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtrados.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final cli = filtrados[index];
                                final nom = cli['nombre']?.toString() ?? 'Sin nombre';
                                final r = cli['rif']?.toString() ?? 'N/A';
                                final cod = cli['codigo_cliente']?.toString() ?? 'S/C';

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade50,
                                    child: const Icon(Icons.store, color: Colors.blue),
                                  ),
                                  title: Text(nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('RIF: $r | Cód: $cod'),
                                  trailing: const Icon(Icons.check_circle_outline, color: Colors.pink),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      nombreCtrl.text = nom;
                                      rifCtrl.text = r;
                                      direccionCtrl.text = cli['direccion']?.toString() ?? '';
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _cerrarSesionVendedor() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _limpiarFormulario() {
    nombreCtrl.clear();
    rifCtrl.clear();
    direccionCtrl.clear();
    observacionesCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario reiniciado')),
    );
  }

  Future<void> _procesarYContinuar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _validandoCliente = true);
    String nombreCliente = nombreCtrl.text.trim();
    String rifNormalizado = rifCtrl.text.trim().toUpperCase().replaceAll(' ', '');
    String codigoClienteAsignado = '';

    try {
      final docCliente = await FirebaseFirestore.instance.collection('clientes').doc(rifNormalizado).get();

      if (!mounted) return;

      if (docCliente.exists) {
        final data = docCliente.data()!;
        String vendedorOriginal = data['vendedor_codigo'] ?? '';
        String nombreVendedorOriginal = data['vendedor_nombre'] ?? 'Otro vendedor';
        codigoClienteAsignado = data['codigo_cliente'] ?? 'S/C';

        if (vendedorOriginal != widget.codigoUsuario && widget.rolUsuario == 'vendedor') {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cliente Asignado', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              content: Text(
                'Este cliente ya pertenece a la cartera de:\n\n'
                '• Vendedor: $nombreVendedorOriginal\n'
                '• Código: $vendedorOriginal\n\n'
                'No puedes registrar pedidos a clientes asignados a otro vendedor.',
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          return;
        }
      } else {
        codigoClienteAsignado = await _generarCodigoCliente();
        await FirebaseFirestore.instance.collection('clientes').doc(rifNormalizado).set({
          'codigo_cliente': codigoClienteAsignado,
          'rif': rifNormalizado,
          'nombre': nombreCliente,
          'direccion': direccionCtrl.text.trim(),
          'vendedor_codigo': widget.codigoUsuario,
          'vendedor_nombre': widget.nombreUsuario,
          'fecha_creacion': FieldValue.serverTimestamp(),
        });
      }

      final pedidosCliente = await FirebaseFirestore.instance
          .collection('pedidos')
          .where('cliente_rif', isEqualTo: rifNormalizado)
          .get();

      final pedidosSinPagar = pedidosCliente.docs.where((doc) {
        final estatus = doc.data()['estatus']?.toString() ?? 'Procesado';
        return estatus != 'Pagado';
      }).toList();

      if (pedidosSinPagar.isNotEmpty && widget.rolUsuario == 'vendedor') {
        double montoPendiente = 0;
        for (var p in pedidosSinPagar) {
          montoPendiente += (p.data()['total_pagar'] as num?)?.toDouble() ?? 0.0;
        }

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('Cliente con Deuda', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'El cliente $nombreCliente tiene ${pedidosSinPagar.length} pedido(s) pendiente(s) por pagar.\n\n'
              '• Deuda acumulada: \$${montoPendiente.toStringAsFixed(2)}\n\n'
              'No es posible generar nuevos pedidos hasta que Administración registre el pago correspondiente.',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CatalogoScreen(
            codigoCliente: codigoClienteAsignado,
            cliente: nombreCliente,
            rif: rifNormalizado,
            direccion: direccionCtrl.text.trim(),
            observaciones: observacionesCtrl.text.trim(),
            vendedor: widget.nombreUsuario,
            vendedorCodigo: widget.codigoUsuario,
            rolUsuario: widget.rolUsuario,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al validar cliente: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _validandoCliente = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool esAdminODev = widget.rolUsuario != 'vendedor';

    return Scaffold(
      appBar: AppBar(
        title: Text(esAdminODev ? 'Pedido (${widget.rolUsuario})' : 'Datos del Pedido', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink.shade100,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Nuevo Pedido / Limpiar',
            icon: const Icon(Icons.cleaning_services_outlined, color: Colors.pink),
            onPressed: _limpiarFormulario,
          ),
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout, color: Colors.pink),
            onPressed: _cerrarSesionVendedor,
          ),
          IconButton(
            tooltip: 'Salir de la app',
            icon: const Icon(Icons.power_settings_new, color: Colors.pink),
            onPressed: () => confirmarSalidaApp(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                color: Colors.pink.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.badge, color: Colors.pink),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VENDEDOR: ${widget.nombreUsuario.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('CÓDIGO: ${widget.codigoUsuario}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              const Text('Información del Cliente', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.pink)),
              const SizedBox(height: 12),

              TextFormField(
                controller: nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre del Cliente / Empresa',
                  hintText: 'Toca el botón o escribe aquí...',
                  prefixIcon: const Icon(Icons.person_search, color: Colors.pink),
                  suffixIcon: IconButton(
                    tooltip: 'Desplegable de Clientes',
                    icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.pink, size: 28),
                    onPressed: _mostrarSelectorClientesModal,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onTap: () {
                  if (nombreCtrl.text.isEmpty) {
                    _mostrarSelectorClientesModal();
                  }
                },
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: rifCtrl,
                decoration: const InputDecoration(
                  labelText: 'RIF / Cédula del Cliente',
                  hintText: 'Ej: J-12345678 o V-12345678',
                  prefixIcon: Icon(Icons.credit_card, color: Colors.pink),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'El RIF o cédula es obligatorio' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: direccionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección de Despacho',
                  prefixIcon: Icon(Icons.location_on_outlined, color: Colors.pink),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: observacionesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones de Despacho',
                  prefixIcon: Icon(Icons.note_alt_outlined, color: Colors.pink),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, minimumSize: const Size(double.infinity, 50)),
                onPressed: _validandoCliente ? null : _procesarYContinuar,
                child: _validandoCliente
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('IR AL CATÁLOGO SOE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  side: const BorderSide(color: Colors.pink),
                ),
                icon: const Icon(Icons.refresh, color: Colors.pink),
                label: const Text('LIMPIAR FORMULARIO / NUEVO PEDIDO', style: TextStyle(color: Colors.pink)),
                onPressed: _limpiarFormulario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA 2: CATÁLOGO Y GUARDADO DE PEDIDOS
// ==========================================
class CatalogoScreen extends StatefulWidget {
  final String codigoCliente, cliente, rif, direccion, observaciones, vendedor, vendedorCodigo, rolUsuario;

  const CatalogoScreen({
    super.key,
    required this.codigoCliente,
    required this.cliente,
    required this.rif,
    required this.direccion,
    required this.observaciones,
    required this.vendedor,
    required this.vendedorCodigo,
    required this.rolUsuario,
  });

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  Map<Producto, int> carrito = {};
  bool generandoPDF = false;

  int get totalJabones {
    int total = 0;
    for (var cantidad in carrito.values) { total += cantidad; }
    return total;
  }

  double get totalPagar {
    double total = 0;
    carrito.forEach((producto, cantidad) { total += producto.precio * cantidad; });
    return total;
  }

  Future<void> _generarYCompartirPDF() async {
    // 1. Bloqueo inmediato para impedir doble toque
    if (generandoPDF) return;

    setState(() => generandoPDF = true);

    try {
      int numCorrelativo = await _obtenerSiguienteNumeroPedido();
      String numeroPedido = "#${numCorrelativo.toString().padLeft(4, '0')}";
      String fechaActual = formatearFechaHora(DateTime.now());

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PEDIDO SOE COSMÉTICOS', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.pink700)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(numeroPedido, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.SizedBox(height: 3),
                        pw.Text('Fecha: $fechaActual', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),

                pw.Text('CLIENTE: ${widget.cliente}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('CÓDIGO CLIENTE: ${widget.codigoCliente} | RIF: ${widget.rif}'),
                pw.Text('DIRECCIÓN: ${widget.direccion}'),
                if (widget.observaciones.isNotEmpty) pw.Text('OBSERVACIONES: ${widget.observaciones}'),
                pw.SizedBox(height: 10),
                pw.Text('VENDEDOR: ${widget.vendedor} (CÓD: ${widget.vendedorCodigo})'),
                pw.Divider(),
                pw.SizedBox(height: 10),

                pw.TableHelper.fromTextArray(
                  headers: ['Producto', 'Cant.', 'Precio U.', 'Subtotal'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.pink),
                  data: carrito.entries.map((e) => [
                    e.key.nombre,
                    e.value.toString(),
                    '\$${e.key.precio.toStringAsFixed(2)}',
                    '\$${(e.key.precio * e.value).toStringAsFixed(2)}'
                  ]).toList(),
                ),

                pw.SizedBox(height: 20),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('TOTAL A PAGAR: \$${totalPagar.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('TOTAL BARRAS: $totalJabones', style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 4),
                pw.Text('TOTAL CAJAS (36 und): ${(totalJabones / 36).ceil()}', style: pw.TextStyle(fontSize: 14)),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/Pedido_${numeroPedido.replaceAll('#', '')}_${widget.cliente.replaceAll(" ", "_")}.pdf');
      await file.writeAsBytes(await pdf.save());

      List<Map<String, dynamic>> listaProductos = [];
      carrito.forEach((producto, cantidad) {
        listaProductos.add({
          'nombre': producto.nombre,
          'cantidad': cantidad,
          'precio': producto.precio,
          'subtotal': cantidad * producto.precio,
        });
      });

      await FirebaseFirestore.instance.collection('pedidos').add({
        'numero_pedido': numeroPedido,
        'correlativo': numCorrelativo,
        'codigo_cliente': widget.codigoCliente,
        'cliente': widget.cliente,
        'cliente_rif': widget.rif,
        'direccion': widget.direccion,
        'observaciones': widget.observaciones,
        'vendedor': widget.vendedor,
        'vendedor_codigo': widget.vendedorCodigo,
        'total_pagar': totalPagar,
        'total_barras': totalJabones,
        'total_cajas': (totalJabones / 36).ceil(),
        'estatus': 'Procesado',
        'fecha': FieldValue.serverTimestamp(),
        'productos': listaProductos,
      });

      // 2. Compartir archivo en WhatsApp
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Adjunto pedido $numeroPedido de ${widget.cliente}',
      );

      // 3. Vaciar carrito, limpiar estado y regresar de la pantalla
      if (mounted) {
        setState(() {
          carrito.clear();
          generandoPDF = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Pedido $numeroPedido registrado con éxito!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => generandoPDF = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el pedido: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink.shade100,
        actions: [
          IconButton(
            tooltip: 'Mis Ventas (Excel)',
            icon: const Icon(Icons.download_for_offline, color: Colors.pink),
            onPressed: () => exportarReporteExcel(
              context: context,
              filtroVendedorCodigo: widget.rolUsuario == 'vendedor' ? widget.vendedorCodigo : null,
              tituloReporte: widget.vendedorCodigo,
            ),
          ),
          IconButton(
            tooltip: 'Salir de la app',
            icon: const Icon(Icons.power_settings_new, color: Colors.pink),
            onPressed: () => confirmarSalidaApp(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: catalogoSoe.length,
        itemBuilder: (context, index) {
          final producto = catalogoSoe[index];
          final cantidad = carrito[producto] ?? 0;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(producto.categoria, style: TextStyle(color: Colors.pink.shade700, fontSize: 11)),
                        Text('\$${producto.precio.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: cantidad > 0 ? () {
                          setState(() {
                            carrito[producto] = cantidad - 1;
                            if (carrito[producto] == 0) carrito.remove(producto);
                          });
                        } : null,
                      ),
                      GestureDetector(
                        onTap: () {
                          TextEditingController controller = TextEditingController(
                            text: cantidad > 0 ? cantidad.toString() : '',
                          );
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Ingresar cantidad'),
                                content: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    hintText: "Ej: 50",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      int nuevaCantidad = int.tryParse(controller.text) ?? 0;
                                      setState(() {
                                        if (nuevaCantidad > 0) {
                                          carrito[producto] = nuevaCantidad;
                                        } else {
                                          carrito.remove(producto);
                                        }
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Aceptar'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$cantidad',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () => setState(() => carrito[producto] = cantidad + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: totalJabones > 0 ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -3),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Barras: $totalJabones', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Total: \$${totalPagar.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: totalJabones >= 12 ? Colors.green : Colors.grey,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: totalJabones >= 12 && !generandoPDF ? _generarYCompartirPDF : null,
                  child: generandoPDF
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          totalJabones >= 12 ? 'GENERAR PDF Y ENVIAR' : 'Faltan ${12 - totalJabones} jabones (Min. 12)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ) : null,
    );
  }
}