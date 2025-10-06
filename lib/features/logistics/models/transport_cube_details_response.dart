import 'transport_cube_details.dart';

/// Respuesta genérica que envuelve los detalles de un cubo
class GetTransportCubeDetailsResponseGenericResponse {
  final int code;
  final String? responseType;
  final String? message;
  final String? messageDetail;
  final TransportCubeDetails? content;

  const GetTransportCubeDetailsResponseGenericResponse({
    required this.code,
    this.responseType,
    this.message,
    this.messageDetail,
    this.content,
  });

  factory GetTransportCubeDetailsResponseGenericResponse.fromJson(Map<String, dynamic> json) {
    return GetTransportCubeDetailsResponseGenericResponse(
      code: json['code'] as int,
      responseType: json['responseType'] as String?,
      message: json['message'] as String?,
      messageDetail: json['messageDetail'] as String?,
      content: json['content'] == null
          ? null
          : TransportCubeDetails.fromJson(json['content'] as Map<String, dynamic>),
    );
  }
}