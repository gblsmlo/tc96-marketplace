---
nome: react-hook-form
descricao: Trabalhar com formulários no React Hook Form — triar se RHF é a ferramenta, conectar campos, validar com Zod, campos condicionais e listas dinâmicas, submeter, e diagnosticar re-render e campo que não envia, citando IDs `RHF-*`, com doze sondas executáveis — use quando a tarefa for montar formulário novo, integrar componente de UI controlado por Controller, mapear erro de servidor para o campo, usar useFieldArray, decidir quem é dono do estado de submissão, ou revisar um formulário existente. Não use para um campo isolado sem validação, que são as Actions nativas via react-developer, para estado de servidor, que é tanstack-query, nem para estado que pertence à URL, que é tanstack-router.
tipo: skill
familia: react
fonte: "[React Hook Form](../../../knowledge-base/docs/react-hook-form.md)"
tags:
  - skill
  - react
  - react-hook-form
---

# react-hook-form

> **Fonte desta skill:** [React Hook Form](../../../knowledge-base/docs/react-hook-form.md) e seus três satélites em `Docs/`.
> Roteador de **tarefa → nota**, não resumo de API. Não contém o texto das regras `RHF-*`, assinaturas, opções, nem o comportamento do Proxy de `formState`: isso vive nos satélites, e é lá que se lê e se atualiza. Procedimento técnico escrito aqui vira cópia que desatualiza sozinha.

Contrato que esta skill implementa: [React Hook Form](../../../knowledge-base/docs/react-hook-form.md) § 7. As invariantes de lá valem em toda tarefa, sem repetição por seção.

---

## Passo 0 — Triagem: isto precisa mesmo de React Hook Form?

**Antes de instalar, importar ou escrever qualquer coisa.** Invariante 1 do contrato.

```
O formulário precisa de ao menos UM destes?
 · validação por campo enquanto o usuário digita
 · erro por campo (de cliente ou de servidor)
 · array dinâmico de campos — adicionar/remover linhas
 · várias etapas (wizard)
 · dependência entre campos — um decide o que o outro aceita
├── NÃO → Actions nativas do React 19: useActionState + <form action>.
│ Menos dependência, menos código, e é o caso mais comum.
│ → React - Formulários e Actions · skill react-developer. PARE AQUI.
└── SIM → RHF é dono da CAPTURA. Siga.
```

Três notas convergem nesse corte — [React Hook Form](../../../knowledge-base/docs/react-hook-form.md) § 5.4, [React - Formulários e Actions](../../../knowledge-base/docs/react-formularios-e-actions.md) § 6 e [React - Patterns](../../../knowledge-base/docs/react-patterns.md) § 4 —, então não é preferência de estilo. **Registre a decisão em uma frase:** se você não consegue nomear qual dos cinco gatilhos se aplica, RHF é dependência sem contrapartida.

---

## Carregamento mínimo

Conforme [React Hook Form](../../../knowledge-base/docs/react-hook-form.md) § 7:

```
SEMPRE: React Hook Form § 2 (modelo mental), § 5 (árvores), § 6 + § 6.1 (regras)
ANTES: § 5.4 — o Passo 0 acima

SOB DEMANDA, UM satélite por vez:
 conectar campo............... React Hook Form - Registro e Controle
 validar / erro de servidor... React Hook Form - Validação e Resolvers
 ler estado, listas, re-render React Hook Form - Estado e Performance

BASE: React.js § 6 — `REACT-PURE-*` e `REACT-HOOK-*` valem dentro do form
NUNCA: os três satélites de uma vez
```

Referências desta skill — abra só a que a tarefa pedir:

| Arquivo | Para quê |
| --- | --- |
| `references/tarefas.md` | as cinco tarefas, com a ordem das decisões e o que verificar em cada |
| `references/dono-da-submissao.md` | `isSubmitting` × `isPending` — escolher um e declarar qual |
| `references/diagnostico.md` | sintoma → causa provável → satélite, e o que **não** é desta skill |
| `references/mapa-de-ids.md` | onde cada `RHF-*` está declarado, e a regra de citação entre docs |
| `references/exemplo-lancamento-de-fatura.md` | caso trabalhado, do Passo 0 ao submit |
| `scripts/sondas.sh` | doze sondas executáveis para revisar formulário existente |
| `scripts/gerar-mapa-de-ids.sh` | regenera `mapa-de-ids.md` a partir de `Docs/React Hook Form*` |

Abaixo, os satélites aparecem pelo nome curto: **Registro**, **Validação**, **Estado**; **hub** é [React Hook Form](../../../knowledge-base/docs/react-hook-form.md).

---

## Roteamento por tarefa

| Tarefa | Onde | Regra que mais falha |
| --- | --- | --- |
| Montar formulário novo | `references/tarefas.md` § 1 | `RHF-VAL-04` — schema primeiro, tipo derivado |
| Integrar componente de UI controlado | § 2 | `RHF-CORE-03` / `RHF-CTRL-01` |
| Validar com Zod, mapear erro de servidor | § 3 | `RHF-VAL-01`, `RHF-ERR-02` |
| Campo condicional, lista dinâmica, wizard | § 4 | `RHF-PERF-01`, `RHF-ARRAY-01`, `REACT-PAT-10` |
| Submeter (mutation ou Server Function) | § 5 | `RHF-BRIDGE-01` — um dono só |
| Decidir quem desabilita o botão | `references/dono-da-submissao.md` | — |
| Diagnosticar re-render ou campo que não envia | `references/diagnostico.md` | `REACT-PERF-01` — mediu? |

A ordem das decisões **não** é a ordem de escrever o JSX: schema → `defaultValues` → `mode` → campo a campo → dono do submit. Escrever o JSX primeiro é o que produz `useState` por campo.

---

## Revisar um formulário que já existe

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-hook-form/scripts/sondas.sh src
```

Doze sondas, na ordem que falha mais: `watch` na raiz, `watch(callback)` deprecado, `useForm` sem `defaultValues`, `formState` vindo de `useFormContext`, dois donos da submissão, `reset` dentro do `onSubmit`, `key` de índice em `useFieldArray`, registro duplo, `useState` espelhando campo, otimismo no formulário, dois estados de espera, e erro sem `aria-invalid`.

**Sondas 3 e 9 têm falso positivo alto** — `useForm` sem `defaultValues` pode estar recebendo `values`, e `useState` no arquivo pode não ter relação com o form. Confirme lendo antes de reportar.

Ao reportar, use o formato de `react-review`: ID canônico + `arquivo:linha` + correção concreta + link do satélite.

---

## O que é fronteira, e de quem é

| A pergunta é sobre | Skill |
| --- | --- |
| se este formulário deveria sequer usar RHF | Passo 0 — se a resposta for Actions nativas, `react-developer` |
| captura, conexão de campo, validação, erro no campo, submissão | **esta** |
| o que a escrita tornou velho: key, frescor, invalidação, otimismo | `tanstack-query` |
| onde a etapa do wizard vive, dado de rota no form, filtro na URL | `tanstack-router` |
| o componente em volta: pureza, Hooks, fronteiras | `react-review` · `react-developer` |
| onde o arquivo do form mora, quem importa quem | `react-structure` |
| story e teste de interação do formulário | `storybook-story` · `storybook-test` |
| **nível** do teste do formulário (unidade × integração × e2e) | `teste-design` |
| teste de unidade · e2e da jornada de submissão | `bun-test-build` · `playwright-build` |
| o endpoint que recebe o submit: schema, status, erro | `elysia-schema` · `http-contract` |

Três regras de fronteira que decidem citação:

- **Otimismo nunca é do formulário** → `RHF-BRIDGE-04`, que é **canônico**, não apelido de `REACT-FORM-07` (hub § 6.2): aquele trata de `useOptimistic` não ser fonte de verdade, e não substitui este.
- **Dado remoto no form:** `values` + `keepDirtyValues` é desta skill (`RHF-BRIDGE-03`); qual query fornece o dado, e com que frescor, é da `tanstack-query`.
- **Regra do React vence regra do RHF:** `REACT-PURE-*` e `REACT-HOOK-*` têm precedência (§ 7, invariante 4).

**Honestidade:** API que não aparece no hub § 4 não foi verificada — vale em especial para `setValues`, `resetDefaultValues` e `createFormControl` (§ 4.3, com ressalva) e para o `<Form>`, que é BETA. Declare a limitação, consulte [react-hook-form.com](https://react-hook-form.com/docs) e proponha atualizar a nota; não invente comportamento nem ID (§ 7, invariante 2).

---

## Exemplo

Formulário de lançamento de fatura: valor em moeda, vencimento, e justificativa que só aparece acima de R$ 10.000. O Passo 0 nomeia dois dos cinco gatilhos; a ordem das decisões elimina os `useState` por campo antes do primeiro JSX; a regra entre campos vai para `.superRefine`, não para `validate`; e o condicional lê o valor com `useWatch` no menor componente, não com `watch` na raiz.

Caso completo, com código e a tabela do que cada decisão evitou: `references/exemplo-lancamento-de-fatura.md`.

---

## Relacionados

- [React Hook Form](../../../knowledge-base/docs/react-hook-form.md) — hub, modelo mental, árvores de decisão, contrato de skill (fonte)
- [React Hook Form - Registro e Controle](../../../knowledge-base/docs/react-hook-form-registro-e-controle.md) · [React Hook Form - Validação e Resolvers](../../../knowledge-base/docs/react-hook-form-validacao-e-resolvers.md) · [React Hook Form - Estado e Performance](../../../knowledge-base/docs/react-hook-form-estado-e-performance.md) — satélites, um por vez
- [React - Formulários e Actions](../../../knowledge-base/docs/react-formularios-e-actions.md) — a alternativa nativa, que o Passo 0 pode indicar
- `react-developer` · `react-review` · `react-structure` · `tanstack-query` · `tanstack-router` — skills vizinhas
- Zettels: · · · ·
