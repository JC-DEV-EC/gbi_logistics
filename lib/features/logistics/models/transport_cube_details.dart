import 'package:flutter/foundation.dart';
import 'transport_cube_info.dart';
import 'guide_transport_cube_info.dart';

/// Detalles completos de un cubo de transporte
@immutable
class TransportCubeDetails {
  final TransportCubeInfo transportCube;
  final List<GuideTransportCubeInfo> guides;

  const TransportCubeDetails({
    required this.transportCube,
    required this.guides,
  });

  factory TransportCubeDetails.fromJson(Map<String, dynamic> content) {
    // Aquí recibimos directamente el objeto 'content' del API
    return TransportCubeDetails(
      transportCube: TransportCubeInfo.fromJson(
        content['transportCube'] as Map<String, dynamic>,
      ),
      guides: (content['guides'] as List<dynamic>)
          .map((e) => GuideTransportCubeInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}