class Producto {
  final String nombre;
  final String categoria;
  final double precio;
  final String descripcion;
  final String marca; // 'SOE', 'Kabellitos', 'Hotelería'
  final int unidadesPorBulto; // 36 para SOE, 12 para Kabellitos

  Producto({
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.descripcion,
    this.marca = 'SOE',
    this.unidadesPorBulto = 36,
  });
}

// Catálogo General Unificado
final List<Producto> catalogoSoe = [
  // ==========================================
  // LÍNEA SOE COSMÉTICOS (Cajas de 36 unidades)
  // ==========================================
  // 1. Cuidado Especial y Sensible ($1.50)
  Producto(
    nombre: 'Aurora (Onco Vita)',
    categoria: 'Cuidado Especial',
    precio: 1.50,
    descripcion: '90g. pH neutro, sin fragancia, con aceites esenciales.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'Sábila y Glicerina',
    categoria: 'Cuidado Especial',
    precio: 1.50,
    descripcion: '100g. Hidratación profunda, sin fragancia.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'Glicerina',
    categoria: 'Cuidado Especial',
    precio: 1.50,
    descripcion: '100g. pH neutro, ideal para piel seca y sensible.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),

  // 2. Uso Diario y Humectantes ($0.90)
  Producto(
    nombre: 'Floralis',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Aroma delicado floral, acción humectante.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'Almendras',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Aroma suave y natural, máxima humectación.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'Coco',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Aroma tropical, limpieza profunda y humectante.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'Avena Clásica',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Limpieza profunda con suave fragancia natural.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'Rosas',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Aroma floral y delicado, acción humectante.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'Blossom',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Máxima hidratación con fragancia floral.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'Bebé',
    categoria: 'Uso Diario',
    precio: 0.90,
    descripcion: '100g. Máxima hidratación con fragancia bebé.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),

  // 3. Tratamiento Facial ($1.50)
  Producto(
    nombre: 'Carbón Activo',
    categoria: 'Tratamiento Facial',
    precio: 1.50,
    descripcion: '100g. Detox, minimiza poros, seboregulador, sin fragancia.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'Concha de Nácar',
    categoria: 'Tratamiento Facial',
    precio: 1.50,
    descripcion: '100g. Aclarante, iluminador, exfoliante suave, sin fragancia.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),

  // 4. Línea Antibacterial ($1.10)
  Producto(
    nombre: 'Avena Antibacterial',
    categoria: 'Antibacterial',
    precio: 1.10,
    descripcion: '100g. Base vegetal, niacinamida, protección y regeneración.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'Natural Antibacterial',
    categoria: 'Antibacterial',
    precio: 1.10,
    descripcion: '100g. Base vegetal, niacinamida, sin fragancia.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'Fresh Antibacterial',
    categoria: 'Antibacterial',
    precio: 1.10,
    descripcion: '100g. Base vegetal, niacinamida, efecto ultra refrescante.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'The Boss Antibacterial',
    categoria: 'Antibacterial',
    precio: 1.10,
    descripcion: '100g. Base vegetal, niacinamida, cuidado masculino.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),

  // 5. Línea The Boss ($0.90)
  Producto(
    nombre: 'The Boss (Clásico)',
    categoria: 'The Boss',
    precio: 0.90,
    descripcion: '100g. Fragancia masculina, limpieza profunda y afeitado suave.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),
  Producto(
    nombre: 'The Boss 2 en 1 Energy',
    categoria: 'The Boss',
    precio: 0.90,
    descripcion: '100g. Ducha y afeitado, energía para el hombre.',
    marca: 'SOE',
    unidadesPorBulto: 36,
  ),

  // ==========================================
  // LÍNEA KABELLITOS (Bultos de 12 unidades / Docena)
  // ==========================================
  Producto(
    nombre: 'Kabellitos Colonia',
    categoria: 'Cuidado Infantil',
    precio: 3.44,
    descripcion: 'Fragancia infantil suave y fresca. Bulto de 12 unidades.',
    marca: 'Kabellitos',
    unidadesPorBulto: 12,
  ),
  Producto(
    nombre: 'Kabellitos Shampoo',
    categoria: 'Cuidado Infantil',
    precio: 2.20,
    descripcion: 'Fórmula suave para niños. Bulto de 12 unidades.',
    marca: 'Kabellitos',
    unidadesPorBulto: 12,
  ),
  Producto(
    nombre: 'Kabellitos Shampoo Antipiojos',
    categoria: 'Cuidado Infantil',
    precio: 2.36,
    descripcion: 'Tratamiento y prevención eficaz. Bulto de 12 unidades.',
    marca: 'Kabellitos',
    unidadesPorBulto: 12,
  ),
  Producto(
    nombre: 'Kabellitos Crema de Peinar',
    categoria: 'Cuidado Infantil',
    precio: 2.36,
    descripcion: 'Desenredo fácil y brillo natural. Bulto de 12 unidades.',
    marca: 'Kabellitos',
    unidadesPorBulto: 12,
  ),
  Producto(
    nombre: 'Kabellitos Crema Anti Pañalitis',
    categoria: 'Cuidado Infantil',
    precio: 2.34,
    descripcion: 'Protección y alivio dérmico para bebés. Bulto de 12 unidades.',
    marca: 'Kabellitos',
    unidadesPorBulto: 12,
  ),
  Producto(
    nombre: 'Kabellitos Jabón Hipoalergénico',
    categoria: 'Cuidado Infantil',
    precio: 0.90,
    descripcion: 'Limpieza suave para piel delicada. Bulto de 12 unidades.',
    marca: 'Kabellitos',
    unidadesPorBulto: 12,
  ),

  // ==========================================
  // LÍNEA HOTELERÍA (Línea Institucional)
  // ==========================================
  // Espacio reservado para los productos hoteleros
];