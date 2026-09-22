# Exemplo trabalhado — clique que falha 1 em 4 no CI

`e2e/checkout.spec.ts:52` falha ~25% das execuções em CI. Passa local, sempre.

---

## Passo 0 — é defeito real do produto?

A falha é **intermitente** e o produto funciona manualmente. Segue.

## Passo 1 — o trace

`trace: 'on-first-retry'` está ligado — o artefato existe. (Se estivesse `'off'`, o
**primeiro achado** seria a configuração, e o diagnóstico só começaria na próxima execução.)

## Passo 2 — a leitura, em quatro passos

| Aba | O que mostrou |
| --- | --- |
| Errors | falhou o `click` em "Confirmar" |
| **Log** da ação | `element intercepts pointer events` |
| **Snapshot Before** | o toast "item adicionado" ainda na tela, **sobre** o botão |
| Network | nada anormal |

O passo 2 encerrou o caso. Nenhum `console.log` daria essa linha.

## Passo 3 — a árvore

Itens 1 a 4: não há `waitForTimeout`, nem asserção que lê valor, nem espera fora de ordem,
nem `networkidle`. Item 6: **falha só em CI** → a causa é que o passo anterior termina mais
rápido lá, e o toast de 3 s ainda está na tela.

## Passo 4 — bissecção (confirmação)

```
$ bash scripts/isolar.sh e2e/checkout.spec.ts:52 20
== 1. É intermitente? 20 execuções → FALHOU
== 2. Estado compartilhado? --workers=1 → passou
== 3. Dependência de outro teste? → passou
```

O item 2 passar **não** significa que a causa é paralelismo: significa que em série o timing
muda. `--workers=1` diagnostica, não conserta.

## O achado

```
`PW-ACT-01` — e2e/checkout.spec.ts:52
Sintoma: falha ~1 em 4 execuções em CI, sempre no clique em "Confirmar"; passa local.
Evidência: trace, aba Log da ação click — "element intercepts pointer events";
 Snapshot Before mostra o toast de "item adicionado" ainda na tela, sobre o botão.
Causa: o toast tem 3 s de duração e cobre o botão; em CI o passo anterior termina mais rápido.
Correção: NÃO usar force: true. Aguardar o toast sair antes de clicar —
 await expect(page.getByRole('status')).toBeHidden — ou corrigir o z-index/posição do toast,
 que é o defeito real: o usuário também não consegue clicar.
Ver Playwright - Ações e Auto-waiting.
```

## O que este exemplo demonstra

| Decisão | Onde está a regra |
| --- | --- |
| a aba **Log** deu a causa, não o Errors | `leitura-do-trace.md` |
| `force: true` foi explicitamente descartado | `conserto-x-anestesico.md` |
| a correção aponta o **defeito de produto**, não só o teste | § *Formato*, terceira regra |
| `--workers=1` foi usado para confirmar, não para consertar | `arvore-de-hipoteses.md` |
| o fechamento é `--repeat-each=20`, não uma execução verde | § *Fechar*, item 1 |
