# Severidade, formato de achado e o corte achado × opinião

---

## Classificação

Precedência normativa, de [[React.js]] § 7 (invariante 3) e [[React - Rules of React]] § 6.

| Severidade | O que entra | Por quê |
| --- | --- | --- |
| **Bloqueante** | `REACT-PURE-*`, `REACT-CALL-*`, `REACT-HOOK-*` | quebra o contrato do React; não se negocia por concisão nem por estilo |
| **Alta** | regras críticas de [[React.js]] § 6.1 — `REACT-EFFECT-06`, `REACT-PAT-03`, `REACT-ASYNC-08`, `REACT-RSC-06`, `REACT-DOM-01`… | bug latente: race condition, tela branca, endpoint sem autorização |
| **Média** | demais `REACT-*` do satélite (estrutura, performance, formulários, refs) | corrigível no mesmo PR |
| **Baixa** | preferência sem ID | **não é achado** — ver o corte, abaixo |

Uma violação `REACT-PURE-*` ou `REACT-HOOK-*` tem precedência sobre qualquer preferência
estética. Não proponha refatoração cosmética em cima de código que viola pureza — reporte
a violação primeiro.

---

## Formato de um achado

Quatro partes, sempre. O formato vem de [[React.js]] § 7 ("Como citar").

```
`ID-DA-REGRA` — arquivo:linha
<o que está errado, uma frase>
Correção: <mudança concreta, não conselho genérico>
Ver [[Satélite correspondente]].
```

Exemplo real:

```
`REACT-PAT-01` — src/features/cart/Cart.tsx:24
`total` é mantido em useState e sincronizado por useEffect a partir de `items`.
Correção: remover o estado e o Effect; calcular `const total = items.reduce(...)` no render.
Ver [[React - Patterns]].
```

Regras do formato:

- **ID canônico obrigatório.** Consulte `mapa-de-ids.md` antes de escrever o ID. Os apelidos
  (`REACT-STATE-03`, `REACT-EFFECT-04`, `REACT-PAT-07`, `REACT-FORM-03`, `REACT-PAT-08`,
  `REACT-PAT-09`, `REACT-FORM-08`, `REACT-STATE-02`) existem para os satélites se sustentarem
  sozinhos e **não devem aparecer em revisão**.
- **`arquivo:linha` sempre.** Achado sem localização não é acionável.
- **Correção concreta.** "Considere refatorar" não é correção; "mova a chamada para o handler
  `onSubmit`" é.
- **Um link de satélite**, para quem for corrigir ler o raciocínio sem que a revisão o parafraseie.

---

## O corte: achado × opinião

**Achado sem ID de regra é opinião, não achado.**

Antes de reportar, verifique se existe ID em [[React.js]] § 6, § 6.1, § 6.2, em `mapa-de-ids.md`
ou na família do satélite. Três saídas:

1. **Existe ID** → é achado. Cite o canônico.
2. **Não existe ID, mas é antipadrão documentado** (`index` como `key`, Context com escrita
   frequente — ambos em [[React - Patterns]] § 8) → reporte citando a **seção**, nunca um ID
   inventado: "antipadrão de [[React - Patterns]] § 8".
3. **Não existe nem ID nem seção** → é preferência sua. Ou fica fora do relatório, ou vai numa
   seção separada rotulada **"Sugestões (sem regra)"**, nunca misturada aos achados.

**Nunca invente um ID.** Se uma API não aparece em [[React.js]] § 4, ela não foi verificada nesta
doc: consulte react.dev, **declare a limitação** e proponha atualizar a nota — não afirme
comportamento ([[React.js]] § 7, invariante 1).

---

## Estrutura do relatório

```markdown
## Revisão React — <alvo>

**Ambiente** (sonda 0): react <versão> · React Compiler <ativo|ausente> ·
rede de lint <ESLint|Biome+domínio react|AUSENTE> · StrictMode <ok|ausente>

### Bloqueante (n)
<achados>

### Alta (n)
<achados>

### Média (n)
<achados>

### Sugestões (sem regra)
<preferências, separadas>

### Não verificado
<APIs fora de React.js § 4, arquivos não lidos, o que a sonda não cobre>
```

Quatro obrigações de fechamento:

1. **Automatize o que dá.** A rede é `eslint-plugin-react-hooks` **ou** o domínio `react` do
   Biome (`linter.domains.react`); `<StrictMode>` revela quebras de pureza em desenvolvimento.
   Se o projeto não tem nenhum dos dois, isso é o **primeiro achado do relatório** — e em
   Biome vale conferir de verdade: `preset: recommended` não liga as regras de Hooks.
2. **Verifique se o stack já resolve.** Antes de sugerir a primitiva crua, confira as pontes de
   [[React.js]] § 8 — dado remoto é [[tanstack-query]], estado de URL é [[tanstack-router]].
3. **Ordene por severidade**, não por ordem de arquivo.
4. **Declare o que não foi verificado.** Silêncio sobre um arquivo não lido é lido como aprovação.

---

## Relacionados

- `sondas.md` — o que rodar antes
- `grade-de-varredura.md` — a ordem de leitura
- `mapa-de-ids.md` — canônicos e apelidos
- `exemplos/relatorio-de-pr.md` — um relatório inteiro, trabalhado
