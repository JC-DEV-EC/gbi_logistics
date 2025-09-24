/// Request para actualizar estado de una guía
class UpdateGuideStatusRequest {
  final List<String> guides;
  final String newStatus;

  const UpdateGuideStatusRequest({
    required this.guides,
    required this.newStatus,
  });

  Map<String, dynamic> toJson() => {
    'guides': guides,
    'newStatus': newStatus,
  };
}

class UpdateGuideStatusResponse {
  final String? guideCode;
  final int statusId;
  final String? subStatusId;
  final String? observation;

  UpdateGuideStatusResponse({
    this.guideCode,
    required this.statusId,
    this.subStatusId,
    this.observation,
  });

  factory UpdateGuideStatusResponse.fromJson(Map<String, dynamic> json) {
    return UpdateGuideStatusResponse(
      guideCode: json['guideCode'] as String?,
      statusId: json['statusId'] as int,
      subStatusId: json['subStatusId'] as String?,
      observation: json['observation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'guideCode': guideCode,
    'statusId': statusId,
    'subStatusId': subStatusId,
    'observation': observation,
  };
}

/// Request para despachar guía a cliente
class DispatchGuideToClientRequest {
  final int subcourierId;
  final List<String> guides;

  const DispatchGuideToClientRequest({
    required this.subcourierId,
    required this.guides,
  });

  Map<String, dynamic> toJson() => {
    'subcourierId': subcourierId,
    'guides': guides,
  };
}

/// Request para crear un nuevo cubo de transporte
class NewTransportCubeRequest {
  /// Códigos de las guías a despachar
  final List<String> guides;

  NewTransportCubeRequest({
    required this.guides,
  }) {
    if (guides.isEmpty) {
      throw ArgumentError('La lista de guías no puede estar vacía');
    }
  }

  Map<String, dynamic> toJson() => {
    'guides': guides,
  };
}

/// Response para crear un nuevo cubo de transporte
class NewTransportCubeResponse {
  /// Id del cubo de transporte
  final int id;
  /// Identificador del cubo de transporte
  final String? transportCubeLabelId;

  const NewTransportCubeResponse({
    required this.id,
    this.transportCubeLabelId,
  });

  factory NewTransportCubeResponse.fromJson(Map<String, dynamic> json) {
    return NewTransportCubeResponse(
      id: json['id'] as int,
      transportCubeLabelId: json['transportCubeLabelId'] as String?,
    );
  }
}

/// Respuesta genérica que envuelve la respuesta de crear cubo
class NewTransportCubeResponseGenericResponse {
  final int code;
  final String? responseType;
  final String? message;
  final String? messageDetail;
  final NewTransportCubeResponse? content;

  const NewTransportCubeResponseGenericResponse({
    required this.code,
    this.responseType,
    this.message,
    this.messageDetail,
    this.content,
  });

  factory NewTransportCubeResponseGenericResponse.fromJson(Map<String, dynamic> json) {
    return NewTransportCubeResponseGenericResponse(
      code: json['code'] as int,
      responseType: json['responseType'] as String?,
      message: json['message'] as String?,
      messageDetail: json['messageDetail'] as String?,
      content: json['content'] == null
          ? null
          : NewTransportCubeResponse.fromJson(json['content'] as Map<String, dynamic>),
    );
  }
}

/// Request para cambiar estado de cubo
class ChangeTranportCubesStateRequest {
  final List<int> transportCubeIds;
  final String newState;

  const ChangeTranportCubesStateRequest({
    required this.transportCubeIds,
    required this.newState,
  });

  Map<String, dynamic> toJson() => {
    'transportCubeIds': transportCubeIds,
    'newState': newState,
  };
}

/// Request para cambiar guía de cubo
class ChangeCubeGuideRequest {
  final List<String> guides;
  final int destinationCubeId;

  const ChangeCubeGuideRequest({
    required this.guides,
    required this.destinationCubeId,
  });

  Map<String, dynamic> toJson() => {
    'guides': guides,
    'destinationCubeId': destinationCubeId,
  };
}

/// Response paginada para guías
/// Estados de tracking del backend
class TrackingStateType {
  /// Estados de tracking según el API
  static const String readyForShipment = 'ReadyForShipment';
  static const String inAirline = 'InAirline';
  static const String internationalTransit = 'InternationalTransit';
  static const String arrivedInEcuador = 'ArrivedInEcuador';
  static const String enteredCustoms = 'EnteredCustoms';
  static const String physicalInspection = 'PhysicalInspection';
  static const String authorizedExit = 'AuthorizedExit';
  static const String receivedInLocalWarehouse = 'ReceivedInLocalWarehouse';
  static const String inLocalDistribution = 'InLocalDistribution';
  static const String deliveredToFinalDestination = 'DeliveredToFinalDestination';
  static const String waitingForTaxPayment = 'WaitingForTaxPayment';
  static const String specialCase = 'SpecialCase';
  static const String emptyPackage = 'EmptyPackage';
  static const String documentaryInspection = 'DocumentaryInspection';
  static const String dispatchedFromCustoms = 'DispatchedFromCustoms';
  static const String transitToWarehouse = 'TransitToWarehouse';
  static const String observed = 'Observed';
  static const String readyForDelivery = 'ReadyForDelivery';
  static const String declaredAbandoned = 'DeclaredAbandoned';
  static const String didNotArrive = 'DidNotArrive';
  static const String inShippingCompany = 'InShippingCompany';
  static const String automaticInspection = 'AutomaticInspection';
  static const String packageCreated = 'PackageCreated';
  static const String dasRejected = 'DASRejected';
  static const String declared = 'Declared';
  static const String inInspectionProcess = 'InInspectionProcess';
  static const String waitingForWeighing = 'WaitingForWeighing';
  static const String dispatchRequested = 'DispatchRequested';
  static const String dispatchedFromCustomsWithOutCube = 'DispatchedFromCustomsWithOutCube';
}

class GetGuidesPaginatedResponse {
  final int totalRegister;
  final List<GuideInfo> registers;
  final String? userMessage;

  const GetGuidesPaginatedResponse({
    required this.totalRegister,
    required this.registers,
    this.userMessage,
  });

  factory GetGuidesPaginatedResponse.fromJson(Map<String, dynamic> json) {
    // La respuesta viene dentro de content
    final content = json['content'] as Map<String, dynamic>;
    return GetGuidesPaginatedResponse(
      totalRegister: content['totalRegister'] as int,
      registers: (content['registers'] as List<dynamic>?)
          ?.map((e) => GuideInfo.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      userMessage: content['userMessage'] as String?,
    );
  }
}

/// Información de una guía
class GuideInfo {
  final String? code;
  final String? subcourierName;
  final int packages;
  final String? stateLabel;
  final DateTime updateDateTime;

  const GuideInfo({
    this.code,
    this.subcourierName,
    required this.packages,
    this.stateLabel,
    required this.updateDateTime,
  });

  factory GuideInfo.fromJson(Map<String, dynamic> json) => GuideInfo(
    code: json['code'] as String?,
    subcourierName: json['subcourierName'] as String?,
    packages: json['packages'] as int,
    stateLabel: json['stateLabel'] as String?,
    updateDateTime: DateTime.parse(json['updateDateTime'] as String),
  );
}

/// Response paginada para cubos
class GetTransportCubesPaginatedResponse {
  final int totalRegister;
  final List<TransportCubeInfoAPI> registers;
  final String? userMessage;

  const GetTransportCubesPaginatedResponse({
    required this.totalRegister,
    required this.registers,
    this.userMessage,
  });

  factory GetTransportCubesPaginatedResponse.fromJson(Map<String, dynamic> json) {
    // La respuesta viene dentro de content
    final content = json['content'] as Map<String, dynamic>;
    return GetTransportCubesPaginatedResponse(
      totalRegister: content['totalRegister'] as int,
      registers: (content['registers'] as List<dynamic>?)
          ?.map((e) => TransportCubeInfoAPI.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      userMessage: content['userMessage'] as String?,
    );
  }
}

/// Información de un cubo (API)
class TransportCubeInfoAPI {
  final int id;
  final DateTime registerDateTime;
  final String state;
  final int guides;
  final String? stateLabel;

  const TransportCubeInfoAPI({
    required this.id,
    required this.registerDateTime,
    required this.state,
    required this.guides,
    this.stateLabel,
  });

  factory TransportCubeInfoAPI.fromJson(Map<String, dynamic> json) => TransportCubeInfoAPI(
    id: json['id'] as int,
    registerDateTime: DateTime.parse(json['registerDateTime'] as String),
    state: json['state'] as String,
    guides: json['guides'] as int,
    stateLabel: json['stateLabel'] as String?,
  );
}
