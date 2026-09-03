# Plano: Metrônomo e Pad de Acompanhamento

> Status: **backlog / não iniciado**. Registrado para planejar com calma;
> o Afinador ainda pode receber ajustes antes de começar isto. Nenhum
> código deste documento foi implementado ainda.

## Contexto e decisão

O app hoje é só o Afinador (`afinador_flutter` / "Afinador Instrumental").
A ideia é evoluir para um "kit do músico" com três ferramentas dentro do
**mesmo app** — Afinador, Metrônomo e Pad — em vez de publicar apps
separados na Play Store.

**Por quê um app só:** é o padrão do gênero (o próprio SoundCorset, usado
como referência de design do afinador, é afinador+metrônomo+pad num único
app), converte melhor em loja do que vários apps pequenos disputando a
mesma audiência, e a arquitetura atual (Clean Architecture + MVVM +
injeção de dependência via `get_it`) já foi pensada para crescer por
módulos sem mexer no que já existe.

## Objetivo

Adicionar Metrônomo e Pad como novas ferramentas do app, reaproveitando a
infraestrutura de áudio, tema e injeção de dependência já existentes,
sem alterar o comportamento do Afinador.

## Feature 1 — Metrônomo

**Controles**
- Andamento (BPM) ajustável, faixa típica ~30–300 bpm.
- Compasso: numerador (2, 3, 4, 5, 6, 7…) e a batida acentuada (a "1")
  soando diferente das demais.
- Seletor de som, com **dois timbres**:
  1. **Mecânico/artesanal** — tique de metrônomo de madeira/pêndulo
     clássico (ataque seco, tom mais quente).
  2. **Eletrônico** — clique/beep sintético, no estilo do click usado por
     bateristas (mais curto e agudo).
- Indicador visual do tempo (ex.: pêndulo animado ou luz piscando no
  tempo), sincronizado ao som.
- Lembrar o último BPM/compasso/som escolhido entre sessões.

**Ponto técnico crítico:** precisão de tempo. Um `Timer.periodic` simples
acumula drift (atraso que cresce com o tempo) e não é confiável para
manter um andamento estável por minutos. É necessário um agendador que
calcule o horário absoluto de cada batida com antecedência (com base em
`Stopwatch`/clock do áudio) em vez de apenas "esperar X ms e repetir".

**Mapeamento para a arquitetura atual**
- `domain/entities`: `MetronomeSettings` (bpm, batidasPorCompasso,
  timbre), `MetronomeTick` (índice da batida, se é acentuada).
- `domain/services`: `MetronomeScheduler` — agenda os ticks com
  precisão e expõe um `Stream<MetronomeTick>`.
- Som: decidir entre estender `ToneSynthesizer` (síntese, como já é
  feito para as cordas do afinador) ou usar assets de áudio curtos para
  os dois timbres — provavelmente síntese resolve bem aqui, já que são
  sons percussivos simples.
- `presentation`: `MetronomeViewModel` + `MetronomeView` (BPM,
  compasso, seletor de timbre, indicador visual).

**Em aberto (perguntar antes de implementar):**
- Precisa de "tap tempo" (bater o andamento tocando na tela)?
- Precisa de vibração (haptic feedback) no tempo, além do som?

## Feature 2 — Pad

**Ideia**: o usuário escolhe um **estilo sonoro** (ex.: "Pad Worship",
"Pad Piano") e depois toca as notas — cada nota soa naquele estilo
selecionado, sustentada.

**Mapeamento para a arquitetura atual**
- `domain/entities`: `PadStyle` (id, nome — worship, piano, …).
- `domain/repositories`: `PadSoundRepository` — fornece o som de cada
  nota para o estilo selecionado.
- `presentation`: `PadViewModel` + `PadView` (seletor de estilo + roda
  ou teclado cromático de notas).

**Ponto técnico em aberto — síntese vs. sample:** a síntese aditiva
usada no `ToneSynthesizer` (fundamental + harmônicos) foi desenhada para
imitar o dedilhado de uma corda, e provavelmente não é rica o bastante
para um pad de worship ou piano convincente. O caminho mais realista é
usar **samples de áudio gravados** por nota/estilo (com loop de sustain),
o que muda a arquitetura de `data/` (precisa de um datasource que carregue
assets de áudio em vez de gerar samples matematicamente) e aumenta o
tamanho do app. Isso precisa ser decidido antes de desenhar a
implementação.

**Em aberto (perguntar antes de implementar):**
- O pad é **monofônico** (uma nota de cada vez, tipo bordão) ou permite
  tocar **várias notas ao mesmo tempo** (acorde)?
- De onde vêm os samples de áudio — gravação própria, biblioteca livre de
  royalties, banco pago? Isso tem implicação de licenciamento se o app for
  publicado.
- Quantos estilos além de Worship e Piano entram na primeira versão?

## Navegação

Hoje o app é uma tela única (`Scaffold` do Afinador). Para as três
ferramentas convivendo no mesmo app, trocar por uma navegação em abas
(`BottomNavigationBar` ou `TabBar`) — Afinador / Metrônomo / Pad —
reaproveitando `AppTheme`/`AppColors` como estão.

O `injection_container.dart` (composition root) ganha os registros novos
de Metrônomo e Pad sem alterar os registros existentes do Afinador.

## Fora de escopo (por ora)

- Mixar várias camadas de pad ao mesmo tempo.
- Compassos irregulares (ex. 7/8) na primeira versão do metrônomo.
- Upload de sons customizados pelo usuário.

## Fases sugeridas

1. **Metrônomo** primeiro — escopo menor, reaproveita mais do que já
   existe (síntese de áudio, `Timer`/isolate já usados no afinador).
2. **Pad** — depende da decisão síntese-vs-sample, escopo maior por causa
   dos assets de áudio.
3. Unificar a navegação em abas e revisar a consistência visual entre as
   três ferramentas.

## Antes de começar a implementação

Resolver as perguntas em aberto de cada seção acima (tap tempo/haptic no
metrônomo; polifonia e origem dos samples no pad) e confirmar que o
Afinador está no estado desejado, já que o usuário sinalizou que pode
querer ajustar mais alguma coisa nele antes de partir para isso.
