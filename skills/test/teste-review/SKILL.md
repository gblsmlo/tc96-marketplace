---
nome: teste-review
descricao: Auditar a estratégia de teste de um repositório — a forma da suíte, não os testes individuais — com nove sondas executáveis e IDs `TS-*`, respondendo "esta suíte protege alguma coisa?" — use quando a tarefa for avaliar se a cobertura de risco é adequada, se a proporção entre níveis faz sentido, se os portões de qualidade realmente fecham, se a camada estática está contando, ou se há classe de risco sem nenhum teste. Não use para achar defeito em teste individual, que é playwright-review ou bun-test-review. Não use para suíte instável, que é teste-diagnose, nem para decidir um teste novo, que é teste-design.
tipo: skill
familia: test
fonte: "[Teste de Software](../../../knowledge-base/docs/teste-de-software.md)"
tags:
  - skill
  - testing
  - software-quality
  - code-review
---

# teste-review

> **Fonte desta skill:** [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) — a § 6 normativa (64 regras em 7 famílias), a § 6.1 com as críticas dos satélites, e a § 6.2 com os IDs canônicos. O corpo de cada família vive no satélite dono do ID.
> Esta skill **não contém** o texto das regras — ela diz o que executar, em que ordem varrer, como classificar e como reportar.

Contrato que esta skill implementa: [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 7 ("Contrato de skill").

> **Nota de desenho.** Esta skill audita a **forma** da suíte; `playwright-review` e `bun-test-review` auditam os **testes**. A diferença é operacional: elas encontram `waitForTimeout` na linha 41; esta encontra que 200 dos 214 testes são E2E e que nenhum cobre o estado de erro. Um repositório pode passar nas duas de ferramenta e falhar aqui — e é o caso mais comum.

---

## Quando usar

Avaliar uma suíte **como sistema**. A pergunta é *"esta suíte protege alguma coisa?"* — diferente de *"os testes passam?"* e diferente de *"os testes estão bem escritos?"*.

| Situação | Vá para |
| --- | --- |
| achar defeito em teste individual | `playwright-review` (E2E) · `bun-test-review` (unidade/integração) |
| suíte instável, flaky, ninguém confia | `teste-diagnose` |
| decidir um teste novo | `teste-design` |
| uma falha concreta | `playwright-diagnose` |
| revisar o código de aplicação | `react-review` · `drizzle-review` |
| processo, defeito, severidade, métricas de time | [Teste de Software - Processo e Artefatos](../../../knowledge-base/docs/teste-de-software-processo-e-artefatos.md) |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 2 | o teste compra informação a um preço — o critério de toda avaliação aqui |
| 2 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 6 + § 6.1 | as regras invioláveis e as críticas |
| 3 | `references/mapa-de-ids.md` | **obrigatório antes de citar** — três IDs são apelidos |
| 4 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 4.1 e § 4.4 | a árvore de nível, e "quando parar de escrever teste" |
| 5 | o satélite do achado | via § 5 do hub |

**Nunca carregue os seis satélites.**

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/sondas.md` | as nove sondas, as três paradas obrigatórias, e o que elas **não** medem |
| `references/ordem-da-varredura.md` | os 11 passos por impacto, e as três conclusões que não se misturam |
| `references/severidade-e-relatorio.md` | classificação, formato com medida, o corte, e o fechamento |
| `references/antipadroes.md` | 29 antipadrões com ID e satélite |
| `references/mapa-de-ids.md` | os 64 `TS-*` por satélite e seção, e os três apelidos |
| `references/exemplo-auditoria.md` | auditoria inteira, das sondas ao "não verificado" |
| `scripts/sondas-suite.sh` | roda S1, S3–S9 e prepara S2 |

---

## Passo 1 — Sondar antes de ler

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/teste-review/scripts/sondas-suite.sh.
```

A forma de uma suíte é **invisível** lendo arquivos: cada teste parece razoável, e o conjunto está desequilibrado.

**Três paradas obrigatórias** — se qualquer uma disparar, reporte antes de continuar:

| Sonda | Se mostrar… | Por quê |
| --- | --- | --- |
| S1 | forma invertida | criticar teste individual vira ruído; a correção reescreve boa parte da suíte |
| S4 | portão que não reprova | torna toda discussão de cobertura decorativa |
| S3 | `no-floating-promises` desligada com Playwright | **bloqueante**: asserção que não afirma nada não aparece como falha |

Detalhe das nove e o que elas não medem: `references/sondas.md`.

---

## Passo 2 — Varrer a estratégia, na ordem

`references/ordem-da-varredura.md`, 11 passos por impacto: portão → forma → classe de risco descoberta → camada estática → atributo não funcional → contrato → substituição → determinismo → reteste → exploratório → teste que não paga.

Se um passo produz achado que invalida o seguinte, **pare de auditar o interior** e reporte a mudança de forma.

---

## Passo 3 — Classificar e reportar

`references/severidade-e-relatorio.md`. Bloqueante é o que produz **verde falso**; Alta é risco descoberto **hoje**; Média é dívida estrutural.

Para achado de forma, **a evidência é a medida** — cole os números da sonda. "Tem E2E demais" sem contagem é opinião.

**Quatro coisas não são achado:** ausência de teste isolada, proporção que não bate com pirâmide *ou* trophy, cobertura baixa, e preferência de ferramenta. Confundi-las queima a credibilidade do relatório inteiro.

---

## Passo 4 — Fechar

1. **Transforme sonda em portão** — achado que só existe no relatório volta em seis meses.
2. **Separe "não protegido", "no nível errado" e "quebrado"** — a do meio é das skills de ferramenta.
3. **Ordene por severidade**, não por diretório.
4. **Dê o próximo passo**, não a lista inteira.
5. **Se houver flake ativo, pare aqui** e continue em `teste-diagnose` (`TS-CORE-04`).
6. **Declare o que não foi verificado.** "Não verificado" não é "sem achado".

---

## Exemplo

Suíte de 214 casos, CI verde há meses, defeito chegando em produção. As sondas mostram 87% em E2E, `continue-on-error` no CI, `strict` desligado sem `no-floating-promises`, e **dois** arquivos mencionando estado de erro. Duas paradas disparam ao mesmo tempo; a leitura de 10 arquivos de E2E explica a forma (7 verificam regra de negócio). Cobertura de 62% e massa em integração no BFF **não** viram achado.

Auditoria completa, com relatório e a seção "não verificado": `references/exemplo-auditoria.md`.

---

## Relacionados

- [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) — fonte desta skill: § 6 normativa, § 6.1, § 6.2, § 7 contrato
- `teste-design` · `teste-diagnose` — as skills irmãs
- `playwright-review` · `bun-test-review` — auditam os **testes**; esta audita a **forma**
- `Github Actions` — onde os portões vivem
- `Docs/Bun - Testes - Cobertura e CI.md` · `Docs/Playwright - Execução, Retries e CI.md` — o mecanismo dos portões
