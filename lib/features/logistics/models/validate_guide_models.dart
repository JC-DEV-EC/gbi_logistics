
/// Request para validar estado de guía por proceso
class ValidateGuideStatusByProcessRequest {
  final int? subcourierId;
  final String? clientId;
  final String guideCode;
  final String processInformation;

  const ValidateGuideStatusByProcessRequest({
    this.subcourierId,
    this.clientId,
    required this.guideCode,
    required this.processInformation,
  });

  Map<String, dynamic> toJson() => {
    'subcourierId': subcourierId,
    'clientId': clientId,
    'guideCode': guideCode,
    'processInformation': processInformation,
  };
}

/// Cliente por subcourier
class ClientBySubcourierItem {
  final String? id;
  final String? name;

  const ClientBySubcourierItem({
    this.id,
    this.name,
  });

  factory ClientBySubcourierItem.fromJson(Map<String, dynamic> json) {
    return ClientBySubcourierItem(
      id: json['id'] as String?,
      name: json['name'] as String?,
    );
  }
}

/// Response para obtener clientes por subcourier
class GetClientBySubcourierResponse {
  final List<ClientBySubcourierItem>? clients;

  const GetClientBySubcourierResponse({
    this.clients,
  });

  factory GetClientBySubcourierResponse.fromJson(Map<String, dynamic> content) {
    return GetClientBySubcourierResponse(
      clients: (content['clients'] as List<dynamic>?)
          ?.map((e) => ClientBySubcourierItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Tipos de proceso para validación de guías
class ValidateGuideProcessType {
  static const String toRegisterCube = 'ToRegisterCube';
}