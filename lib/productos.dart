class Producto {
  final String nombre;
  final String categoria;
  final double precio;
  final String descripcion;

  Producto({
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.descripcion,
  });
}

// Lista de inventario SOE Cosméticos
final List<Producto> catalogoSoe = [
  // 1. Cuidado Especial y Sensible ($1.5)
  Producto(nombre: 'Aurora (Onco Vita)', categoria: 'Cuidado Especial', precio: 1.50, descripcion: '90g. pH neutro, sin fragancia, con aceites esenciales.'),
  Producto(nombre: 'Sábila y Glicerina', categoria: 'Cuidado Especial', precio: 1.50, descripcion: '100g. Hidratación profunda, sin fragancia.'),
  Producto(nombre: 'Glicerina', categoria: 'Cuidado Especial', precio: 1.50, descripcion: '100g. pH neutro, ideal para piel seca y sensible.'),

  // 2. Uso Diario y Humectantes ($0.9)
  Producto(nombre: 'Floralis', categoria: 'Uso Diario', precio: 0.90, descripcion: '100g. Aroma delicado floral, acción humectante.'),
  Producto(nombre: 'Almendras', categoria: 'Uso Diario', precio: 0.90, descripcion: '100g. Aroma suave y natural, máxima humectación.'),
  Producto(nombre: 'Coco', categoria: 'Uso Diario', precio: 0.90, descripcion: '100g. Aroma tropical, limpieza profunda y humectante.'),
  Producto(nombre: 'Avena Clásica', categoria: 'Uso Diario', precio: 0.90, descripcion: '100g. Limpieza profunda con suave fragancia natural.'),
  Producto(nombre: 'Rosas', categoria: 'Uso Diario', precio: 0.90, descripcion: '100g. Aroma floral y delicado, acción humectante.'),
  Producto(nombre: 'Blossom', categoria: 'Uso Diario', precio: 0.90, descripcion: '100g. Máxima hidratación con fragancia floral.'),
  Producto(nombre: 'Bebé', categoria: 'Uso Diario', precio: 0.90, descripcion: '100g. Máxima hidratación con fragancia bebe.'),


  // 3. Tratamiento Facial ($1.5)
  Producto(nombre: 'Carbón Activo', categoria: 'Tratamiento Facial', precio: 1.50, descripcion: '100g. Detox, minimiza poros, seboregulador, sin fragancia.'),
  Producto(nombre: 'Concha de Nácar', categoria: 'Tratamiento Facial', precio: 1.50, descripcion: '100g. Aclarante, iluminador, exfoliante suave, sin fragancia.'),

  // 4. Línea Antibacterial ($1.10)
  Producto(nombre: 'Avena Antibacterial', categoria: 'Antibacterial', precio: 1.10, descripcion: '100g. Base vegetal, niacinamida, protección y regeneración.'),
  Producto(nombre: 'Natural Antibacterial', categoria: 'Antibacterial', precio: 1.10, descripcion: '100g. Base vegetal, niacinamida, sin fragancia.'),
  Producto(nombre: 'Fresh Antibacterial', categoria: 'Antibacterial', precio: 1.10, descripcion: '100g. Base vegetal, niacinamida, efecto ultra refrescante.'),
  Producto(nombre: 'The Boss Antibacterial', categoria: 'Antibacterial', precio: 1.10, descripcion: '100g. Base vegetal, niacinamida, cuidado masculino.'),

  // 5. Línea The Boss ($0.90)
  Producto(nombre: 'The Boss (Clásico)', categoria: 'The Boss', precio: 0.90, descripcion: '100g. Fragancia masculina, limpieza profunda y afeitado suave.'),
  Producto(nombre: 'The Boss 2 en 1 Energy', categoria: 'The Boss', precio: 0.90, descripcion: '100g. Ducha y afeitado, energía para el hombre.'),
];