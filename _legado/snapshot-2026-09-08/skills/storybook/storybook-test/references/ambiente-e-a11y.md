# Substituir o ambiente, e acessibilidade

Só entra quando a story sobe de nível: composição de página, componente que fala com o BFF, módulo server-only.

| Substituir | Como | Regra |
| --- | --- | --- |
| callback observável | `fn()` em `meta.args` | `SB-TEST-03` |
| módulo do projeto ou pacote | `sb.mock()` — **só** em `.storybook/preview.*` | `SB-MOCK-01` |
| comportamento do mock, por story | `mocked()` em `beforeEach` | `SB-MOCK-04` |
| requisição HTTP | MSW, via `mswLoader` + `beforeEach({ msw })` | `SB-MOCK-07` |
| relógio, aleatoriedade, locale | `beforeEach` que **retorna** a limpeza | `SB-CTX-08` |

**A divisão que vale memorizar:** o preview decide **o quê** é mockado; a story decide **como se comporta**. `sb.mock()` num arquivo de story não funciona, e não falha de forma óbvia.

Dois detalhes que quebram em silêncio: arquivo em `__mocks__` precisa ser **JavaScript com ESM**, não TypeScript (`SB-MOCK-03`); e o tipo da resposta mockada reusa o tipo exportado pelo servidor, nunca redigitado à mão (`SB-MOCK-07`).

**Mocks `fn()` não precisam de restauração manual** — o Storybook reseta entre stories. É a exceção declarada de `SB-TEST-07`.

---

## Passo 4 — Acessibilidade

```ts
parameters: { a11y: { test: 'error' } }
```

**`'todo'` não produz nada em CI** — nem erro, nem aviso, nem saída. Só `'error'` falha (`SB-TEST-04`). Um projeto inteiro em `'todo'` tem checagem que só existe para quem abre a UI.

A rampa é o problema real: ligar `'error'` num design system existente deixa o CI vermelho no dia 1, e a única válvula produz zero saída. As duas pontas estão documentadas e o meio não — é pendência aberta em [[Storybook - Pendências de revisão]]. A saída praticável é `'error'` por story ou por componente, avançando em ondas, em vez de global de uma vez.

O addon desabilita a regra `region` por padrão, para evitar **falso positivo** em componente isolado — um botão fora de landmark é o normal do Storybook, não defeito.

---

