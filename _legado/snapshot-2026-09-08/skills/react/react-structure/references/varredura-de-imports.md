# Varredura de imports — na ordem que falha mais

> Ordem de [[Feature-Based Architecture]] § 6 e § 4. Pare de detalhar um arquivo quando um
> achado invalidar o seguinte: se a **camada** está errada, não revise o import dela —
> reporte a mudança de camada.

Script: `scripts/sondas-imports.sh [alvo]`, que roda as oito sondas na mesma ordem.

```bash
bash ~/.claude/skills/react-structure/scripts/sondas-imports.sh src
```

---

## Sonda 0 — enforcement (roda primeiro)

`biome.json`, `noRestrictedImports`, `noImportCycles`, e os aliases nos **três** arquivos.

| Achado da sonda 0 | Consequência |
| --- | --- |
| sem `biome.json`, ou sem as regras de § 7 | as fronteiras são convenção: **primeiro achado do relatório**, porque sem isso ele se repete no próximo PR |
| alias divergindo entre `tsconfig`, `vite.config`, `vitest.config` | "funciona no build, quebra no teste" — § 2 e § 7 |
| camada endereçada pelo barrel sem entrada **sem curinga** no `paths` | o import nu não resolve |

---

## A ordem, e o que cada passo pega

| # | O que | ID | Sonda |
| --- | --- | --- | --- |
| 1 | **Direção invertida** — genérico importando `@features/`/`@routes/`; feature importando `@routes/` | `REACT-ARCH-06`, `REACT-ARCH-07` | 1 |
| 2 | **Deep import** — `@features/x/...` com três segmentos ou mais | `REACT-ARCH-05` | 2 |
| 3 | **Alias próprio dentro da feature** | `REACT-ARCH-04` | 3 |
| 4 | **Barrel** — superfície pública grande demais, ou lógica no `index.ts` | `REACT-ARCH-02`, `REACT-ARCH-03` | 4 |
| 5 | **Rota inchada** — teste de bancada de § 4, não impressão | `REACT-ARCH-09` | 5 |
| 6 | **Colocação** — papel técnico onde deveria haver domínio; extração prematura | `REACT-ARCH-01`, `REACT-ARCH-08` | — |
| 7 | **Convenção** — `export type` no barrel, kebab-case | `REACT-ARCH-11`, `REACT-ARCH-12` | 6, 7 |

**Não reporte o mesmo arquivo duas vezes com IDs diferentes.** Domínio dentro de `libs/`
já saiu no passo 1 como `REACT-ARCH-06`; ele não volta no passo 6 como `REACT-ARCH-01`.

`REACT-ARCH-04` tem **cobertura parcial de lint** (§ 4): `noImportCycles` só pega quando o
import fecha ciclo. O resto depende desta varredura.

---

## O que a sonda não pega

| Não detectável por regex | ID | Como achar |
| --- | --- | --- |
| feature que nasceu de uma **tela**, não de uma capacidade | `REACT-ARCH-01` | ler o nome da pasta e perguntar: é vocabulário de produto? |
| extração para o compartilhado com menos de três consumidores | `REACT-ARCH-08` | contar os importadores do módulo em `features/core/` |
| barrel exportando mais do que alguém consome | `REACT-ARCH-02` | cruzar o `index.ts` com quem importa dele |
| rota que carrega jornada em vez de compor | `REACT-ARCH-09` | teste de bancada de § 4 |

---

## Formato do achado

Mesmo formato das skills irmãs, com o ID desta família:

```
`ID-DA-REGRA` — arquivo:linha
<o que está errado, uma frase>
Correção: <mudança concreta>
Ver [[Feature-Based Architecture]] § <seção>.
```

Severidade sai de `mapa-de-ids.md` (coluna **Severidade**, normativa em § 4) — **não
reclassifique**. Direção de dependência ganha de estética, sempre (§ 10, invariante 2).

**O corte:** preferência de organização sem ID não é achado. Existe ID em § 4 → achado.
É antipadrão de § 6 sem ID → cite a **seção**. Nem uma coisa nem outra → "Sugestões (sem
regra)", separado. Nunca invente um `REACT-ARCH-*`.

---

## Relacionados

- [[Feature-Based Architecture]] § 4, § 6, § 7 — a fonte
- `arvore-de-colocacao.md` — decidir onde colocar, antes de auditar o que está colocado
- `mapa-de-ids.md` — severidade e enforcement por ID
