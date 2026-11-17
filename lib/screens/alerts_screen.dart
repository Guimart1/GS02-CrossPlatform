import 'package:flutter/material.dart';
import '../models/territorial_models.dart';
import '../state/territorial_state.dart';
import '../theme/app_theme.dart';
import '../widgets/flow_painters.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, required this.state});

  final TerritorialState state;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  RiskType? _filter;

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == null
        ? widget.state.alerts
        : widget.state.alerts.where((a) => a.riskType == _filter).toList();
    final hc = widget.state.highContrast;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        FlowStreakCard(
          highContrast: hc,
          child: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Apoio à decisão humana: alertas indicam risco provável com justificativa e limitações. Nenhuma interdição ou evacuação é automatizada.',
                  style: TextStyle(fontSize: 12.5, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _FilterChip(
              label: 'Todos',
              selected: _filter == null,
              onTap: () => setState(() => _filter = null),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Alagamento',
              selected: _filter == RiskType.alagamento,
              onTap: () => setState(() => _filter = RiskType.alagamento),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Desabamento',
              selected: _filter == RiskType.desabamento,
              onTap: () => setState(() => _filter = RiskType.desabamento),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...filtered.map(
          (alert) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _AlertCard(
              alert: alert,
              highContrast: hc,
              onDecide: () => _openDecisionSheet(context, alert),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openDecisionSheet(
    BuildContext context,
    PredictiveAlert alert,
  ) async {
    String selectedAction = alert.recommendedActions.first;
    final noteController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Decisão do Gestor — ${alert.zoneName}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Selecione a ação preventiva a ser coordenada pela equipe humana:',
                      style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 12),
                    RadioGroup<String>(
                      groupValue: selectedAction,
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedAction = val);
                        }
                      },
                      child: Column(
                        children: [
                          ...alert.recommendedActions.map(
                            (action) => RadioListTile<String>(
                              value: action,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                action,
                                style: const TextStyle(fontSize: 13.5),
                              ),
                            ),
                          ),
                          const RadioListTile<String>(
                            value: 'Manter monitoramento sem despacho imediato',
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Manter monitoramento sem despacho imediato',
                              style: TextStyle(fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observação técnica do gestor (opcional)',
                        hintText: 'Ex: Equipe da subprefeitura acionada às 15h.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await widget.state.recordHumanDecision(
                            alertId: alert.id,
                            actionTaken: selectedAction,
                            note: noteController.text.trim().isEmpty
                                ? 'Registrado pelo gestor responsável.'
                                : noteController.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Registrar Decisão Humana'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.canvas,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.highContrast,
    required this.onDecide,
  });

  final PredictiveAlert alert;
  final bool highContrast;
  final VoidCallback onDecide;

  @override
  Widget build(BuildContext context) {
    return FlowStreakCard(
      highContrast: highContrast,
      accentColor: alert.riskLevel.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(alert.riskType.icon, color: alert.riskLevel.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${alert.zoneName} • Horizonte ${alert.horizonHours}h',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              RiskPill(level: alert.riskLevel),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Justificativa técnica',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            alert.justification,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          ConfidenceMeter(
            percent: alert.confidencePercent,
            label: alert.confidenceLabel,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Limitações do modelo',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.limitations,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (alert.isResolvedByHuman) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.low.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.low.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Decisão humana registrada',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.low,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alert.humanDecision!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (alert.decisionNote != null &&
                      alert.decisionNote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        alert.decisionNote!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDecide,
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: Text(
                alert.isResolvedByHuman
                    ? 'Atualizar Decisão Humana'
                    : 'Analisar e Decidir',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
