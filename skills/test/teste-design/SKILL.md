---
name: teste-design
description: Decidir em que nível um teste vai e derivar os casos antes de escrever uma linha, citando IDs `TS-*` da doc do vault — use quando a tarefa for responder "que teste eu escrevo para isto?", escolher entre unidade/integração/componente/contrato/E2E, definir a proporção da suíte de um módulo, derivar casos de uma entrada (faixa, limite, combinação, estado), ou decidir o que substituir por dublê. Não use para escrever o teste em si — depois de decidido o nível, a fonte passa a ser playwright-build ou bun-test-build. Não use para auditar suíte existente, que é teste-review, nem para suíte instável, que é teste-diagnose.
tags:
  - skill
  - testing
  - software-quality
  - test-design
fonte: "[[Teste de Software - Níveis e Escopo]]"
---

# teste-design

> **Fonte desta skill:** [[Teste de Software - Níveis e Escopo]] e [[Teste de Software - Técnicas de Design de Caso]], com o hub [[Teste de Software]] como roteador. As 64 regras da família `TS-*` moram na § 6 do hub.
> Esta skill **não contém** o texto das regras — ela diz o que decidir, em que ordem, e para quem entregar depois.

Contrato que esta skill implementa: [[Teste de Software]] § 7 ("Contrato de skill").

> **Nota de desenho.** Esta é a **camada de conceito**: decide *o quê* e *em que nível*. Ela **não escreve teste** — quem escreve é [[playwright-build]] ou [[bun-test-build]], e a passagem de bastão está no Passo 7. Rodar as duas camadas como se fossem uma só desperdiça contexto; pular esta e ir direto para a ferramenta produz **E2E por default**, o antipadrão de maior custo do stack.

---

## Quando usar

Há uma feature, um bug, uma regra, uma jornada — e a pergunta é *que teste cobre isto, e onde ele mora?*

| Situação | Vá para |
| --- | --- |
| o nível já está decidido, quero escrever | [[playwright-build]] (E2E) · [[bun-test-build]] (unidade/integração) · [[storybook-test]] (componente) |
| auditar a estratégia de uma suíte existente | [[teste-review]] |
| suíte em que ninguém confia | [[teste-diagnose]] |
| um teste concreto falhando | [[playwright-diagnose]] · [[bun-test-review]] |
| critério de aceite de requisito não funcional | [[Teste de Software - Processo e Artefatos]] |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [[Teste de Software]] § 2 | o teste compra informação a um preço; a camada mais barata que ainda pega o defeito |
| 2 | [[Teste de Software]] § 4.1 | a árvore de nível — o núcleo desta skill |
| 3 | [[Teste de Software]] § 6 | as 8 `TS-CORE-*` e as críticas da § 6.1 |
| 4 | [[Teste de Software]] § 4.3 | a árvore de técnica, quando houver entrada a exercitar |
| 5 | [[Teste de Software]] § 4.2 | a árvore de substituição, quando houver dependência |

**Nunca carregue os seis satélites.** E não carregue a nota de ferramenta ainda — ela entra no Passo 7.

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/arvore-de-nivel.md` | a frase, o nível, a proporção por módulo (Passos 1–3) |
| `references/tecnicas-de-caso.md` | técnica por forma da entrada, fronteiras não numéricas, os cinco estados (Passo 4) |
| `references/substituicao.md` | a pergunta única do dublê e o vocabulário (Passo 5) |
| `references/antipadroes.md` | a grade de conferência, 24 antipadrões com ID |
| `references/mapa-de-ids.md` | os 64 `TS-*` por satélite e seção, e os três **apelidos** |
| `references/exemplo-desconto-por-volume.md` | caso trabalhado, da frase ao bastão |
| `scripts/gerar-mapa-de-ids.sh` | regenera o mapa nas três skills de teste |

---

## Passo 1 — A frase, antes de tudo

> **O que exatamente pode dar errado aqui?**

Se não conseguir escrevê-la, **o teste não deveria ser escrito ainda** (`TS-CORE-01`). A frase boa nomeia **um sujeito e um comportamento errado** — e é ela que decide o nível, não a intuição. Exemplos de frase vaga × acionável: `references/arvore-de-nivel.md`.

---

## Passo 2 — Escolher o nível

`references/arvore-de-nivel.md`, ou a § 4.1 do hub. Três cortes resolvem a maioria:

- **regra de negócio nunca é E2E** (`TS-NIV-02`);
- precisa de rota, login ou mais de uma tela → **E2E**; varia props → **componente**;
- defeito na **junta** entre peças → integração.

**E2E é a menor fatia da suíte** (`TS-CORE-02`).

---

## Passo 3 — Escolher a proporção do módulo

Por **módulo**, não por repositório (`TS-NIV-08`). Complexidade dentro de funções → pirâmide; entre peças → trophy. O mesmo repositório tem os dois. Conte a camada estática (`TS-TIPO-08`).

---

## Passo 4 — Derivar os casos

`references/tecnicas-de-caso.md`. Se for para aplicar **uma** técnica, é **valor limite** (`TS-TEC-01`). Não esqueça as fronteiras não numéricas — coleção **vazia** é a que mais quebra UI — nem os cinco estados do fluxo (`TS-TIPO-02`).

---

## Passo 5 — Decidir o que substituir

`references/substituicao.md`. A pergunta única: **se a dependência real divergisse do dublê, este teste deveria quebrar?** Se sim, não substitua (`TS-CORE-03`). Relógio e aleatoriedade: substitua sempre (`TS-DUB-05`).

---

## Passo 6 — Autoverificação antes de passar o bastão

| # | Confira | Regra |
| --- | --- | --- |
| 1 | a frase existe e é específica | `TS-CORE-01` |
| 2 | o nível é o mais barato que ainda pega o defeito | `TS-CORE-02` |
| 3 | nenhuma regra de negócio foi mandada para E2E | `TS-NIV-02` |
| 4 | as fronteiras da entrada têm caso | `TS-TEC-01`, `TS-TEC-03` |
| 5 | as classes/transições **inválidas** têm caso | `TS-TEC-02`, `TS-TEC-04` |
| 6 | os cinco estados estão decididos (mesmo que "não cobrir") | `TS-TIPO-02` |
| 7 | nada que o teste vem provar está sendo substituído | `TS-CORE-03` |
| 8 | relógio e aleatoriedade estão controlados | `TS-DUB-05` |
| 9 | o dublê está chamado pelo nome certo | `TS-DUB-01` |
| 10 | requisito não funcional tem número e percentil | `TS-TIPO-05`, `TS-TIPO-06` |

Depois, passe `references/antipadroes.md` linha a linha.

---

## Passo 7 — Passar o bastão

| Nível | Continue em |
| --- | --- |
| E2E | [[playwright-build]] |
| unidade, integração | [[bun-test-build]] |
| componente | [[storybook-story]] · [[storybook-test]] |
| contrato | [[elysia-schema]] · [[Hono - Validação e RPC]] |
| estático | [[TypeScript]] · [[Zod - Validação de Ambiente]] |

**Entregue a decisão junto:** nível, casos derivados, e o que será substituído. A skill de ferramenta implementa — ela não reabre essas perguntas.

---

## Passo 8 — Fechar

1. **Declare o que decidiu não cobrir.** Decisão registrada não é lacuna; decisão implícita é.
2. **Se a frase não caiu em nenhum nível**, o requisito está ambíguo — o achado é de requisito (`TS-PROC-01`).
3. **Se o defeito veio de produção**, o teste vai no nível mais barato que o pega (`TS-CORE-06`) — é o teste com maior prova de valor que existe.
4. **Se a decisão foi "não testar"**, escreva o porquê.

---

## Exemplo

*"Cobrir o desconto por volume no checkout."* A frase — "desconto acima de 50% pode ser aplicado sem aprovação" — manda para **unidade**, não para o checkout inteiro. Valor limite gera 5 casos, transição de estado mais 2, e o E2E fica com **um**: a tela exibe o valor calculado. A alternativa intuitiva (8 E2E) compra menos informação por muito mais tempo de execução.

Caso completo: `references/exemplo-desconto-por-volume.md`.

---

## Relacionados

- [[Teste de Software - Níveis e Escopo]] — fonte desta skill
- [[Teste de Software - Técnicas de Design de Caso]] — a segunda fonte, do Passo 4
- [[Teste de Software]] — o hub: § 2, § 4.1, § 4.2, § 4.3, § 6, § 7
- [[teste-review]] · [[teste-diagnose]] — as skills irmãs
- [[playwright-build]] · [[bun-test-build]] · [[storybook-test]] — para onde o bastão vai
