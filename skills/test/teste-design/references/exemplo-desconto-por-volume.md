# Exemplo trabalhado — desconto por volume no checkout

Tarefa: *"cobrir o desconto por volume no checkout"*.

---

## Passo 1 — a frase

> "Um desconto acima de 50% pode ser aplicado sem passar pela aprovação do gerente."

Sujeito e comportamento errado: acionável. Compare com "o checkout pode quebrar", que não
aponta nível nenhum.

## Passo 2 — o nível

É **regra de negócio**, não jornada → unidade (`TS-NIV-02`). O E2E ganha **um** caso: a
tela exibe o valor que o cálculo produziu.

## Passo 3 — a proporção

O módulo de precificação é cálculo denso → **pirâmide**, massa em unidade (`TS-NIV-08`).

## Passo 4 — os casos

A regra tem faixa (0–50% livre, acima exige aprovação) → **valor limite** (`TS-TEC-01`):

| Desconto | Esperado | Por quê |
| --- | --- | --- |
| 0% | aplica | fronteira inferior |
| 50% | aplica | **o limite** |
| 50,01% | exige aprovação | logo acima |
| 100% | exige aprovação | extremo |
| −5% | rejeita | classe inválida (`TS-TEC-02`) |

Mais transição de estado: aprovar um desconto **já aprovado**, e aplicar um **rejeitado**
(`TS-TEC-04`).

## Passo 5 — substituição

O cálculo é puro: **nada a substituir**. O E2E precisa de um pedido existente → cria por
API, não pela UI (`TS-CORE-03`). Se a regra usa "data da promoção", o relógio é controlado
(`TS-DUB-05`).

## O resultado

**5 testes de unidade + 2 de transição + 1 E2E.**

A alternativa intuitiva — 8 E2E percorrendo o checkout — custaria minutos por execução,
falharia por qualquer defeito no caminho, e diagnosticaria pior. É o mesmo número de
casos comprando muito menos informação.

## Passo 7 — o bastão

| Nível | Continua em |
| --- | --- |
| unidade, transição | `bun-test-build` |
| E2E | `playwright-build` |

Entregue junto: **nível, casos derivados e o que será substituído**. A skill de ferramenta
implementa; ela não reabre essas perguntas.
