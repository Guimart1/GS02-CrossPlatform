import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum RiskType {
  alagamento('Alagamento', Icons.water_drop_outlined),
  desabamento('Desabamento', Icons.landslide_outlined);

  const RiskType(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum RiskLevel {
  baixo('Baixo', AppColors.low),
  moderado('Moderado', AppColors.moderate),
  alto('Alto', AppColors.high),
  critico('Crítico', AppColors.critical);

  const RiskLevel(this.label, this.color);
  final String label;
  final Color color;
}

class TerritorialZone {
  const TerritorialZone({
    required this.id,
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.slopeDegrees,
    required this.impermeabilityPercent,
    required this.estimatedResidents,
    required this.soilSaturationPercent,
    required this.rainfall24hMm,
    required this.primaryRisk,
  });

  final String id;
  final String name;
  final String region;
  final double latitude;
  final double longitude;
  final double slopeDegrees;
  final int impermeabilityPercent;
  final int estimatedResidents;
  final int soilSaturationPercent;
  final double rainfall24hMm;
  final RiskType primaryRisk;

  RiskLevel get currentLevel {
    final score = (rainfall24hMm * 0.9) +
        (soilSaturationPercent * 0.55) +
        (slopeDegrees * 0.8);
    if (score >= 110) return RiskLevel.critico;
    if (score >= 85) return RiskLevel.alto;
    if (score >= 60) return RiskLevel.moderado;
    return RiskLevel.baixo;
  }

  TerritorialZone copyWith({
    int? soilSaturationPercent,
    double? rainfall24hMm,
  }) {
    return TerritorialZone(
      id: id,
      name: name,
      region: region,
      latitude: latitude,
      longitude: longitude,
      slopeDegrees: slopeDegrees,
      impermeabilityPercent: impermeabilityPercent,
      estimatedResidents: estimatedResidents,
      soilSaturationPercent:
          soilSaturationPercent ?? this.soilSaturationPercent,
      rainfall24hMm: rainfall24hMm ?? this.rainfall24hMm,
      primaryRisk: primaryRisk,
    );
  }
}

class HourlyHydroData {
  const HourlyHydroData({
    required this.hourLabel,
    required this.precipitationMm,
    required this.probabilityPercent,
  });

  final String hourLabel;
  final double precipitationMm;
  final int probabilityPercent;
}

class PredictiveAlert {
  const PredictiveAlert({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    required this.riskType,
    required this.riskLevel,
    required this.title,
    required this.horizonHours,
    required this.justification,
    required this.confidencePercent,
    required this.limitations,
    required this.recommendedActions,
    this.humanDecision,
    this.decisionNote,
    this.decidedAt,
  });

  final String id;
  final String zoneId;
  final String zoneName;
  final RiskType riskType;
  final RiskLevel riskLevel;
  final String title;
  final int horizonHours;
  final String justification;
  final int confidencePercent;
  final String limitations;
  final List<String> recommendedActions;
  final String? humanDecision;
  final String? decisionNote;
  final DateTime? decidedAt;

  String get confidenceLabel {
    if (confidencePercent >= 80) return 'Alta';
    if (confidencePercent >= 60) return 'Moderada';
    return 'Preliminar';
  }

  bool get isResolvedByHuman => humanDecision != null;

  PredictiveAlert copyWith({
    String? humanDecision,
    String? decisionNote,
    DateTime? decidedAt,
  }) {
    return PredictiveAlert(
      id: id,
      zoneId: zoneId,
      zoneName: zoneName,
      riskType: riskType,
      riskLevel: riskLevel,
      title: title,
      horizonHours: horizonHours,
      justification: justification,
      confidencePercent: confidencePercent,
      limitations: limitations,
      recommendedActions: recommendedActions,
      humanDecision: humanDecision ?? this.humanDecision,
      decisionNote: decisionNote ?? this.decisionNote,
      decidedAt: decidedAt ?? this.decidedAt,
    );
  }
}

class FieldOccurrence {
  const FieldOccurrence({
    required this.id,
    required this.title,
    required this.zoneId,
    required this.zoneName,
    required this.riskType,
    required this.severity,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String zoneId;
  final String zoneName;
  final RiskType riskType;
  final RiskLevel severity;
  final String description;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'zoneId': zoneId,
        'zoneName': zoneName,
        'riskType': riskType.name,
        'severity': severity.name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FieldOccurrence.fromJson(Map<String, dynamic> json) {
    return FieldOccurrence(
      id: json['id'] as String,
      title: json['title'] as String,
      zoneId: json['zoneId'] as String,
      zoneName: json['zoneName'] as String,
      riskType: RiskType.values.firstWhere(
        (e) => e.name == json['riskType'],
        orElse: () => RiskType.alagamento,
      ),
      severity: RiskLevel.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => RiskLevel.moderado,
      ),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class HumanDecisionRecord {
  const HumanDecisionRecord({
    required this.id,
    required this.alertId,
    required this.zoneName,
    required this.actionTaken,
    required this.note,
    required this.decidedAt,
  });

  final String id;
  final String alertId;
  final String zoneName;
  final String actionTaken;
  final String note;
  final DateTime decidedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'alertId': alertId,
        'zoneName': zoneName,
        'actionTaken': actionTaken,
        'note': note,
        'decidedAt': decidedAt.toIso8601String(),
      };

  factory HumanDecisionRecord.fromJson(Map<String, dynamic> json) {
    return HumanDecisionRecord(
      id: json['id'] as String,
      alertId: json['alertId'] as String,
      zoneName: json['zoneName'] as String,
      actionTaken: json['actionTaken'] as String,
      note: json['note'] as String,
      decidedAt: DateTime.parse(json['decidedAt'] as String),
    );
  }
}
