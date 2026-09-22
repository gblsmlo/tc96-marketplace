# Sondas — rodar antes de ler código

> Uma revisão que começa pela leitura linear encontra o que estava na tela e perde o que
> estava em outro arquivo. As sondas medem o repositório inteiro em segundos e dizem
> **onde olhar**. Elas não produzem achado: achado exige leitura do trecho e `arquivo:linha`.

Script pronto: `scripts/sondas.sh [alvo]` — roda as quinze e imprime o ID a citar em cada bloco.

```bash
bash ~/.claude/skills/react-review/scripts/sondas.sh src
```

Alvo padrão: `src`, ou `.` quando não existir. Na fonte do vault o caminho é
`Skills/react/react-review/scripts/sondas.sh`.

---

## Sonda 0 — ambiente (roda primeiro, muda o veredito das outras)

```bash
rg -n '"react":|"react-dom":' package.json
rg -n 'babel-plugin-react-compiler|reactCompiler|react-compiler' package.json vite.config.* babel.config.* next.config.*
# a rede de lint: ESLint com o plugin, ou Biome com o domínio react ligado
rg -n 'react-hooks' package.json eslint.config.* .eslintrc*
rg -n 'domains|useHookAtTopLevel|useExhaustiveDependencies' biome.json*
rg -l 'StrictMode' src
```

Três consequências diretas:

| Achado da sonda 0 | Consequência na revisão |
| --- | --- |
| React Compiler **ativo** | memoização manual é redundante — `REACT-PERF-02` vira achado por si só |
| **rede de lint ausente** | metade de `REACT-HOOK-*` não tem rede: é o **primeiro achado do relatório** |
| `<StrictMode>` **ausente** | quebras de pureza não aparecem em dev — `REACT-DOM-06` ao contrário |

Sem a sonda 0, uma revisão pode reportar "falta `useMemo` aqui" num projeto que compila
memoização automaticamente. É achado inválido, e desmoraliza o resto do relatório.

---

## As duas formas de rede, e a que falha em silêncio

A sonda 0 aceita **duas** implementações da mesma proteção — e a segunda tem uma pegadinha:

| Ferramenta | O que basta | O que engana |
| --- | --- | --- |
| **ESLint** | `eslint-plugin-react-hooks` nas dependências ou na config | — |
| **Biome** | `linter.domains.react` em `"recommended"`/`"all"`, **ou** `useHookAtTopLevel` e `useExhaustiveDependencies` declaradas | `recommended` ligado **não basta**: as regras de Hooks são recommended **do domínio react**, e sem o domínio elas não rodam |

O caso do Biome **não dá erro nem aviso**: `biome lint` passa, as demais regras recommended
disparam normalmente, e as de Hooks ficam mudas. A sonda imprime a correção junto:

```jsonc
"linter": { "domains": { "react": "recommended" } }
```

Como confirmar sem confiar na leitura do config — vale trinta segundos:

```bash
printf 'import {useState} from "react"\nexport function C({a}:{a:boolean}){\n if(a) return null\n const [x]=useState(0)\n return <div>{x}</div>\n}\n' > src/__probe.tsx
npx biome lint src/__probe.tsx     # useHookAtTopLevel tem de aparecer
rm src/__probe.tsx
```

---

## As catorze sondas de código

| # | O que encontra | Regra a citar | Falso positivo típico |
| --- | --- | --- | --- |
| 1 | `fetch`/`axios` dentro de `useEffect` | `REACT-EFFECT-06`, `REACT-ASYNC-03` | código legado explicitamente marcado; confirme se é novo |
| 2 | `useEffect` cujo corpo começa em `set*` | `REACT-PAT-01` | Effect que sincroniza com sistema externo e por acaso começa em `set` |
| 3 | `eslint-disable` em `exhaustive-deps` | `REACT-EFFECT-03` | — praticamente não há |
| 4 | `useEffect(async …)` | `REACT-EFFECT-12` | — |
| 5 | `setX(x + 1)` sem forma updater | `REACT-STATE-01` | valor que não depende do anterior (`setPagina(1)` não casa) |
| 6 | inventário de `useMemo`/`useCallback`/`memo` | `REACT-PERF-01` | nenhum: **toda** ocorrência precisa de medida ou de compiler |
| 7 | `key={i}` | [[React - Patterns]] § 8 | lista estática, nunca reordenada, sem estado nas linhas |
| 8 | `forwardRef` | `REACT-REF-03` | biblioteca de terceiros reexportada |
| 9 | `<Suspense>` sem Error Boundary no mesmo arquivo | `REACT-ASYNC-08` | boundary declarado no arquivo pai — confirme subindo um nível |
| 10 | `.push/.sort/.splice/.reverse` | `REACT-PURE-03`, `REACT-PURE-05` | array local criado no próprio escopo (`[...x].sort()` é correto) |
| 11 | arquivos com `'use client'` | `REACT-RSC-03` | nenhum por si só — o achado é a **altura** na árvore |
| 12 | `'use server'` sem `parse`/`safeParse` aparente | `REACT-RSC-06` | validação importada de outro módulo; confirme lendo |
| 13 | `createRoot` × `hydrateRoot` | `REACT-DOM-01` | app sem SSR: `createRoot` é o correto |
| 14 | `typeof window` | `REACT-DOM-03` | uso fora do render (Effect, handler, módulo) |

**Sondas 9, 11, 12 e 13 são de contexto, não de padrão**: elas listam candidatos cuja
correção depende de olhar o arquivo pai, a topologia da árvore ou a configuração de SSR.
Reportar direto da saída delas gera falso positivo.

---

## O que as sondas **não** pegam

Regex não vê escopo. Estes exigem leitura, e são justamente os de severidade mais alta:

| Não detectável por sonda | Regra | Como achar |
| --- | --- | --- |
| Hook depois de early return, dentro de `if`/loop/callback | `REACT-HOOK-01` | lint, ou leitura do topo de cada componente |
| Componente chamado como função | `REACT-CALL-01` | leitura; procure `Componente(` com maiúscula |
| Hook passado como valor | `REACT-CALL-02` | leitura |
| Estado que deveria estar na URL | `REACT-PAT-10` | ler os `useState` e perguntar: sobrevive a refresh? |
| Estado elevado alto demais | `REACT-PAT-02` | ler quem consome cada estado |
| Dado remoto em `useState` | `REACT-PAT-03` | cruzar sonda 1 com os `useState` do mesmo arquivo |
| Erro esperado lançado para boundary | `REACT-ASYNC-09` | ler os `throw` em action e handler |
| Prop booleana por variação de conteúdo | `REACT-PAT-04` | ler a assinatura dos componentes maiores |

A ordem prática: sondas primeiro para saber **quais arquivos** ler; depois a
`grade-de-varredura.md` sobre esses arquivos, na ordem que falha mais.

---

## Relacionados

- `grade-de-varredura.md` — a ordem de leitura depois das sondas
- `severidade-e-relatorio.md` — como classificar e escrever o que foi encontrado
- `mapa-de-ids.md` — onde cada ID está declarado
