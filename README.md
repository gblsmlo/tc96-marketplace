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

### Superfície de API não mora aqui

A regra e a superfície de API respondem perguntas diferentes, e por isso têm fontes
diferentes:

| A pergunta é… | A fonte é | Como |
| --- | --- | --- |
| como esta API funciona **nesta versão** | [Context7](https://context7.com/) | a skill declara o library ID em `docs:`; o runtime resolve |
| o que é **certo** aqui, e com que ID eu cito isso num review | `knowledge-base/` | link relativo, versionado, com sha256 de origem |

A fonte neutra só **declara** o library ID — não embute credencial nem nome de
ferramenta. Quem resolve é o runtime que tiver Context7 disponível. O registro está em
[`build/context7.json`](build/context7.json), com snippets e trust score de quando cada
ID foi verificado.

Skill que não declara nada **não tem biblioteca upstream**: teste é conceito e HTTP são
RFCs, não API de ninguém. Ausência ali é informação, não lacuna.

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
| `docs: [/websites/tanstack_query]` | `docs:` (o runtime resolve pelo Context7) | tabela **Superfície de API** |
| `familia:` | (some — layout achatado) | subdiretório |

Links são markdown relativo, nunca wikilink: a fonte é navegável fora do Obsidian, e cada
adaptador reescreve a profundidade que o layout do alvo exige.

## Build

```bash
bash build/sincronizar.sh              # vault -> knowledge-base (regenera o MANIFESTO)
bash build/sincronizar.sh --verificar  # não escreve; falha se a origem mudou
bash build/context7.sh --verificar     # confere os library IDs contra o catálogo
bash build/claude-code.sh              # -> dist/claude-code/plugins/<plugin>/
bash build/agents-md.sh                # -> dist/agents-md/
```

Os adaptadores processam **só** o que tem `tipo:` neutro no frontmatter. Família ainda no
formato antigo é ignorada em silêncio — é o que permite migrar uma por vez sem quebrar o
build.

### Instalar o alvo Claude Code

`dist/claude-code/` é um marketplace: `.claude-plugin/marketplace.json` na raiz e um
plugin por recorte habilitável em `plugins/` (core, frontend, backend, e2e). Aponte o
marketplace `hermes` para esse diretório, ou copie `skills/` e `agents/` de um plugin
para `~/.claude/`.

O marketplace `hermes` já aponta para cá desde 2026-09-22:

```bash
claude plugin marketplace list          # hermes -> Directory (…/Workspaces/dist/claude-code)
claude plugin install hermes-core@hermes
```

> `dist/` é ignorado pelo git e todo build o apaga antes de reescrever. O marketplace
> referencia o diretório, então **rode um adaptador antes de instalar ou atualizar
> plugin** — marketplace apontando para dist vazio falha com `cache-miss`.

`hermes-backend` não existe enquanto bun, elysia e drizzle não forem migradas: o
adaptador só emite plugin para recorte que tem alguma família migrada.

## Estado da migração

| | Migrado | Pendente |
| --- | --- | --- |
| **skills** | **as 28, em 9 famílias** | — |
| **agents** | `frontend-developer` | os outros 10 |

O conteúdo migrado veio de `hermes-frontend/0.1.5` (build de 17/09) para a estrutura, e as
47 notas de regra vieram **frescas do vault**, não do build. `_legado/snapshot-2026-09-08/`
guarda a versão anterior do frontend, de antes da migração para o Hermes.

### Migrar a próxima família

1. Acrescente o domínio dela em `knowledge-base/dominio.txt` e rode
   `bash build/sincronizar.sh`.
2. Declare a família em `FAMILIAS`, dentro de `build/importar-do-plugin.py`, e o library
   ID dela em `build/context7.json` (ou em `sem_biblioteca`, com o porquê).
3. Importe: `python3 build/importar-do-plugin.py <familia>`.
4. Verifique e builde: `bash build/verificar.sh && bash build/claude-code.sh`.

Todas as 9 famílias já estão migradas; o importador fica como registro de proveniência.
