# As seis perguntas e as dez causas

---

## As seis perguntas (§ 4.5 do hub) — percorra na ordem

| # | Pergunta | Se sim, a causa é | Regra |
| --- | --- | --- | --- |
| 1 | alguma falha é intermitente? | **flakiness** — problema nº 1, contamina todo o resto | `TS-CORE-04` |
| 2 | quando falha, dá para saber o motivo em < 1 min? | diagnóstico ruim: nome, granularidade, instrumentação | `TS-PROC-06` |
| 3 | quebrando o código de propósito, algo fica vermelho? | **asserção fraca**, ou dublê no lugar errado | `TS-CORE-03`, `TS-SUI-04` |
| 4 | um refactor sem mudança de comportamento quebra muitos testes? | testes observam **implementação** | `TS-CORE-07`, `TS-SUI-06` |
| 5 | a suíte demora tanto que ninguém roda antes do PR? | forma invertida: massa no nível errado | `TS-NIV-04` |
| 6 | passa tudo e defeito chega em produção? | **classe de risco** descoberta, não linha | `TS-CORE-05`, `TS-TIPO-02` |

A pergunta **3 é a mais reveladora e a menos feita** — uma suíte pode ser 100%
determinística, rápida, verde **e não detectar nada** (`deteccao.md`).

A pergunta **6 é a que mais traz o time até aqui**, e a resposta quase nunca é "falta
cobertura": é **classe de risco** ausente — estado de erro, entrada no limite, transição
inválida (`TS-TEC-01`, `TS-TEC-04`, `TS-TIPO-02`).

---

## As dez causas, em ordem de frequência

| Causa | Sintoma | Regra |
| --- | --- | --- |
| **espera por tempo fixo** | passa na máquina rápida, falha no CI | `TS-SUI-07` |
| **estado compartilhado** | falha só em paralelo; passa com um worker | `TS-SUI-09` |
| **dependência de ordem** | passa sozinho, falha na suíte | `TS-SUI-01` |
| **relógio real** | falha à meia-noite, na virada do mês, no horário de verão | `TS-DUB-05` |
| **aleatoriedade** | falha 1 em 50, sem padrão | `TS-DUB-05` |
| **rede externa** | falha quando o terceiro oscila | `TS-CORE-03` |
| **animação / render** | clique no lugar errado | — |
| **vazamento entre testes** | o segundo teste vê o estado do primeiro | `TS-SUI-08` |
| **paralelismo do runner** | porta, arquivo ou banco em disputa | `TS-SUI-09` |
| **ordem de coleção** | asserção de lista falha às vezes | `TS-SUI-01` |

**A causa nº 1 é sempre a mesma, em qualquer ferramenta:** esperar **tempo** em vez de
esperar **condição**. Ela é lenta quando a máquina está rápida e insuficiente quando está
lenta — o pior de dois mundos, por construção.

---

## Separar as hipóteses

| Rode | Se o comportamento mudar, a causa é |
| --- | --- |
| o teste sozinho | dependência de outro teste |
| com **um worker** | estado compartilhado / paralelismo |
| em ordem aleatória | dependência de ordem |
| 20× o mesmo teste | confirma que é intermitente |
| em container com a imagem do CI | paridade de ambiente |

Formas concretas por ferramenta: `Docs/Playwright.md` § 5.2 (a árvore mais detalhada do vault) e
`Docs/Bun - Testes - Ciclo de Vida e Isolamento.md`.

> **Diagnosticar não é consertar.** Um worker faz a falha desaparecer e **mantém** o
> acoplamento, com a suíte N vezes mais lenta. Prefixar arquivos com `001-`, `002-`
> **codifica** a dependência em vez de removê-la, e a próxima inserção quebra tudo.

---

## Relacionados

- [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) § 2 — as dez causas, com corpo
- [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md) § 4.5 — a árvore das seis perguntas
- `conserto-x-anestesico.md` — o que **não** fazer com o que você achou
