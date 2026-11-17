import 'package:flutter/foundation.dart';
import '../models/territorial_models.dart';
import '../services/storage_service.dart';
import '../services/weather_api_service.dart';

class TerritorialState extends ChangeNotifier {
  TerritorialState({
    WeatherApiService? weatherService,
    StorageService? storageService,
  })  : _weatherService = weatherService ?? WeatherApiService(),
        _storageService = storageService ?? StorageService();

  final WeatherApiService _weatherService;
  final StorageService _storageService;

  bool isLoading = false;
  bool isLiveApi = false;
  String dataSourceLabel = 'Carregando telemetria...';
  DateTime? lastUpdated;

  bool highContrast = false;
  double textScale = 1.0;
  bool anonymizeCitizenData = true;

  String selectedZoneId = 'z1';

  List<TerritorialZone> zones = [
    const TerritorialZone(
      id: 'z1',
      name: 'Microbacia Tamanduateí Sul',
      region: 'Zona Sudeste • Área Urbana Densa',
      latitude: -23.5950,
      longitude: -46.5850,
      slopeDegrees: 8.5,
      impermeabilityPercent: 87,
      estimatedResidents: 42800,
      soilSaturationPercent: 78,
      rainfall24hMm: 54.2,
      primaryRisk: RiskType.alagamento,
    ),
    const TerritorialZone(
      id: 'z2',
      name: 'Encosta Serra da Cantareira',
      region: 'Zona Norte • Declive Geotécnico',
      latitude: -23.4380,
      longitude: -46.6320,
      slopeDegrees: 31.0,
      impermeabilityPercent: 44,
      estimatedResidents: 18400,
      soilSaturationPercent: 86,
      rainfall24hMm: 63.4,
      primaryRisk: RiskType.desabamento,
    ),
    const TerritorialZone(
      id: 'z3',
      name: 'Várzea do Rio Aricanduva',
      region: 'Zona Leste • Fundo de Vale',
      latitude: -23.5560,
      longitude: -46.5120,
      slopeDegrees: 5.2,
      impermeabilityPercent: 91,
      estimatedResidents: 56200,
      soilSaturationPercent: 74,
      rainfall24hMm: 48.9,
      primaryRisk: RiskType.alagamento,
    ),
    const TerritorialZone(
      id: 'z4',
      name: 'Núcleo Rural Marsilac',
      region: 'Extremo Sul • Estrada Vicinal',
      latitude: -23.9080,
      longitude: -46.7010,
      slopeDegrees: 24.5,
      impermeabilityPercent: 19,
      estimatedResidents: 9300,
      soilSaturationPercent: 69,
      rainfall24hMm: 39.0,
      primaryRisk: RiskType.desabamento,
    ),
  ];

  List<HourlyHydroData> hourlyHydro = const [];
  List<PredictiveAlert> alerts = [];
  List<FieldOccurrence> occurrences = [];
  List<HumanDecisionRecord> decisionHistory = [];

  TerritorialZone get selectedZone =>
      zones.firstWhere((z) => z.id == selectedZoneId, orElse: () => zones.first);

  int get pendingAlertsCount =>
      alerts.where((a) => !a.isResolvedByHuman).length;

  RiskLevel get highestRiskLevel {
    var highest = RiskLevel.baixo;
    for (final z in zones) {
      if (z.currentLevel.index > highest.index) {
        highest = z.currentLevel;
      }
    }
    return highest;
  }

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    final prefs = await _storageService.loadPreferences();
    highContrast = prefs.highContrast;
    textScale = prefs.textScale;
    anonymizeCitizenData = prefs.anonymizeCitizenData;

    occurrences = await _storageService.loadOccurrences();
    decisionHistory = await _storageService.loadDecisions();

    _buildInitialAlerts();
    await refreshTelemetry();
  }

  Future<void> selectZone(String zoneId) async {
    if (selectedZoneId == zoneId) return;
    selectedZoneId = zoneId;
    notifyListeners();
    await refreshTelemetry();
  }

  Future<void> refreshTelemetry() async {
    isLoading = true;
    notifyListeners();

    final zone = selectedZone;
    final result = await _weatherService.fetchHydroForecast(
      latitude: zone.latitude,
      longitude: zone.longitude,
    );

    hourlyHydro = result.hourlyData;
    isLiveApi = result.isLiveApi;
    dataSourceLabel = result.sourceLabel;
    lastUpdated = DateTime.now();

    // Atualiza a zona selecionada com a leitura mais recente (mantendo variação realista se chuva for 0mm)
    final updatedRain = result.rainfall24hMm > 0
        ? result.rainfall24hMm
        : zone.rainfall24hMm;
    final updatedSoil = result.isLiveApi
        ? ((zone.soilSaturationPercent * 0.65) +
                (result.soilMoisturePercent * 0.35))
            .round()
        : result.soilMoisturePercent;

    zones = zones
        .map((z) => z.id == zone.id
            ? z.copyWith(
                rainfall24hMm: updatedRain,
                soilSaturationPercent: updatedSoil,
              )
            : z)
        .toList();

    isLoading = false;
    notifyListeners();
  }

  void _buildInitialAlerts() {
    alerts = [
      const PredictiveAlert(
        id: 'al-01',
        zoneId: 'z2',
        zoneName: 'Encosta Serra da Cantareira',
        riskType: RiskType.desabamento,
        riskLevel: RiskLevel.critico,
        title: 'Risco de escorregamento superficial nas próximas 6h',
        horizonHours: 6,
        justification:
            'Saturação do solo atingiu 86% sobre declividade média de 31°, combinada com acumulado de chuva superior a 60 mm nas últimas 24h.',
        confidencePercent: 84,
        limitations:
            'Não detecta trincas internas em fundações privadas nem intervenções recentes de contenção não cadastradas.',
        recommendedActions: [
          'Enviar equipe de vistoria geotécnica ao setor norte',
          'Emitir aviso preventivo de atenção aos moradores',
          'Avaliar interdição parcial de via vicinal após checagem visual',
        ],
      ),
      const PredictiveAlert(
        id: 'al-02',
        zoneId: 'z1',
        zoneName: 'Microbacia Tamanduateí Sul',
        riskType: RiskType.alagamento,
        riskLevel: RiskLevel.alto,
        title: 'Sobrecarga de macrodrenagem no pico pluviométrico',
        horizonHours: 4,
        justification:
            'Taxa de impermeabilização de 87% reduz infiltração; previsão horária indica concentração de 14 mm/h entre 15h e 18h.',
        confidencePercent: 79,
        limitations:
            'Projeção assume capacidade nominal de galerias; obstruções pontuais por resíduos sólidos podem antecipar o transbordamento.',
        recommendedActions: [
          'Posicionar equipe de limpeza preventiva em bocas de lobo críticas',
          'Alertar operadores de tráfego para rotas alternativas',
          'Monitorar régua limnimétrica do córrego a cada 30 min',
        ],
      ),
      const PredictiveAlert(
        id: 'al-03',
        zoneId: 'z3',
        zoneName: 'Várzea do Rio Aricanduva',
        riskType: RiskType.alagamento,
        riskLevel: RiskLevel.moderado,
        title: 'Acúmulo laminar em baixadas de fundo de vale',
        horizonHours: 8,
        justification:
            'Solo em 74% de saturação com escoamento lento em área de várzea urbana.',
        confidencePercent: 68,
        limitations:
            'Estação meteorológica de referência fica a 4,2 km; microclimas locais podem variar em até 20%.',
        recommendedActions: [
          'Manter bombas de drenagem em prontidão operacional',
          'Revisar estoque de barreiras móveis na subprefeitura',
        ],
      ),
    ];

    // Reaplica decisões já persistidas no aparelho
    for (var i = 0; i < alerts.length; i++) {
      final matching = decisionHistory
          .where((d) => d.alertId == alerts[i].id)
          .toList();
      if (matching.isNotEmpty) {
        final latest = matching.first;
        alerts[i] = alerts[i].copyWith(
          humanDecision: latest.actionTaken,
          decisionNote: latest.note,
          decidedAt: latest.decidedAt,
        );
      }
    }
  }

  Future<void> recordHumanDecision({
    required String alertId,
    required String actionTaken,
    required String note,
  }) async {
    final now = DateTime.now();
    final idx = alerts.indexWhere((a) => a.id == alertId);
    if (idx == -1) return;

    final target = alerts[idx];
    alerts[idx] = target.copyWith(
      humanDecision: actionTaken,
      decisionNote: note,
      decidedAt: now,
    );

    final record = HumanDecisionRecord(
      id: 'dec-${now.millisecondsSinceEpoch}',
      alertId: alertId,
      zoneName: target.zoneName,
      actionTaken: actionTaken,
      note: note,
      decidedAt: now,
    );

    decisionHistory = [record, ...decisionHistory];
    notifyListeners();
    await _storageService.saveDecisions(decisionHistory);
  }

  Future<void> addFieldOccurrence({
    required String title,
    required String zoneId,
    required RiskType riskType,
    required RiskLevel severity,
    required String description,
  }) async {
    final zone = zones.firstWhere((z) => z.id == zoneId, orElse: () => zones.first);
    final now = DateTime.now();
    final item = FieldOccurrence(
      id: 'occ-${now.millisecondsSinceEpoch}',
      title: title,
      zoneId: zone.id,
      zoneName: zone.name,
      riskType: riskType,
      severity: severity,
      description: description,
      createdAt: now,
    );

    occurrences = [item, ...occurrences];
    notifyListeners();
    await _storageService.saveOccurrences(occurrences);
  }

  Future<void> updateAccessibility({
    bool? highContrastMode,
    double? newTextScale,
    bool? anonymize,
  }) async {
    highContrast = highContrastMode ?? highContrast;
    textScale = newTextScale ?? textScale;
    anonymizeCitizenData = anonymize ?? anonymizeCitizenData;
    notifyListeners();
    await _storageService.savePreferences(
      highContrast: highContrast,
      textScale: textScale,
      anonymizeCitizenData: anonymizeCitizenData,
    );
  }
}
