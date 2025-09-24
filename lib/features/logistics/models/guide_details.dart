import 'package:flutter/foundation.dart';

/// Modelo de ítem de paquete
@immutable
class PackageItem {
  final int id;
  final String? trackingNumber;
  final double weight;
  final double volume;
  final double width;
  final double height;

  const PackageItem({
    required this.id,
    this.trackingNumber,
    required this.weight,
    required this.volume,
    required this.width,
    required this.height,
  });

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    return PackageItem(
      id: json['id'] as int,
      trackingNumber: json['trackingNumber'] as String?,
      weight: (json['weight'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'weight': weight,
      'volume': volume,
      'width': width,
      'height': height,
    };
  }
}

/// Modelo de detalles de guía
@immutable
class GuideDetails {
  final String? guideCode;
  final String? subcourierName;
  final String? courierName;
  final int packages;
  final String? dimensions;
  final double totalWeight;
  final String? mailbox;
  final String? stateLabel;
  final DateTime updateDateTime;
  final List<PackageItem>? packageItems;

  const GuideDetails({
    this.guideCode,
    this.subcourierName,
    this.courierName,
    required this.packages,
    this.dimensions,
    required this.totalWeight,
    this.mailbox,
    this.stateLabel,
    required this.updateDateTime,
    this.packageItems,
  });

  factory GuideDetails.fromJson(Map<String, dynamic> json) {
    return GuideDetails(
      guideCode: json['guideCode'] as String?,
      subcourierName: json['subcourierName'] as String?,
      courierName: json['courierName'] as String?,
      packages: json['packages'] as int? ?? 0,
      dimensions: json['dimensions'] as String?,
      totalWeight: (json['totalWeight'] as num?)?.toDouble() ?? 0.0,
      mailbox: json['mailbox'] as String?,
      stateLabel: json['stateLabel'] as String?,
      updateDateTime: DateTime.parse(json['updateDateTime'] as String),
      packageItems: (json['packageItems'] as List<dynamic>?)
          ?.map((e) => PackageItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guideCode': guideCode,
      'subcourierName': subcourierName,
      'courierName': courierName,
      'packages': packages,
      'dimensions': dimensions,
      'totalWeight': totalWeight,
      'mailbox': mailbox,
      'stateLabel': stateLabel,
      'updateDateTime': updateDateTime.toIso8601String(),
      'packageItems': packageItems?.map((e) => e.toJson()).toList(),
    };
  }
}