import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/territorial_models.dart';

class WeatherFetchResult {
  const WeatherFetchResult({
    required this.hourlyData,
    required this.rainfallPeriodMm,
    required this.soilMoisturePercent,
    required this.isLiveApi,
    required this.sourceLabel,
  });

  final List<HourlyHydroData> hourlyData;
  final double rainfallPeriodMm;
  final int soilMoisturePercent;
  final bool isLiveApi;
  final String sourceLabel;
}

/// Serviço de consumo da API pública Open-Meteo (sem chave de API)
/// para precipitação horária/diária, probabilidade de chuva e umidade do solo,
/// com suporte a seleção de data e período (24h, 3 dias, 7 dias).
class WeatherApiService {
  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<WeatherFetchResult> fetchHydroForecast({
    required double latitude,
    required double longitude,
    required DateTime referenceDate,
    required ChartPeriod period,
  }) async {
    final endDate = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final startDate = endDate.subtract(Duration(days: period.days - 1));

    final queryParams = <String, String>{
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'start_date': _isoDate(startDate),
      'end_date': _isoDate(endDate),
      'timezone': 'America/Sao_Paulo',
    };

    if (period == ChartPeriod.d7) {
      queryParams['daily'] = 'precipitation_sum,precipitation_probability_max';
      queryParams['hourly'] = 'soil_moisture_0_to_1cm';
    } else {
      queryParams['hourly'] =
          'precipitation,precipitation_probability,soil_moisture_0_to_1cm';
    }

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', queryParams);

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 7));
      if (response.statusCode != 200) {
        return _syntheticFallback(endDate, period);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final hourly = decoded['hourly'] as Map<String, dynamic>?;
      final soilRaw = (hourly?['soil_moisture_0_to_1cm'] as List<dynamic>?)
              ?.map((e) => (e as num?)?.toDouble() ?? 0.32)
              .toList() ??
          const <double>[];

      final avgSoil = soilRaw.isEmpty
          ? 62
          : ((soilRaw.reduce((a, b) => a + b) / soilRaw.length) * 180)
              .round()
              .clamp(25, 96);

      if (period == ChartPeriod.d7) {
        final daily = decoded['daily'] as Map<String, dynamic>?;
        if (daily == null) return _syntheticFallback(endDate, period);

        final times = (daily['time'] as List<dynamic>).cast<String>();
        final sums = (daily['precipitation_sum'] as List<dynamic>)
            .map((e) => (e as num?)?.toDouble() ?? 0.0)
            .toList();
        final probs = (daily['precipitation_probability_max'] as List<dynamic>?)
                ?.map((e) => (e as num?)?.toInt() ?? 0)
                .toList() ??
            const <int>[];

        final list = <HourlyHydroData>[];
        double totalRain = 0;
        for (var i = 0; i < times.length; i++) {
          final dt = DateTime.tryParse(times[i]);
          final label = dt != null
              ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}'
              : times[i];
          final rain = i < sums.length ? sums[i] : 0.0;
          final prob = i < probs.length ? probs[i] : 0;
          totalRain += rain;
          list.add(
            HourlyHydroData(
              hourLabel: label,
              precipitationMm: double.parse(rain.toStringAsFixed(1)),
              probabilityPercent: prob,
            ),
          );
        }

        return WeatherFetchResult(
          hourlyData: list,
          rainfallPeriodMm: double.parse(totalRain.toStringAsFixed(1)),
          soilMoisturePercent: avgSoil,
          isLiveApi: true,
          sourceLabel: 'Open-Meteo API (Tempo Real)',
        );
      }

      if (hourly == null) return _syntheticFallback(endDate, period);

      final times = (hourly['time'] as List<dynamic>).cast<String>();
      final precip = (hourly['precipitation'] as List<dynamic>)
          .map((e) => (e as num?)?.toDouble() ?? 0.0)
          .toList();
      final probs = (hourly['precipitation_probability'] as List<dynamic>?)
              ?.map((e) => (e as num?)?.toInt() ?? 0)
              .toList() ??
          const <int>[];

      if (period == ChartPeriod.h24) {
        final list = <HourlyHydroData>[];
        double totalRain = 0;
        for (var i = 0; i < times.length && i < 24; i++) {
          final rawTime = times[i];
          final hour =
              rawTime.length >= 16 ? rawTime.substring(11, 16) : '${i}h';
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

        return WeatherFetchResult(
          hourlyData: list,
          rainfallPeriodMm: double.parse(totalRain.toStringAsFixed(1)),
          soilMoisturePercent: avgSoil,
          isLiveApi: true,
          sourceLabel: 'Open-Meteo API (Tempo Real)',
        );
      }

      // Período de 3 dias: agrupa em blocos de 9 horas (~8 barras) para leitura limpa
      const bucketSize = 9;
      final list = <HourlyHydroData>[];
      double totalRain = 0;
      for (var i = 0; i < times.length; i += bucketSize) {
        double bucketSum = 0;
        int maxProb = 0;
        final endIdx = math.min(i + bucketSize, times.length);
        for (var j = i; j < endIdx; j++) {
          final r = j < precip.length ? precip[j] : 0.0;
          final p = j < probs.length ? probs[j] : 0;
          bucketSum += r;
          if (p > maxProb) maxProb = p;
        }
        totalRain += bucketSum;

        final dt = DateTime.tryParse(times[i]);
        final label = dt != null
            ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}h'
            : times[i];
        list.add(
          HourlyHydroData(
            hourLabel: label,
            precipitationMm: double.parse(bucketSum.toStringAsFixed(1)),
            probabilityPercent: maxProb,
          ),
        );
      }

      return WeatherFetchResult(
        hourlyData: list,
        rainfallPeriodMm: double.parse(totalRain.toStringAsFixed(1)),
        soilMoisturePercent: avgSoil,
        isLiveApi: true,
        sourceLabel: 'Open-Meteo API (Tempo Real)',
      );
    } catch (_) {
      return _syntheticFallback(endDate, period);
    }
  }

  String _isoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  WeatherFetchResult _syntheticFallback(DateTime endDate, ChartPeriod period) {
    final seed = endDate.day + endDate.month * 31;
    final list = <HourlyHydroData>[];
    double total = 0;

    if (period == ChartPeriod.h24) {
      const hours = ['00:00', '03:00', '06:00', '09:00', '12:00', '15:00', '18:00', '21:00'];
      for (var i = 0; i < hours.length; i++) {
        final wave = math.sin((seed + i) * 0.85).abs();
        final rain = double.parse((1.5 + wave * 13.5).toStringAsFixed(1));
        total += rain;
        list.add(
          HourlyHydroData(
            hourLabel: hours[i],
            precipitationMm: rain,
            probabilityPercent: (40 + wave * 52).round().clamp(15, 98),
          ),
        );
      }
    } else if (period == ChartPeriod.d3) {
      final start = endDate.subtract(const Duration(days: 2));
      for (var i = 0; i < 8; i++) {
        final dt = start.add(Duration(hours: i * 9));
        final wave = math.cos((seed + i) * 0.75).abs();
        final rain = double.parse((4.0 + wave * 22.0).toStringAsFixed(1));
        total += rain;
        final label =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}h';
        list.add(
          HourlyHydroData(
            hourLabel: label,
            precipitationMm: rain,
            probabilityPercent: (45 + wave * 50).round().clamp(20, 98),
          ),
        );
      }
    } else {
      final start = endDate.subtract(const Duration(days: 6));
      for (var i = 0; i < 7; i++) {
        final dt = start.add(Duration(days: i));
        final wave = math.sin((seed + i * 2) * 0.65).abs();
        final rain = double.parse((6.0 + wave * 42.0).toStringAsFixed(1));
        total += rain;
        final label =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
        list.add(
          HourlyHydroData(
            hourLabel: label,
            precipitationMm: rain,
            probabilityPercent: (35 + wave * 60).round().clamp(15, 98),
          ),
        );
      }
    }

    return WeatherFetchResult(
      hourlyData: list,
      rainfallPeriodMm: double.parse(total.toStringAsFixed(1)),
      soilMoisturePercent: (62 + (seed % 26)).clamp(45, 92),
      isLiveApi: false,
      sourceLabel: 'Série Sintética Calibrada (Offline)',
    );
  }
}
