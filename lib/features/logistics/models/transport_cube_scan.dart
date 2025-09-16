/// Request para verificar escaneo de cubo
class TransportCubeScanRequest {
  final int cubeId;
  final List<String> scannedItems;

  const TransportCubeScanRequest({
    required this.cubeId,
    required this.scannedItems,
  });

  Map<String, dynamic> toJson() => {
    'cubeId': cubeId,
    'scannedItems': scannedItems,
  };
}
