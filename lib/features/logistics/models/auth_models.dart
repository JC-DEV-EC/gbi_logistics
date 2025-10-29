
/// Request para login
class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
  };
}

/// Información de un subcourier
class SubcourierInfo {
  final int id;
  final String? name;
  final bool? showClients;

  const SubcourierInfo({
    required this.id,
    this.name,
    this.showClients,
  });

  factory SubcourierInfo.fromJson(Map<String, dynamic> json) => SubcourierInfo(
    id: json['id'] as int,
    name: json['name'] as String?,
    showClients: json['showClients'] as bool?,
  );
}

/// Estadísticas de estados de guías
class GuideStateStatistics {
  final String? status;
  final int count;

  const GuideStateStatistics({
    this.status,
    required this.count,
  });

  factory GuideStateStatistics.fromJson(Map<String, dynamic> json) => GuideStateStatistics(
    status: json['status'] as String?,
    count: json['count'] as int,
  );
}

/// Datos del dashboard
class DashboardData {
  final List<GuideStateStatistics> guideStadistics;

  const DashboardData({
    required this.guideStadistics,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    guideStadistics: (json['guideStadistics'] as List<dynamic>?)
        ?.map((e) => GuideStateStatistics.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );
}

/// Respuesta de login
class LoginResponse {
  final String? token;
  final String? personFirstName;
  final String? personLastName;
  final String? entityName;
  final String? courierImageUrl;
  final List<SubcourierInfo> subcouriersInformation;
  final DashboardData dashboardData;

  const LoginResponse({
    this.token,
    this.personFirstName,
    this.personLastName,
    this.entityName,
    this.courierImageUrl,
    required this.subcouriersInformation,
    required this.dashboardData,
  });

  /// Crea una respuesta vacía
  factory LoginResponse.empty() => LoginResponse(
    subcouriersInformation: [],
    dashboardData: DashboardData(guideStadistics: []),
  );

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // La API devuelve la respuesta dentro de content
    final content = json['content'] as Map<String, dynamic>;
    return LoginResponse(
      token: content['token'] as String?,
      personFirstName: content['personFirstName'] as String?,
      personLastName: content['personLastName'] as String?,
      entityName: content['entityName'] as String?,
      courierImageUrl: content['courierImageUrl'] as String?,
      subcouriersInformation: (content['subcouriersInformation'] as List<dynamic>?)
          ?.map((e) => SubcourierInfo.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      dashboardData: content['dashboardData'] != null
          ? DashboardData.fromJson(content['dashboardData'] as Map<String, dynamic>)
          : DashboardData(guideStadistics: []),
    );
  }

  Map<String, dynamic> toJson() => {
    'content': {
      'token': token,
      'personFirstName': personFirstName,
      'personLastName': personLastName,
      'entityName': entityName,
      'courierImageUrl': courierImageUrl,
      'subcouriersInformation': subcouriersInformation
          .map((e) => {
            'id': e.id,
            'name': e.name,
            'showClients': e.showClients,
          })
          .toList(),
      'dashboardData': {
        'guideStadistics': dashboardData.guideStadistics
            .map((e) => {
              'status': e.status,
              'count': e.count,
            })
            .toList(),
      },
    },
  };
}
