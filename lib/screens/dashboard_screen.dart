import 'package:flutter/material.dart';
import '../models/territorial_models.dart';
import '../state/territorial_state.dart';
import '../theme/app_theme.dart';
import '../widgets/flow_painters.dart';
import '../widgets/precipitation_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.state,
    required this.onNavigateToAlerts,
  });

  final TerritorialState state;
  final VoidCallback onNavigateToAlerts;

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now.add(const Duration(days: 7)),
    );
    if (picked != null) {
      await state.setChartDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zone = state.selectedZone;
    final hc = state.highContrast;

    return RefreshIndicator(
      onRefresh: state.refreshTelemetry,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          _HeaderBanner(state: state),
          const SizedBox(height: 16),
          // Seletor de território / microbacia
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.zones.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final z = state.zones[index];
                final selected = z.id == zone.id;
                return ChoiceChip(
                  label: Text(z.name),
                  selected: selected,
                  onSelected: (_) => state.selectZone(z.id),
                  backgroundColor: AppColors.canvas,
                  selectedColor:
                      (hc ? Colors.black : AppColors.primary).withValues(alpha: 0.12),
                  side: BorderSide(
                    color: selected
                        ? (hc ? Colors.black : AppColors.primary)
                        : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? (hc ? Colors.black : AppColors.primary)
                        : AppColors.inkMuted,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // KPIs principais
          Row(
            children: [
              Expanded(
                child: FlowStreakCard(
                  highContrast: hc,
                  accentColor: zone.currentLevel.color,
                  semanticLabel:
                      'Chuva acumulada em 24 horas: ${zone.rainfall24hMm} milímetros',
                  child: _KpiContent(
                    icon: Icons.water_drop_outlined,
                    label: 'Chuva 24h',
                    value: '${zone.rainfall24hMm.toStringAsFixed(1)} mm',
                    sublabel: zone.region.split('•').first.trim(),
                    accent: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FlowStreakCard(
                  highContrast: hc,
                  accentColor: AppColors.accent,
                  semanticLabel:
                      'Saturação do solo: ${zone.soilSaturationPercent} por cento',
                  child: _KpiContent(
                    icon: Icons.layers_outlined,
                    label: 'Saturação do Solo',
                    value: '${zone.soilSaturationPercent}%',
                    sublabel: 'Declive ${zone.slopeDegrees.toStringAsFixed(0)}°',
                    accent: zone.soilSaturationPercent >= 80
                        ? AppColors.critical
                        : AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FlowStreakCard(
                  highContrast: hc,
                  accentColor: AppColors.high,
                  onTap: onNavigateToAlerts,
                  semanticLabel:
                      'Alertas aguardando decisão humana: ${state.pendingAlertsCount}',
                  child: _KpiContent(
                    icon: Icons.notifications_active_outlined,
                    label: 'Decisões Pendentes',
                    value: '${state.pendingAlertsCount}',
                    sublabel: 'Toque para analisar',
                    accent: state.pendingAlertsCount > 0
                        ? AppColors.high
                        : AppColors.low,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FlowStreakCard(
                  highContrast: hc,
                  accentColor: zone.currentLevel.color,
                  semanticLabel:
                      'Nível territorial atual: ${zone.currentLevel.label}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Risco Territorial',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      RiskPill(level: zone.currentLevel),
                      const SizedBox(height: 8),
                      Text(
                        'Impermeab. ${zone.impermeabilityPercent}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Gráfico de precipitação alterável por data e período
          FlowStreakCard(
            highContrast: hc,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fluxo Pluviométrico (${state.selectedPeriod.label})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total no período: ${state.periodRainfallMm.toStringAsFixed(1)} mm',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Controles de data e período
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Dia anterior',
                            icon: const Icon(Icons.chevron_left, size: 20),
                            onPressed: () => state.setChartDate(
                              state.selectedDate.subtract(const Duration(days: 1)),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _pickDate(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDate(state.selectedDate),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Próximo dia',
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: () {
                              final next = state.selectedDate
                                  .add(const Duration(days: 1));
                              final maxDate =
                                  DateTime.now().add(const Duration(days: 7));
                              if (!next.isAfter(maxDate)) {
                                state.setChartDate(next);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ChartPeriod.values.map((period) {
                        final isSelected = state.selectedPeriod == period;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(period.label),
                            selected: isSelected,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) => state.setChartPeriod(period),
                            backgroundColor: AppColors.surface,
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.14),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.inkMuted,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PrecipitationChart(
                  data: state.hourlyHydro,
                  highContrast: hc,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Mapa tabular de microbacias e encostas monitoradas
          FlowStreakCard(
            highContrast: hc,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Microbacias & Encostas Monitoradas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'População estimada agregada por setor (dados anonimizados)',
                  style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 12),
                ...state.zones.map(
                  (z) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => state.selectZone(z.id),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: z.id == zone.id
                              ? AppColors.primary.withValues(alpha: 0.05)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: z.id == zone.id
                                ? AppColors.primary.withValues(alpha: 0.35)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              z.primaryRisk.icon,
                              color: z.currentLevel.color,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    z.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Solo ${z.soilSaturationPercent}% • Chuva ${z.rainfall24hMm.toStringAsFixed(1)} mm • ~${(z.estimatedResidents / 1000).toStringAsFixed(1)}k hab.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            RiskPill(level: z.currentLevel),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({required this.state});

  final TerritorialState state;

  @override
  Widget build(BuildContext context) {
    return FlowStreakCard(
      highContrast: state.highContrast,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.hub_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Central GeoFluxo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.dataSourceLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: state.isLiveApi
                        ? AppColors.low
                        : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Atualizar telemetria',
            onPressed: state.isLoading ? null : state.refreshTelemetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _KpiContent extends StatelessWidget {
  const _KpiContent({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sublabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: accent,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sublabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}
