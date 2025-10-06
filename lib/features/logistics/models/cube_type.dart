/// Tipos de cubo de transporte
enum CubeType {
  /// Tránsito a bodega
  transitToWarehouse('TransitToWarehouse'),

  /// Despacho a subcourier
  toDispatchToSubcourier('ToDispatchToSubcourier'),

  /// Despacho a cliente
  toDispatchToClient('ToDispatchToClient');

  final String value;
  const CubeType(this.value);

  @override
  String toString() => value;

  static CubeType? fromString(String? value) {
    if (value == null) return null;
    return CubeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CubeType.transitToWarehouse,
    );
  }

  static CubeType? fromInt(int? code) {
    if (code == null) return null;
    switch (code) {
      case 0:
        return CubeType.transitToWarehouse;
      case 1:
        return CubeType.toDispatchToSubcourier;
      case 2:
        return CubeType.toDispatchToClient;
      default:
        return null;
    }
  }

  static CubeType? fromDynamic(dynamic v) {
    if (v == null) return null;
    if (v is int) return fromInt(v);
    if (v is String) {
      // Puede venir nombre o número como string
      final parsed = int.tryParse(v);
      if (parsed != null) return fromInt(parsed);
      return fromString(v);
    }
    return null;
  }
}