# Exemplo trabalhado — diagnóstico de uma suíte

Time reexecuta o job por reflexo. Ninguém investiga vermelho antes de tentar de novo.

---

## Passo 0 — as falhas são defeitos reais?

Não: mesmo commit, mesma suíte, resultados diferentes. **Intermitente** → é desta skill.

## Passo 1 — a medida

```
$ bash scripts/medir-flakiness.sh "bunx playwright test" 20

== Anestésicos já instalados
 -- retry configurado:
 playwright.config.ts:12: retries: 3
 -- espera por tempo fixo, a causa nº 1 (TS-SUI-07):
 e2e/checkout.spec.ts:22,31,44,58,63,71,88 (7 ocorrências)
 -- skip / todo acumulado:
 e2e/pagamento.spec.ts:1
== Taxa de flakiness
..F....F..F.....F..F
 execuções: 20 | falhas: 5 | taxa: 25.0%
 ACIMA DE ~1%: a suíte perdeu valor.
```

Histórico do CI confirma: **34 das últimas 200 execuções** falharam e passaram na
reexecução sem mudança de código = **17%**.

## Passo 2 — as seis perguntas

Pergunta 1: sim, intermitente. **Pare aqui** — flakiness contamina todo o resto, e responder
as outras cinco antes de resolver esta produz diagnóstico sobre ruído.

## Passo 3 — a causa

9 dos 12 arquivos de `e2e/` usam **espera por tempo fixo** antes da asserção (`TS-SUI-07`).
Os outros 3 compartilham a mesma conta de teste entre workers (`TS-SUI-09`) — confirmado
porque, com `--workers=1`, a falha some.

## O relatório

```
`TS-CORE-04` — a suíte de e2e/, últimas 200 execuções do CI
Sintoma: o time reexecuta o job por reflexo; ninguém investiga vermelho antes de tentar de novo.
Medida: 34 das 200 execuções falharam e passaram na reexecução sem mudança de código = 17%
 de taxa de flakiness. O limiar em que uma suíte perde valor é ~1%.
Causa: 9 dos 12 arquivos de e2e/ usam espera por tempo fixo antes da asserção (TS-SUI-07);
 os outros 3 compartilham a mesma conta de teste entre workers (TS-SUI-09).
Correção: (1) substituir espera por tempo por asserção que reespera — começar por
 e2e/checkout.spec.ts, que tem 7 ocorrências; (2) conta por worker.
 NÃO subir retries: com 17%, retry mascara e não resolve (TS-SUI-03).
Ver Teste de Software - Confiabilidade da Suíte, e Playwright § 5.2 para as formas concretas.
```

E o segundo achado, de outra natureza — veio do **teste de trinta segundos**:

```
`TS-SUI-04` — packages/core/src/desconto.ts
Sintoma: a suíte passa 100% e um defeito de cálculo de desconto chegou em produção.
Medida: teste de trinta segundos — invertida a comparação `>=` para `>` na linha 22,
 a suíte inteira continuou verde (0 testes falharam).
Causa: os 14 testes de desconto chamam a função e afirmam que não lança; nenhum
 compara o valor retornado. Cobertura do arquivo: 96%.
Correção: asserção sobre o valor, com os casos de valor limite (TS-TEC-01):
 0%, 50%, 50,01%, 100%, −5%.
Ver Teste de Software - Técnicas de Design de Caso.
```

## O que este exemplo demonstra

| Decisão | Onde está a regra |
| --- | --- |
| a medida veio antes da opinião, e o número tem limiar | `medicao.md` |
| a pergunta 1 interrompeu as outras cinco | `causas-de-flake.md` |
| `--workers=1` foi usado para **diagnosticar**, não para corrigir | `conserto-x-anestesico.md` |
| "subir retries" foi explicitamente descartado no relatório | `TS-SUI-03` |
| 96% de cobertura e defeito em produção convivem sem contradição | `deteccao.md` |
| cada correção tem ponto de partida nomeado | `TS-CORE-04` |
