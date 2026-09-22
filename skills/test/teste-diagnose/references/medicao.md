# Medir antes de opinar

> Esta skill se distingue de conversa de corredor exatamente aqui: **flakiness tem número,
> e o número tem limiar.**

---

## Passo 0 — a pergunta que vem antes

> **As falhas são defeitos reais do produto?**

Se sim, **a suíte fez o trabalho dela** e não há nada a diagnosticar. Confundir "muito
vermelho" com "suíte ruim" é como um time desliga a única coisa que estava avisando.

O sinal de distinção: falha **determinística** (sempre no mesmo lugar, com a mesma
mensagem) é defeito; falha **intermitente** é a suíte. Só o segundo caso é desta skill.

---

## As medidas

| Métrica | Como obter | Referência |
| --- | --- | --- |
| **taxa de flakiness** | execuções que falharam e passaram na reexecução ÷ total, no histórico do CI — ou `scripts/medir-flakiness.sh` | **~1% é onde a suíte perde valor**; o índice do Google é ~0,15% |
| **investigações inúteis/dia** | taxa × nº de testes × execuções por dia | 0,1% × 10 000 = **10 por dia** |
| **taxa de escape** | defeitos achados em produção ÷ total de defeitos | a métrica mais honesta que existe |
| **duração** | tempo da suíte por nível | se ninguém roda antes do PR, deixou de ser portão |
| **retry ativo** | inventário do script | retry é anestésico (`TS-SUI-03`) |
| **`skip` acumulado** | inventário do script | dívida, e frequentemente flake escondido |

```bash
bash ~/.claude/skills/teste-diagnose/scripts/medir-flakiness.sh "bun test" 20
```

O script faz duas coisas: **inventaria os anestésicos já instalados** (retry, workers=1,
`skip`, espera por tempo fixo, relógio real, prefixo numérico, `try/catch` no corpo) e
**mede a taxa** repetindo o comando N vezes.

---

## Por que a taxa, e não a impressão

Uma suíte com 0,05% de flake e uma com 3% têm o **mesmo sintoma percebido** ("às vezes
falha") e prognósticos opostos: a primeira está sã e alguém teve azar; a segunda perdeu
valor e precisa de intervenção.

**O argumento que fecha qualquer discussão sobre "conviver com flaky":** acima de ~1%, as
pessoas param de acreditar no vermelho — e o vermelho **verdadeiro** passa junto com os
falsos. O custo não é o tempo de reexecutar; é a perda do sinal (`TS-CORE-04`).

**Cuidado com o zero.** 20 execuções verdes não provam ausência de um flake de 1 em 50.
Se a taxa medida for 0 e o time relata instabilidade, a medida certa é o **histórico do
CI**, não mais uma rodada local.

---

## Relacionados

- [[Teste de Software - Confiabilidade da Suíte]] § 1 — a aritmética
- [[Teste de Software]] § 2, afirmação 5 — uma suíte não confiável é pior que nenhuma
- `causas-de-flake.md` — o passo seguinte, depois de ter o número
