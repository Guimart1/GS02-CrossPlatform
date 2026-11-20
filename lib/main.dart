import 'package:flutter/material.dart';
import 'screens/alerts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/governance_screen.dart';
import 'screens/occurrence_form_screen.dart';
import 'state/territorial_state.dart';
import 'theme/app_theme.dart';
import 'widgets/flow_painters.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GeoFluxoApp());
}

class GeoFluxoApp extends StatefulWidget {
  const GeoFluxoApp({super.key});

  @override
  State<GeoFluxoApp> createState() => _GeoFluxoAppState();
}

class _GeoFluxoAppState extends State<GeoFluxoApp> {
  final TerritorialState _state = TerritorialState();

  @override
  void initState() {
    super.initState();
    _state.initialize();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return MaterialApp(
          title: 'GeoFluxo — Inteligência Territorial',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(highContrast: _state.highContrast),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(_state.textScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: _MainShell(state: _state),
        );
      },
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell({required this.state});

  final TerritorialState state;

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  static const _titles = [
    'Painel Territorial',
    'Alertas Preditivos',
    'Registrar Ocorrência',
    'Governança & LGPD',
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        state: widget.state,
        onNavigateToAlerts: () => setState(() => _currentIndex = 1),
      ),
      AlertsScreen(state: widget.state),
      OccurrenceFormScreen(state: widget.state),
      GovernanceScreen(state: widget.state),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: FlowLinesBackground(
        highContrast: widget.state.highContrast,
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Painel',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: widget.state.pendingAlertsCount > 0,
              label: Text('${widget.state.pendingAlertsCount}'),
              child: const Icon(Icons.warning_amber_outlined),
            ),
            selectedIcon: const Icon(Icons.warning_amber_rounded),
            label: 'Alertas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_location_alt_outlined),
            selectedIcon: Icon(Icons.add_location_alt),
            label: 'Ocorrência',
          ),
          const NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Governança',
          ),
        ],
      ),
    );
  }
}
