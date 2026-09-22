# Severidade, formato e o corte

| Severidade | O que entra |
| --- | --- |
| **Bloqueante** | teste que **nunca roda** (`BUN-TEST-01`); asserção que nunca executa (`BUN-TEST-06`); portão de cobertura que não reprova (`BUN-TEST-27`, `BUN-TEST-28`); `-u` no CI (`BUN-TEST-05`); typecheck ausente (`BUN-TEST-18`) |
| **Alta** | vazamento de mock/spy (`BUN-TEST-02`, `BUN-TEST-03`); dependência de ordem entre arquivos (`BUN-TEST-09`); recurso compartilhado sob `--parallel` (`BUN-TEST-10`); matcher de DOM não registrado (`BUN-TEST-12`); `.only` commitado (`BUN-TEST-08`) |
| **Média** | `cleanup()` ausente (`BUN-TEST-26`); `await` faltando em `userEvent`; snapshot sem property matcher (`BUN-TEST-19`); `.skip` de bug conhecido (`BUN-TEST-11`); versão não pinada (`BUN-TEST-15`) |
| **Baixa** | preferência sem ID — **não é achado**, ver Passo 6 |

O critério que decide entre Bloqueante e Alta: **o defeito faz o CI mentir?** Teste que não roda e portão que não fecha produzem verde falso — é outra categoria de problema que "teste frágil".

---

## Passo 5 — Formato de saída de um achado

Quatro partes, o mesmo contrato de [[react-review]] e [[drizzle-review]]:

```
`ID-DA-REGRA` — arquivo:linha
<o que está errado, uma frase>
Correção: <mudança concreta>
Ver [[Satélite correspondente]].
```

### Exemplo

```
`BUN-TEST-06` — apps/api/test/pagamento.test.ts:34
A asserção vive no catch e o teste passa quando cobrar() não lança: nenhuma asserção roda.
Correção: expect.assertions(1) no topo, ou trocar por await expect(cobrar(...)).rejects.toThrow(PagamentoRecusado).
Ver [[Bun - Testes - Escrita e Asserções]].
```

Regras do formato:

- **ID conferido na § 6** antes de escrever.
- **`arquivo:linha` sempre.** Para sonda, a evidência é a saída do comando — cole-a, incluindo o exit code quando ele for o achado (S5).
- **Correção concreta.** Se a suíte já tem o padrão certo em outro arquivo, aponte esse arquivo: estender o padrão estabelecido vale mais que introduzir um novo.
- **Um link de satélite.**

---

## Passo 6 — O corte: achado × opinião

**Achado sem ID de regra é opinião**, com três saídas:

1. **Existe ID** → achado, cite o ID.
2. **Não existe ID, mas há nota normativa** (o que testar, política de integração externa, o que asseverar num componente) → cite a nota: "[[Software Testing]]", "[[Testes de frontend devem observar comportamento]]". Não invente `BUN-TEST-*`.
3. **Nem ID nem nota** → seção separada "Sugestões (sem regra)", nunca misturada com os achados.

Dois casos que **não** são achado, e confundi-los queima a credibilidade do relatório:

- **Ausência de teste.** "Este módulo não tem teste" é decisão de estratégia, não violação de regra — [[Software Testing]]. Reporte como pergunta, não como defeito.
- **Estilo de asserção.** `toEqual` onde você usaria `toStrictEqual` só é achado se a forma exata for o contrato. Sem esse argumento, é preferência.

Se a varredura encontrar defeito recorrente e real sem regra correspondente, o produto certo é uma **proposta de regra** para [[Bun - Testes]] § 6 — ID sugerido, texto e o caso que a motivou — não uma citação falsa.

---

