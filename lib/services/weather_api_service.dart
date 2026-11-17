import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/territorial_models.dart';

class WeatherFetchResult {
  const WeatherFetchResult({
    required this.hourlyData,
    required this.rainfall24hMm,
    required this.soilMoisturePercent,
    required this.isLiveApi,
    required this.sourceLabel,
  });

  final List<HourlyHydroData> hourlyData;
  final double rainfall24hMm;
  final int soilMoisturePercent;
  final bool isLiveApi;
  final String sourceLabel;
}

/// Serviço de consumo da API pública Open-Meteo (sem chave de API)
/// para precipitação horária, probabilidade de chuva e umidade superficial do solo.
/// Em caso de indisponibilidade de rede, retorna série sintética calibrada.
class WeatherApiService {
  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<WeatherFetchResult> fetchHydroForecast({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'hourly': 'precipitation,precipitation_probability,soil_moisture_0_to_1cm',
        'forecast_days': '1',
        'timezone': 'America/Sao_Paulo',
      },
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 7));
      if (response.statusCode != 200) {
        return _syntheticFallback();
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final hourly = decoded['hourly'] as Map<String, dynamic>?;
      if (hourly == null) {
        return _syntheticFallback();
      }

      final times = (hourly['time'] as List<dynamic>).cast<String>();
      final precip = (hourly['precipitation'] as List<dynamic>)
          .map((e) => (e as num?)?.toDouble() ?? 0.0)
          .toList();
      final probs = (hourly['precipitation_probability'] as List<dynamic>)
          .map((e) => (e as num?)?.toInt() ?? 0)
          .toList();
      final soilRaw = (hourly['soil_moisture_0_to_1cm'] as List<dynamic>?)
              ?.map((e) => (e as num?)?.toDouble() ?? 0.32)
              .toList() ??
          const <double>[];

      final list = <HourlyHydroData>[];
      double totalRain = 0;
      for (var i = 0; i < times.length && i < 24; i++) {
        final rawTime = times[i];
        final hour = rawTime.length >= 16 ? rawTime.substring(11, 16) : '${i}h';
        final rain = i < precip.length ? precip[i] : 0.0;
        final prob = i < probs.length ? probs[i] : 0;
        totalRain += rain;
        list.add(
          HourlyHydroData(
            hourLabel: hour,
            precipitationMm: rain,
            probabilityPercent: prob,
          ),
        );
      }

      final avgSoil = soilRaw.isEmpty
          ? 62
          : ((soilRaw.reduce((a, b) => a + b) / soilRaw.length) * 180)
              .round()
              .clamp(25, 96);

      return WeatherFetchResult(
        hourlyData: list,
        rainfall24hMm: double.parse(totalRain.toStringAsFixed(1)),
        soilMoisturePercent: avgSoil,
        isLiveApi: true,
        sourceLabel: 'Open-Meteo API (Tempo Real)',
      );
    } catch (_) {
      return _syntheticFallback();
    }
  }

  WeatherFetchResult _syntheticFallback() {
    const synthetic = [
      HourlyHydroData(hourLabel: '00:00', precipitationMm: 1.8, probabilityPercent: 45),
      HourlyHydroData(hourLabel: '03:00', precipitationMm: 4.2, probabilityPercent: 60),
      HourlyHydroData(hourLabel: '06:00', precipitationMm: 8.6, probabilityPercent: 78),
      HourlyHydroData(hourLabel: '09:00', precipitationMm: 12.4, probabilityPercent: 88),
      HourlyHydroData(hourLabel: '12:00', precipitationMm: 6.1, probabilityPercent: 70),
      HourlyHydroData(hourLabel: '15:00', precipitationMm: 14.8, probabilityPercent: 92),
      HourlyHydroData(hourLabel: '18:00', precipitationMm: 9.5, probabilityPercent: 84),
      HourlyHydroData(hourLabel: '21:00', precipitationMm: 3.4, probabilityPercent: 55),
    ];

    return const WeatherFetchResult(
      hourlyData: synthetic,
      rainfall24hMm: 60.8,
      soilMoisturePercent: 81,
      isLiveApi: false,
      sourceLabel: 'Série Sintética Calibrada (Offline)',
    );
  }
}
