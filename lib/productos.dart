class Producto {
  final String nombre;
  final String categoria;
  final double precio;
  final String descripcion;
  final String marca; // 'SOE', 'Kabellitos', 'Hotelería'
  final int unidadesPorBulto; // 36 para SOE, 12 para Kabellitos, 1 para Hotelería
  final String nombreDespacho; // Nombre técnico detallado para Despacho y PDF

  Producto({
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.descripcion,
    this.marca = 'SOE',
    this.unidadesPorBulto = 36,
    required this.nombreDespacho,
  });
}

// Catálogo General Unificado
final List<Producto> catalogoSoe = [
  // ==========================================
  // 1. LÍNEA SOE COSMÉTICOS (Cajas de 36 unidades)
  // ==========================================
  // Cuidado Especial y Sensible ($1.50)
  Producto(
    nombre: 'Aurora (Onco Vita)',
    categoria: 'Cuidado Especial',
    precio: 1.50,
    descripcion: '90g. pH neutro, sin fragancia, con aceites esenciales.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Aurora (Onco Vita) 90g — Cuidado Especial',
  ),
  Producto(
    nombre: 'Sábila y Glicerina',
    categoria: 'Cuidado Especial',
    precio: 1.50,
    descripcion: '100g. Hidratación profunda, sin fragancia.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Sábila y Glicerina 100g — Cuidado Especial',
  ),
  Producto(
    nombre: 'Glicerina',
    categoria: 'Cuidado Especial',
    precio: 1.50,
    descripcion: '100g. pH neutro, ideal para piel seca y sensible.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Glicerina Pura 100g — Cuidado Especial',
  ),

  // Uso Diario y Humectantes ($0.90)
  Producto(
    nombre: 'Floralis',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Aroma delicado floral, acción humectante.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Floralis 100g — Uso Diario',
  ),
  Producto(
    nombre: 'Almendras',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Aroma suave y natural, máxima humectación.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Almendras 100g — Uso Diario',
  ),
  Producto(
    nombre: 'Coco',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Aroma tropical, limpieza profunda y humectante.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Coco 100g — Uso Diario',
  ),
  Producto(
    nombre: 'Avena Clásica',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Limpieza profunda con suave fragancia natural.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Avena Clásica 100g — Uso Diario',
  ),
  Producto(
    nombre: 'Rosas',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Aroma floral y delicado, acción humectante.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Rosas 100g — Uso Diario',
  ),
  Producto(
    nombre: 'Blossom',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Máxima hidratación con fragancia floral.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Blossom 100g — Uso Diario',
  ),
  Producto(
    nombre: 'Bebé',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Máxima hidratación con fragancia bebé.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Bebé 100g — Uso Diario',
  ),

  // Tratamiento Facial ($1.50)
  Producto(
    nombre: 'Carbón Activo',
    categoria: 'Tratamiento Facial',
    precio: 1.50,
    descripcion: '100g. Detox, minimiza poros, seboregulador, sin fragancia.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Carbón Activo 100g — Facial Detox',
  ),
  Producto(
    nombre: 'Concha de Nácar',
    categoria: 'Tratamiento Facial',
    precio: 1.50,
    descripcion: '100g. Aclarante, iluminador, exfoliante suave, sin fragancia.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Concha de Nácar 100g — Facial Aclarante',
  ),

  // Línea Antibacterial ($1.10)
  Producto(
    nombre: 'Avena Antibacterial',
    categoria: 'Antibacterial',
    precio: 1.10,
    descripcion: '100g. Base vegetal, niacinamida, protección y regeneración.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Avena Antibacterial 100g — Antibacterial',
  ),
  Producto(
    nombre: 'Natural Antibacterial',
    categoria: 'Antibacterial',
    precio: 1.10,
    descripcion: '100g. Base vegetal, niacinamida, sin fragancia.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Natural Antibacterial 100g — Antibacterial',
  ),
  Producto(
    nombre: 'Fresh Antibacterial',
    categoria: 'Antibacterial',
    precio: 1.10,
    descripcion: '100g. Base vegetal, niacinamida, efecto ultra refrescante.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'Fresh Antibacterial 100g — Antibacterial',
  ),
  Producto(
    nombre: 'The Boss Antibacterial',
    categoria: 'Antibacterial',
    precio: 1.10,
    descripcion: '100g. Base vegetal, niacinamida, cuidado masculino.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'The Boss Antibacterial 100g — Antibacterial',
  ),

  // Línea The Boss ($0.90)
  Producto(
    nombre: 'The Boss (Clásico)',
    categoria: 'The Boss',
    precio: 0.90,
    descripcion: '100g. Fragancia masculina, limpieza profunda y afeitado suave.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'The Boss Clásico 100g — Masculino',
  ),
  Producto(
    nombre: 'The Boss 2 en 1 Energy',
    categoria: 'The Boss',
    precio: 0.90,
    descripcion: '100g. Ducha y afeitado, energía para el hombre.',
    marca: 'SOE',
    unidadesPorBulto: 36,
    nombreDespacho: 'The Boss 2 en 1 Energy 100g — Masculino',
  ),

  // ==========================================
  // 2. LÍNEA KABELLITOS (Bultos de 12 unidades / Docena)
  // ==========================================
  Producto(
    nombre: 'Kabellitos Colonia',
    categoria: 'Cuidado Infantil',
    precio: 3.44,
    descripcion: 'Fragancia infantil suave y fresca. Bulto de 12 unidades.',
    marca: 'Kabellitos',
    unidadesPorBulto: 12,
    nombreDespacho: 'Kabellitos Colonia — Cuidado Infantil (Docena)',
  ),
  Producto(
    nombre: 'Kabellitos Shampoo',
    categoria: 'Cuidado Infantil',
    precio: 2.20,
    descripcion: 'Fórmula suave para niños. Bulto de 12 unidades.',
    marca: 'Kabellitos',
    unidadesPorBulto: 12,
    nombreDespacho: 'Kabellitos Shampoo — Cuidado Infantil (Docena)',
  ),
  Producto(
    nombre: 'Kabellitos Shampoo Antipiojos',
    categoria: 'Cuidado Infantil',
    precio: 2.36,
    descripcion: 'Tratamiento y prevención eficaz. Bulto de 12 unidades.',
    marca: 'Kabellitos',
    unidadesPorBulto: 12,
    nombreDespacho: 'Kabellitos Shampoo Antipiojos — Cuidado Infantil (Docena)',
  ),
  Producto(
    nombre: 'Kabellitos Crema de Peinar',
    categoria: 'Cuidado Infantil',
    precio: 2.36,
    descripcion: 'Desenredo fácil y brillo natural. Bulto de 12 unidades.',
    marca: 'Kabellitos',
    unidadesPorBulto: 12,
    nombreDespacho: 'Kabellitos Crema de Peinar — Cuidado Infantil (Docena)',
  ),
  Producto(
    nombre: 'Kabellitos Crema Anti Pañalitis',
    categoria: 'Cuidado Infantil',
    precio: 2.34,
    descripcion: 'Protección y alivio dérmico para bebés. Bulto de 12 unidades.',
    marca: 'Kabellitos',
    unidadesPorBulto: 12,
    nombreDespacho: 'Kabellitos Crema Anti Pañalitis — Cuidado Infantil (Docena)',
  ),
  Producto(
    nombre: 'Kabellitos Jabón Hipoalergénico',
    categoria: 'Cuidado Infantil',
    precio: 0.90,
    descripcion: 'Limpieza suave para piel delicada. Bulto de 12 unidades.',
    marca: 'Kabellitos',
    unidadesPorBulto: 12,
    nombreDespacho: 'Kabellitos Jabón Hipoalergénico — Cuidado Infantil (Docena)',
  ),

  // ==========================================
  // 3. LÍNEA HOTELERÍA (Institucional / Amenities)
  // ==========================================
  // Jabones Rectangulares
  Producto(
    nombre: 'Jabón SOE Hotel 10g',
    categoria: 'Jabones Rectangulares',
    precio: 0.18,
    descripcion: '10g rectangular. Empaque individual hotelero.',
    marca: 'Hotelería',
    unidadesPorBulto: 1,
    nombreDespacho: 'Jabón SOE Hotel 10g — Rectangular',
  ),
  Producto(
    nombre: 'Jabón SOE Hotel 15g',
    categoria: 'Jabones Rectangulares',
    precio: 0.25,
    descripcion: '15g rectangular. Empaque individual hotelero.',
    marca: 'Hotelería',
    unidadesPorBulto: 1,
    nombreDespacho: 'Jabón SOE Hotel 15g — Rectangular',
  ),
  Producto(
    nombre: 'Jabón SOE Hotel 20g',
    categoria: 'Jabones Rectangulares',
    precio: 0.34,
    descripcion: '20g rectangular. Empaque individual hotelero.',
    marca: 'Hotelería',
    unidadesPorBulto: 1,
    nombreDespacho: 'Jabón SOE Hotel 20g — Rectangular',
  ),
  Producto(
    nombre: 'Jabón SOE Hotel 30g',
    categoria: 'Jabones Rectangulares',
    precio: 0.45,
    descripcion: '30g rectangular. Empaque individual hotelero.',
    marca: 'Hotelería',
    unidadesPorBulto: 1,
    nombreDespacho: 'Jabón SOE Hotel 30g — Rectangular',
  ),
  Producto(
    nombre: 'Jabón SOE Hotel 50g',
    categoria: 'Jabones Rectangulares',
    precio: 0.57,
    descripcion: '50g rectangular. Empaque individual hotelero.',
    marca: 'Hotelería',
    unidadesPorBulto: 1,
    nombreDespacho: 'Jabón SOE Hotel 50g — Rectangular',
  ),

  // Jabones Redondos
  Producto(
    nombre: 'Jabón SOE Redondo Hotel 20g',
    categoria: 'Jabones Redondos',
    precio: 0.34,
    descripcion: '20g redondo. Presentación hotelera circular.',
    marca: 'Hotelería',
    unidadesPorBulto: 1,
    nombreDespacho: 'Jabón SOE Hotel 20g — Redondo',
  ),
  Producto(
    nombre: 'Jabón SOE Redondo Hotel 30g',
    categoria: 'Jabones Redondos',
    precio: 0.45,
    descripcion: '30g redondo. Presentación hotelera circular.',
    marca: 'Hotelería',
    unidadesPorBulto: 1,
    nombreDespacho: 'Jabón SOE Hotel 30g — Redondo',
  ),

  // Amenities (30ml)
  Producto(
    nombre: 'Shampoo 30ml',
    categoria: 'Amenities',
    precio: 0.50,
    descripcion: '30ml frasco hotelero.',
    marca: 'Hotelería',
    unidadesPorBulto: 1,
    nombreDespacho: 'Shampoo Hotelero 30ml — Amenities',
  ),
  Producto(
    nombre: 'Acondicionador 30ml',
    categoria: 'Amenities',
    precio: 0.50,
    descripcion: '30ml frasco hotelero.',
    marca: 'Hotelería',
    unidadesPorBulto: 1,
    nombreDespacho: 'Acondicionador Hotelero 30ml — Amenities',
  ),
  Producto(
    nombre: 'Gel de Baño 30ml',
    categoria: 'Amenities',
    precio: 0.50,
    descripcion: '30ml frasco hotelero.',
    marca: 'Hotelería',
    unidadesPorBulto: 1,
    nombreDespacho: 'Gel de Baño Hotelero 30ml — Amenities',
  ),
  Producto(
    nombre: 'Body Lotion 30ml',
    categoria: 'Amenities',
    precio: 0.50,
    descripcion: '30ml loción corporal hotelera.',
    marca: 'Hotelería',
    unidadesPorBulto: 1,
    nombreDespacho: 'Body Lotion Hotelera 30ml — Amenities',
  ),
  Producto(
    nombre: 'Espuma para Jacuzzi 30ml',
    categoria: 'Amenities',
    precio: 0.50,
    descripcion: '30ml concentrado para tina/jacuzzi.',
    marca: 'Hotelería',
    unidadesPorBulto: 1,
    nombreDespacho: 'Espuma para Jacuzzi 30ml — Amenities',
  ),
];