# Workspaces — fonte neutra de agentes, skills e regra

Este repositório é a **fonte**, não a instalação. Nada aqui é específico de um runtime de
agente: o Claude Code é um alvo de build como qualquer outro, e sair dele não custa
reescrever conteúdo — custa escrever um adaptador.

## As três camadas

| Camada | Onde | Responde | Dono da divergência |
| --- | --- | --- | --- |
| **papel** | [`agents/`](agents/) | *quem* faz, com que contexto, e o que entrega | — |
| **procedimento** | [`skills/`](skills/README.md) | *como* fazer, em que ordem, e como reportar | divergiu do agente → bug do agente |
| **regra** | [`knowledge-base/`](knowledge-base/MANIFESTO.md) | *o que* é certo, por ID | divergiu da skill → bug da skill |

Nenhuma camada copia o texto da camada abaixo. Ela **cita por ID** (`REACT-*`, `TSQ-*`,
`RHF-*`, `SB-*`, `REACT-ARCH-*`). Cópia de regra dentro de skill vira réplica
desatualizada no dia seguinte.

`knowledge-base/` é projetado do vault Obsidian em `~/Sync/Vaults/Notes`, **num sentido
só**. Editar a regra continua sendo editar a nota lá. O que entra está declarado em
[`knowledge-base/dominio.txt`](knowledge-base/dominio.txt), e a integridade de cada cópia
(sha256 da origem) no `MANIFESTO.md`.

> **Zettels não entram.** Decisão de 2026-09-22: a camada de raciocínio do vault não é
> projetada, e as citações a ela são removidas do texto na projeção. A cadeia é papel →
> procedimento → regra.

## O que torna a fonte neutra

O frontmatter não usa nome de ferramenta de nenhum runtime. Declara **capacidade**, e o
adaptador traduz:

| Fonte neutra | Claude Code | AGENTS.md |
| --- | --- | --- |
| `nome:` | `name:` | H1 do arquivo |
| `descricao:` | `description:` | blockquote **Quando usar** |
| `capacidades: [ler, buscar, executar]` | `tools: Read, Grep, Glob, Bash` | — |
| `modelo: alto \| medio \| rapido` | `model: opus \| sonnet \| haiku` | — |
| `tipo: skill \| agente` | (some — é o layout que separa) | (some) |
| `familia:` | (some — layout achatado) | subdiretório |

Links são markdown relativo, nunca wikilink: a fonte é navegável fora do Obsidian, e cada
adaptador reescreve a profundidade que o layout do alvo exige.

## Build

```bash
bash build/sincronizar.sh              # vault -> knowledge-base (regenera o MANIFESTO)
bash build/sincronizar.sh --verificar  # não escreve; falha se a origem mudou
bash build/claude-code.sh              # -> dist/claude-code/hermes-frontend/
bash build/agents-md.sh                # -> dist/agents-md/
```

Os adaptadores processam **só** o que tem `tipo:` neutro no frontmatter. Família ainda no
formato antigo é ignorada em silêncio — é o que permite migrar uma por vez sem quebrar o
build.

### Instalar o alvo Claude Code

`dist/claude-code/hermes-frontend/` é um plugin completo. Aponte o marketplace `hermes`
para o diretório que contém o plugin, ou copie `skills/` e `agents/` para `~/.claude/`.

> O marketplace `hermes` registrado hoje em `~/.claude/plugins/known_marketplaces.json`
> aponta para `~/www/Workspaces/hermes`, **que não existe mais**. Os plugins instalados
> continuam funcionando pelo cache em `~/.claude/plugins/cache/hermes/`, mas não recebem
> atualização até o caminho ser corrigido.

## Estado da migração

| | Migrado | Pendente |
| --- | --- | --- |
| **skills** | react (4) · tanstack (2) · storybook (3) | test (3) · playwright (3) · http (4) · bun (5) · elysia (3) · drizzle (1) |
| **agents** | `frontend-developer` | os outros 10 |

O conteúdo migrado veio de `hermes-frontend/0.1.5` (build de 17/09) para a estrutura, e as
47 notas de regra vieram **frescas do vault**, não do build. `_legado/snapshot-2026-09-08/`
guarda a versão anterior do frontend, de antes da migração para o Hermes.

### Migrar a próxima família

1. Acrescente o domínio dela em `knowledge-base/dominio.txt`.
2. `bash build/sincronizar.sh`.
3. Importe as skills com `build/importar-do-plugin.py` (ajuste `FAMILIA` e `AGENTES`).
4. Verifique: `bash build/verificar.sh`.
