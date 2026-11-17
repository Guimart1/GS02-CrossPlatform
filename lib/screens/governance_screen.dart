import 'package:flutter/material.dart';
import '../state/territorial_state.dart';
import '../theme/app_theme.dart';
import '../widgets/flow_painters.dart';

class GovernanceScreen extends StatelessWidget {
  const GovernanceScreen({super.key, required this.state});

  final TerritorialState state;

  @override
  Widget build(BuildContext context) {
    final hc = state.highContrast;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        FlowStreakCard(
          highContrast: hc,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Acessibilidade & Privacidade',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Modo Alto Contraste'),
                subtitle: const Text(
                  'Reforça bordas e tipografia em preto puro para leitura sob sol intenso.',
                ),
                value: state.highContrast,
                onChanged: (val) =>
                    state.updateAccessibility(highContrastMode: val),
              ),
              const Divider(),
              const Text(
                'Escala de Fonte',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: state.textScale,
                min: 0.9,
                max: 1.3,
                divisions: 4,
                label: '${(state.textScale * 100).round()}%',
                onChanged: (val) =>
                    state.updateAccessibility(newTextScale: val),
              ),
              const Divider(),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Anonimização Estrita (LGPD)'),
                subtitle: const Text(
                  'Agrega população por microbacia e bloqueia coleta de dados pessoais.',
                ),
                value: state.anonymizeCitizenData,
                onChanged: (val) => state.updateAccessibility(anonymize: val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FlowStreakCard(
          highContrast: hc,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Histórico de Decisões Humanas (${state.decisionHistory.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Trilha de auditoria das deliberações tomadas pelo gestor público.',
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 12),
              if (state.decisionHistory.isEmpty)
                const Text(
                  'Nenhuma decisão registrada ainda. Analise os alertas na aba Alertas.',
                  style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
                )
              else
                ...state.decisionHistory.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.zoneName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            d.actionTaken,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (d.note.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              d.note,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FlowStreakCard(
          highContrast: hc,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transparência & Fontes de Dados',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                '• Meteorologia e umidade do solo: Open-Meteo Forecast API (dados públicos em tempo real).\n'
                '• Parâmetros topográficos e declividade: base territorial sintética calibrada para simulação acadêmica.\n'
                '• Limitação ética: o GeoFluxo não executa acionamentos automáticos de defesa civil ou evacuação.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
