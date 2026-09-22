# A frase, o nível e a proporção

> Passos 1 a 3 da skill. A árvore completa é a § 4.1 de [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md); aqui está o
> percurso e o que ele elimina.

---

## A frase, antes de tudo

> **O que exatamente pode dar errado aqui?**

Escreva-a. Se não conseguir, **o teste não deveria ser escrito ainda** (`TS-CORE-01`): não
há como julgar se ele vale o custo, nem em que nível ele pertence.

A frase boa **nomeia um sujeito e um comportamento errado** — e é ela que decide o nível,
não a intuição:

| ✗ vago | ✓ acionável | Nível que a frase revela |
| --- | --- | --- |
| "o checkout pode quebrar" | "o desconto acima de 50% pode ser aplicado sem aprovação" | unidade |
| "a listagem pode falhar" | "um pedido recém-criado pode não aparecer na lista" | E2E |
| "o form pode dar erro" | "o campo de CPF pode aceitar 10 dígitos" | unidade |
| "a tela pode ficar estranha" | "a lista vazia pode renderizar sem o estado de vazio" | componente |
| "a API pode mudar" | "o servidor pode renomear `quantidade` e o cliente não perceber" | contrato |

---

## O nível

| O que pode dar errado | Nível | Ferramenta |
| --- | --- | --- |
| cálculo, parse, validação, invariante de domínio | **unidade** | `bun-test-build` |
| duas peças minhas conversando (caso de uso + repositório) | **integração**, com dependência real controlada | `bun-test-build` |
| o formato que atravessa a fronteira com um sistema que não é meu | **contrato** — e boa parte é o compilador | `Docs/Hono - Validação e RPC.md` · `Docs/Elysia - Schema e Eden.md` |
| estado visual/interativo de um componente | **componente** | `storybook-story` · `storybook-test` |
| a jornada crítica funciona com rota, sessão e rede | **E2E** | `playwright-build` |
| tipo incompatível, uso incorreto de API | **estático** | `Docs/TypeScript.md` |

Três cortes decidem a maioria dos casos:

- **Regra de negócio nunca é E2E** (`TS-NIV-02`). O E2E verifica que a tela exibe o valor calculado; o cálculo é unidade.
- **Se precisa de rota, login ou mais de uma tela** → E2E. Se varia **props** → componente.
- **Se o defeito está na junta entre peças**, unidade de cada peça passa e o sistema quebra — é integração.

E o corte que separa esta skill da intuição: **E2E é a menor fatia da suíte**, e escrever
E2E por default é o erro mais caro que um agente comete (`TS-CORE-02`).

---

## A proporção — por módulo, não por repositório

`TS-NIV-08`. Não é política global:

```
A complexidade deste módulo está DENTRO de funções?
 (cálculo, domínio rico, regra densa, parsing)
 → pirâmide: a massa vai para unidade

A complexidade está ENTRE as peças?
 (BFF, adaptação de dado, orquestração, mapeamento de contrato)
 → trophy: a massa vai para integração
```

O pacote que calcula imposto é pirâmide. A rota que orquestra três chamadas é trophy.
**O mesmo repositório tem os dois**, e tratar a proporção como política global é o que
produz suíte desequilibrada.

Os dois modelos concordam em uma coisa, e ela vale como regra: **E2E é a menor fatia**, e
a forma invertida — massa em E2E — é o antipadrão (`TS-NIV-04`).

**Conte a camada estática.** TypeScript e lint pegam uma classe de defeito inteira antes de
qualquer teste rodar, e são a camada mais barata que existe (`TS-TIPO-08`).

---

## Relacionados

- [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md) § 4.1 — a árvore completa
- [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) — a fonte
- `tecnicas-de-caso.md` — o passo seguinte, quando houver entrada a exercitar
