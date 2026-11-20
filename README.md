# GeoFluxo — Painel de Inteligência Territorial (Alagamentos & Desabamentos)

Projeto desenvolvido para a **Global Solution** da disciplina **Cross-Platform Application Development** (FIAP — 2º Ano de Ciência da Computação).

**Repositório:** `https://github.com/Guimart1/GS02-CrossPlatform`

---

## Integrantes do Grupo
- **Guilherme Martins dos Santos** — RM566570
- **Gabriel Rodrigues Barbosa** — RM566475
- **Matheus Cordeiro Alves** — RM563107

---

## Descrição do Projeto
O **GeoFluxo** é um aplicativo mobile desenvolvido em **Flutter** que atua como um **painel de inteligência territorial** para apoiar gestores públicos e equipes de defesa civil na antecipação de riscos de **alagamentos** e **desabamentos** em microbacias urbanas e encostas.

O app adota uma identidade visual própria em **fundo branco**, com **sombras suaves** e **traços vetoriais ("riscos") animados** que simulam fluxo hídrico, relevo topográfico e integração contínua entre sensores. Todo o sistema foi desenhado para **apoiar a tomada de decisão humana**, sem automatizar decisões de alto impacto (como interdições de vias ou evacuações).

### Principais Funcionalidades
- **Dashboard Territorial:** Indicadores de chuva acumulada (24h), saturação do solo, declividade, impermeabilização, decisões pendentes e seletor interativo de microbacias/encostas.
- **Gráfico Pluviométrico Dinâmico:** Gráfico vetorial customizado (`CustomPainter`) alterável por **data** (navegação por dia ou calendário) e **período** (`24h`, `3 dias` e `7 dias`).
- **Alertas Preditivos Transparentes:** Cada alerta apresenta **justificativa técnica**, **nível de confiança (%)** e **limitações explícitas do modelo**.
- **Apoio à Decisão Humana:** Fluxo para o gestor escolher ou registrar uma ação preventiva com observação técnica e trilha de auditoria persistida localmente.
- **Formulário de Ocorrências com Validação e LGPD:** Registro de ocorrências de campo com validação de campos e bloqueio automático de padrões de CPF/telefone para preservar a privacidade dos cidadãos.
- **Acessibilidade e Privacidade:** Modo **Alto Contraste**, ajuste de **escala de fonte**, `Semantics` para leitores de tela e agregação populacional anonimizada por macro-setor.

---

## Fontes de Dados
- **Open-Meteo Forecast API (`https://api.open-meteo.com/v1/forecast`):** API pública (sem necessidade de chave) consumida em tempo real para precipitação horária/diária, probabilidade de chuva e umidade superficial do solo (`soil_moisture_0_to_1cm`) por latitude e longitude de cada microbacia.
- **Base Territorial Sintética Calibrada:** Parâmetros locais de declividade média, taxa de impermeabilização do solo e população estimada agregada por setor (microbacias Tamanduateí Sul, Encosta Serra da Cantareira, Várzea do Rio Aricanduva e Núcleo Rural Marsilac).
- **Fallback Offline:** Caso a API externa esteja indisponível, o aplicativo gera uma série sintética determinística e informa explicitamente na interface que os dados exibidos estão em modo offline.

---

## Limitações
- **Granularidade espacial:** As leituras meteorológicas e de umidade do solo representam grades regionais; microclimas e acumulados pontuais em ruas específicas podem variar.
- **Infraestrutura não sensorizada:** O modelo não identifica automaticamente obstruções pontuais em bocas de lobo, galerias pluviais assoreadas ou trincas estruturais internas em imóveis privados.
- **Apoio à decisão (não automatizado):** O GeoFluxo não realiza acionamentos automáticos de defesa civil, interdições ou evacuações. Toda ação de alto impacto exige análise, vistoria presencial e validação do gestor público responsável.
- **Persistência local:** Ocorrências registradas e o histórico de decisões são armazenados localmente no dispositivo via `shared_preferences` (sem sincronização com servidor central nesta versão).

---

## Tecnologias e Requisitos Técnicos
- **Framework:** Flutter (Dart)
- **Gerenciamento de Estado:** `ChangeNotifier` + `ListenableBuilder` (`lib/state/territorial_state.dart`)
- **Consumo de API:** `http` (`lib/services/weather_api_service.dart`)
- **Persistência Local:** `shared_preferences` (`lib/services/storage_service.dart`)
- **Navegação:** `NavigationBar` + `IndexedStack` e modal sheets de decisão

---

## Como Executar
```bash
flutter pub get
flutter run -d chrome
```

Para executar análise estática e testes automatizados:
```bash
flutter analyze
flutter test
```
