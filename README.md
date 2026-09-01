# Afinador Instrumental

Afinador de instrumentos musicais em Flutter. Detecta a nota tocada em
tempo real através do microfone e mostra o desvio em cents num ponteiro,
com presets de afinação para violão, baixo, ukulele, violino, cavaquinho
e um modo cromático (qualquer nota).

## Funcionalidades

- Detecção de pitch em tempo real (algoritmo YIN) a partir do microfone.
- Presets: Violão/Guitarra, Baixo, Ukulele, Violino, Cavaquinho e Cromático.
- Ponteiro visual com desvio em cents e indicação de "Afinado!".
- Destaque automático da corda mais próxima da nota detectada.

## Arquitetura

O projeto segue **MVVM** + **Clean Architecture**, com as camadas
`domain`, `data` e `presentation` isoladas por interfaces (SOLID):

```
lib/
  domain/         Entidades, contratos de repositório e casos de uso
                  (não depende de Flutter nem de nenhum plugin)
  data/           Implementações concretas (ex.: captura de áudio via
                  o pacote `record`)
  presentation/   ViewModel (ChangeNotifier), View e widgets
  core/di/        Composition root (injeção de dependências com get_it)
```

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.44 ou
  superior (canal stable), com o Dart incluso.
- Um dispositivo/emulador Android, um Mac com Xcode para iOS, ou Linux
  desktop (com ALSA/PulseAudio) para testar localmente.
- Um microfone disponível no dispositivo/computador usado para testar.

Verifique se o ambiente está pronto com:

```bash
flutter doctor
```

## Instalação

```bash
git clone git@github.com:Alfser/afinador-instrumental.git
cd afinador-instrumental
flutter pub get
```

## Executando o app

Liste os dispositivos disponíveis:

```bash
flutter devices
```

E rode em um deles:

```bash
flutter run -d <device-id>
```

Exemplos:

```bash
flutter run -d linux     # Linux desktop
flutter run -d macos     # macOS desktop
flutter run              # deixa escolher entre os conectados (Android/iOS)
```

Ao abrir o app, escolha o instrumento desejado e toque em **Iniciar**
para conceder a permissão de microfone e começar a afinação.

### Permissões de microfone

- **Android**: `RECORD_AUDIO` já está declarada em
  `android/app/src/main/AndroidManifest.xml`.
- **iOS**: a descrição de uso já está em `ios/Runner/Info.plist`
  (`NSMicrophoneUsageDescription`).
- **Linux/macOS**: a permissão é concedida pelo próprio sistema
  operacional na primeira execução.

Se a permissão for negada, o app exibe uma mensagem de erro na tela —
basta permitir o acesso ao microfone nas configurações do
sistema/dispositivo e tentar novamente.

## Testes e qualidade

```bash
flutter analyze   # análise estática
flutter test      # testes automatizados
```

## Build de produção

```bash
flutter build apk        # Android
flutter build ios        # iOS (requer macOS + Xcode)
flutter build linux      # Linux desktop
```
