import 'package:flutter/material.dart';
import '../models/territorial_models.dart';
import '../state/territorial_state.dart';
import '../theme/app_theme.dart';
import '../widgets/flow_painters.dart';

class OccurrenceFormScreen extends StatefulWidget {
  const OccurrenceFormScreen({super.key, required this.state});

  final TerritorialState state;

  @override
  State<OccurrenceFormScreen> createState() => _OccurrenceFormScreenState();
}

class _OccurrenceFormScreenState extends State<OccurrenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  late String _selectedZoneId;
  RiskType _riskType = RiskType.alagamento;
  RiskLevel _severity = RiskLevel.moderado;
  bool _submitting = false;

  // Padrões simples para impedir registro acidental de CPF/telefone (privacidade LGPD)
  static final _piiPattern = RegExp(r'(\d{3}\.?\d{3}\.?\d{3}-?\d{2})|(\(\d{2}\)\s?\d{4,5}-?\d{4})');

  @override
  void initState() {
    super.initState();
    _selectedZoneId = widget.state.selectedZoneId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    await widget.state.addFieldOccurrence(
      title: _titleController.text.trim(),
      zoneId: _selectedZoneId,
      riskType: _riskType,
      severity: _severity,
      description: _descController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    _titleController.clear();
    _descController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ocorrência territorial salva localmente com sucesso.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hc = widget.state.highContrast;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        FlowStreakCard(
          highContrast: hc,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrar Ocorrência de Campo',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Use apenas referências de macro-setor. Dados pessoais de cidadãos não devem ser inseridos.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título resumido da ocorrência *',
                    hintText: 'Ex: Obstrução de boca de lobo na via principal',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 6) {
                      return 'Informe ao menos 6 caracteres para identificar o ponto.';
                    }
                    if (_piiPattern.hasMatch(text)) {
                      return 'Não inclua CPF ou telefone para preservar a privacidade.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedZoneId,
                  decoration: const InputDecoration(
                    labelText: 'Microbacia / Encosta *',
                  ),
                  items: widget.state.zones
                      .map(
                        (z) => DropdownMenuItem(
                          value: z.id,
                          child: Text(z.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedZoneId = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<RiskType>(
                        initialValue: _riskType,
                        decoration: const InputDecoration(labelText: 'Tipo *'),
                        items: RiskType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.label),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _riskType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<RiskLevel>(
                        initialValue: _severity,
                        decoration:
                            const InputDecoration(labelText: 'Severidade *'),
                        items: RiskLevel.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _severity = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observação técnica / referência pública *',
                    hintText:
                        'Ex: Acúmulo de água de 25 cm próximo à ponte; trinca visível em talude.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 12) {
                      return 'Descreva a situação observada (mínimo 12 caracteres).';
                    }
                    if (_piiPattern.hasMatch(text)) {
                      return 'Remova números de CPF ou telefone (privacidade LGPD).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      _submitting ? 'Salvando...' : 'Salvar Ocorrência',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FlowStreakCard(
          highContrast: hc,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ocorrências Registradas (${widget.state.occurrences.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (widget.state.occurrences.isEmpty)
                const Text(
                  'Nenhuma ocorrência de campo registrada neste dispositivo ainda.',
                  style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
                )
              else
                ...widget.state.occurrences.map(
                  (occ) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                occ.riskType.icon,
                                size: 18,
                                color: occ.severity.color,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  occ.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              RiskPill(level: occ.severity),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            occ.zoneName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            occ.description,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
