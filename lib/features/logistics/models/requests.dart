import 'cube_type.dart';

/// Request para crear un nuevo cubo de transporte
class NewTransportCubeRequest {
  final List<String> guides;
  final CubeType type;

  const NewTransportCubeRequest({
    required this.guides,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'guides': guides,
    'type': type.toString(),
  };
}

/// Request para cambiar el estado de un cubo de transporte
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

/// Request para despachar guías a cliente
class DispatchedGuideToClientRequest {
  final int subcourierId;
  final List<String> guides;

  const DispatchedGuideToClientRequest({
    required this.subcourierId,
    required this.guides,
  });

  Map<String, dynamic> toJson() => {
    'subcourierId': subcourierId,
    'guides': guides,
  };
}
