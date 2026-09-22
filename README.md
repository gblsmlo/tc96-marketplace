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
`RHF-*`, `SB-*`, `HTTP-*`, `BUN-*`, `ELYSIA-*`, `DRZ-*`, `PW-*`, `TS-*`). Cópia de regra dentro de skill vira réplica
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

Quando a nota existe aqui **e** a biblioteca está no Context7, o ID de regra vem da nota e
só a assinatura vem do Context7 — é assim com Hono, que tem `HONO-*` na knowledge-base.

### O workspace resolve como projeto

**Nada aqui aponta para arquivo fora daqui.** Não há caminho absoluto nem
referência a pasta de vault: todo link é markdown relativo e resolve dentro do
repositório. `bash build/verificar.sh` falha quando um aparece.

Até 2026-09-22 a `knowledge-base/` era projeção de um vault Obsidian. Deixou de ser: as
**129 notas** são conteúdo deste projeto, cada uma com o próprio `titulo:` no frontmatter
— que é o rótulo com que as skills linkam para ela. O índice sai de
[`build/indexar.sh`](build/indexar.sh), que lê as notas daqui e de mais nada.
O registro da extração única está em [`_legado/vault/`](_legado/vault/).

> **Zettels não entram.** Decisão de 2026-09-22: a camada de raciocínio não é extraída, e
> as citações a ela saem do texto. A cadeia é papel → procedimento → regra. Pelo mesmo
> corte, os mapas de fundamentos de curso ficaram de fora — os agentes de produto e gestão
> os citam **por nome, em code span**, e declaram que não têm regra com ID para citar.

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
bash build/indexar.sh                  # regenera knowledge-base/MANIFESTO.md
bash build/indexar.sh --verificar      # não escreve; falha se o índice estiver velho
bash build/context7.sh --verificar     # confere os library IDs contra o catálogo
bash build/verificar.sh                # link quebrado, sintaxe de vault, frontmatter
bash build/claude-code.sh              # -> dist/claude-code/plugins/<plugin>/
bash build/agents-md.sh                # -> dist/agents-md/
```

Os adaptadores processam **só** o que tem `tipo:` neutro no frontmatter. Família ainda no
formato antigo é ignorada em silêncio — é o que permite migrar uma por vez sem quebrar o
build.

### Instalar o alvo Claude Code

`dist/claude-code/` é um marketplace: `.claude-plugin/marketplace.json` na raiz e um
plugin por recorte habilitável em `plugins/` (core, frontend, backend, e2e). Aponte o
marketplace `twincam` para esse diretório, ou copie `skills/` e `agents/` de um plugin
para `~/.claude/`.

O marketplace `twincam` já aponta para cá desde 2026-09-22:

```bash
claude plugin marketplace list          # twincam -> Directory (…/Workspaces/dist/claude-code)
claude plugin install twincam-core@twincam
```

> `dist/` é ignorado pelo git e todo build o apaga antes de reescrever. O marketplace
> referencia o diretório, então **rode um adaptador antes de instalar ou atualizar
> plugin** — marketplace apontando para dist vazio falha com `cache-miss`.

## Estado

| | Quantos | Idioma |
| --- | --- | --- |
| **skills** | 28, em 9 famílias | inglês |
| **scripts de skill** | 40 | inglês |
| **agents** | 12 | `frontend-developer` em inglês; os outros onze em português |
| **knowledge-base** | 129 notas (`docs/` 118 · `pages/` 11) | português — é a regra, e o ID vem dela |

Os `mapa-de-ids.md` são **gerados** por `skills/<familia>/<skill>/scripts/gerar-mapa-de-ids.sh`
a partir da knowledge-base; não edite à mão. Rodar o gerador reproduz byte a byte o que
está versionado, tirando a data.

`_legado/` guarda o que saiu do caminho vivo: `snapshot-2026-09-08/` é a versão do
frontend anterior ao Hermes, e `vault/` é a proveniência da extração. Nada em `_legado/`
roda.
