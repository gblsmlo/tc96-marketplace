---
titulo: React - Patterns
Link: https://react.dev/learn
tags:
  - react
  - patterns
  - architecture
  - agent-context
source: "react.dev (Learn + Reference) e Zettels de frontend do vault"
verificado-em: 2026-08-14
---

# React — Patterns

> Estrutura de **decisão**: onde mora o estado, o que compor, o que extrair, onde traçar fronteiras. Não repete a superfície de API — para assinatura de Hook, vá a [React - Hooks](react-hooks.md); para o mapa completo da API, [React.js](react-js.md) § 4.
>
> **Papel desta nota no vault:** ela é a ponte entre a referência oficial e os Zettels conceituais que já existem aqui. Cada padrão aponta para o Zettel que desenvolve a ideia — o Zettel é a fonte do raciocínio, esta nota é o índice acionável.

Entrada: [React.js](react-js.md) · Base normativa: [React - Rules of React](react-rules-of-react.md)

---

## 1. O eixo que organiza tudo

Padrões de React se resolvem em três perguntas, nesta ordem:

1. **De quem é este dado?** — decide colocação de estado
2. **Quem fornece o conteúdo variável?** — decide composição
3. **Onde uma falha ou uma espera deve parar?** — decide fronteiras

A ordem importa: composição escolhida antes de decidir a posse do dado quase sempre gera prop drilling.

---

## 2. Posse e colocação de estado

### Classificar antes de posicionar

| Natureza do dado | Onde vive | Zettel |
| --- | --- | --- |
| Derivável do que já existe | **em lugar nenhum** — calcule no render | |
| Local a um componente | `useState` / `useReducer` nele | |
| Compartilhado por irmãos | no ancestral comum mais próximo (*lifting*) | |
| Amplo, leitura frequente, escrita rara | Context | |
| Amplo, escrita frequente | store externa | |
| Vindo do servidor | não é estado de cliente | |
| Persistido no browser | precisa versão e validação | |

**A regra que mais economiza código:** antes de criar estado, pergunte se o valor é derivável. Percentual, total, disponibilidade de botão, item selecionado a partir de um id — quase sempre são derivados. Ver — traz o par antes/depois de lista + campo de busca.

### Onde calcular o derivado quando dois irmãos o consomem

Calcule **uma vez, no dono do estado**, e passe o resultado. Repetir o mesmo `filter` em cada filho duplica trabalho e permite que os dois divirjam.

```tsx
function Tela() {
  const [filtro, setFiltro] = useState('')
  const [produtos, setProdutos] = useState<Produto[]>([])

  // calculado uma vez, no dono do estado
  const visiveis = produtos.filter((p) => p.nome.includes(filtro))
  const total = visiveis.reduce((s, p) => s + p.preco, 0)

  return (
    <>
      <CampoFiltro value={filtro} onChange={setFiltro} />
      <ListaProdutos produtos={visiveis} />
      <Resumo quantidade={visiveis.length} total={total} />
    </>
  )
}
```

Os filhos recebem dados prontos e não sabem que existe um filtro — continuam reutilizáveis. Só memoize (`useMemo`) se o cálculo se provar caro sob medição (`REACT-PERF-01`).

### Filtro, aba, paginação: isso pertence à URL?

Pergunta que a maioria do código pula. O estado pertence à URL quando precisa **sobreviver a um refresh**, **ser compartilhável por link** ou **funcionar com o botão voltar**. Filtro de busca, aba ativa, página, ordenação e faixa de datas quase sempre atendem a pelo menos um critério.

Quando pertence, a fonte de verdade é a rota — no meu stack, os search params tipados do [TanStack Router](tanstack-router.md) — e não `useState`. Estado efêmero de UI (menu aberto, hover, foco, rascunho de campo) fica em `useState`.

| ID | Regra |
| --- | --- |
| `REACT-PAT-10` | Estado que precisa sobreviver a refresh, ser compartilhável por link ou responder ao botão voltar **MUST** viver na URL, não em `useState`. |

| ID             | Regra                                                                                                        |
| -------------- | ------------------------------------------------------------------------------------------------------------ |
| `REACT-PAT-01` | Valor derivável de props/estado existentes **NEVER** vira estado próprio.                                    |
| `REACT-PAT-02` | Estado **MUST** viver no ancestral comum mais próximo dos componentes que o leem — nem acima, nem duplicado. |
| `REACT-PAT-03` | Dado remoto **NEVER** é armazenado em `useState` como fonte de verdade.                                      |

### Colocação: subir o mínimo

Elevar estado até a raiz "por precaução" custa re-renders na árvore inteira e transforma o componente de topo em depósito. Suba até o ancestral comum e pare ali. Quando subir muito começar a doer como prop drilling, a resposta é composição (§ 3) antes de Context.

### Resetar estado com `key`

Trocar a `key` de um componente faz o React descartar a instância e criar outra do zero — o modo idiomático de resetar estado quando a identidade lógica muda.

```tsx
// Ao trocar de usuário, o formulário reinicia por completo
<ProfileForm key={userId} userId={userId} />
```

Isso substitui o antipadrão de sincronizar props em estado dentro de um `useEffect`.

---

## 3. Composição

O padrão central do React, e o que mais reduz props booleanas de configuração. Desenvolvido em.

### Children e slots

Um componente controla estrutura e comportamento comuns; o consumidor fornece o conteúdo variável.

```tsx
type CardProps = {
  children: React.ReactNode
  footer?: React.ReactNode
}

function Card({ children, footer }: CardProps) {
  return (
    <section>
      {children}
      {footer && <footer>{footer}</footer>}
    </section>
  )
}
```

O sinal de que a composição está faltando: props do tipo `showFooter`, `footerButtonLabel`, `hideHeader` acumulando na assinatura. Cada nova variação vira uma prop; com composição, vira conteúdo.

### Composição contra prop drilling

Passar JSX como children evita repassar props por níveis intermediários que não as usam — geralmente antes de recorrer a Context.

```tsx
// Em vez de Layout repassar `user` para Header repassar para Avatar:
<Layout header={<Header avatar={<Avatar user={user} />} />}>
  <Content />
</Layout>
```

### Quando extrair um componente

Critério do vault, em: extraia quando o componente representa um conceito, se repete, isola comportamento relevante, ou reduz a carga cognitiva do pai. **Separar cada bloco visual em um arquivo não é bom projeto** — fragmentação excessiva aumenta navegação e passagem de props.

Para variantes visuais.

| ID | Regra |
| --- | --- |
| `REACT-PAT-04` | Variação de conteúdo **MUST** ser resolvida por composição antes de nova prop booleana. |
| `REACT-PAT-05` | Extração de componente **MUST** ter justificativa conceitual, não apenas tamanho de arquivo. |

---

## 4. Controlado × não controlado

| | Controlado | Não controlado |
| --- | --- | --- |
| Fonte de verdade | estado do pai | DOM / estado interno |
| Uso | quando o pai precisa ler ou reagir a cada mudança | quando só o valor final importa |
| Custo | re-render por caractere | menos flexível |

Padrão prático: um componente pode oferecer os dois modos — prop `value` controlada, `defaultValue` não controlada — mas **nunca alternar entre eles em runtime**.

Escala de escolha para formulários, do mais simples ao mais complexo:

| Formulário | Ferramenta |
| --- | --- |
| Poucos campos, validação no submit | campos não controlados + `<form action>` e `useActionState` — [React - Formulários e Actions](react-formularios-e-actions.md) |
| Validação por campo enquanto digita, arrays de campos, wizard, dependências entre campos | React Hook Form — |

Nos dois casos a validação de schema é Zod. Actions nativas não são "para brinquedo": elas cobrem o caso simples bem, e é o caso mais comum.

---

## 5. Extração de lógica

### Hook customizado × função pura × componente

```
A lógica precisa de estado ou de Hooks do React?
├── NÃO → função comum. Testável sem renderizar. Prefira sempre que possível.
└── SIM
    ├── Ela também produz UI própria? → componente
    └── Só coordena estado/sincronização? → Hook customizado
```

Detalhe em e nas regras `REACT-HOOK-04..07` em [React - Hooks](react-hooks.md).

### O que não extrair

Lógica usada uma vez, sem fronteira de sincronização, não ganha nada em virar Hook — só ganha um arquivo e uma indireção. O gatilho de extração é repetição real ou uma fronteira com sistema externo.

---

## 6. Fronteiras

Fronteiras são onde a árvore decide o que fazer com **falha**, **espera** e **ambiente**. Defini-las é decisão de arquitetura, não detalhe.

### Fronteira de falha — Error Boundary

Isola uma falha de render para que ela não derrube a aplicação inteira. Desenvolvido em.

Posicione no **nível da feature**, não só na raiz: um boundary único na raiz transforma qualquer erro em tela branca. Distinga erro esperado (estado da UI) de inesperado (boundary), conforme.

### Fronteira de espera — `<Suspense>`

Define qual pedaço da UI mostra fallback enquanto algo carrega. Colocada muito alto, some com a página inteira por um dado secundário. Ver [React - Suspense e Assincronia](react-suspense-e-assincronia.md).

### Fronteira de ambiente — `'use client'`

Marca onde o código passa a ir para o bundle do cliente. Tudo importado a partir dali vai junto. O padrão que preserva o benefício de RSC é **empurrar a fronteira para baixo**: Server Components buscam dados e passam resultado renderizado como children para pequenos Client Components interativos. Ver [React - Server Components e Diretivas](react-server-components-e-diretivas.md).

### Fronteira de confiança — servidor

Uma Server Function roda no servidor, mas continua recebendo entrada não confiável: valide, autentique e autorize sempre..

| ID             | Regra                                                                                                          |
| -------------- | -------------------------------------------------------------------------------------------------------------- |
| `REACT-PAT-06` | Error Boundaries **MUST** existir no nível da feature, não apenas na raiz.                                     |
| `REACT-PAT-07` | Erro esperado **NEVER** é lançado para um boundary — é estado da UI.                                           |
| `REACT-PAT-08` | A fronteira `'use client'` **MUST** ficar o mais baixo possível na árvore.                                     |
| `REACT-PAT-09` | Toda função de servidor **MUST** validar a entrada na própria fronteira, independente da validação no cliente. |

---

## 7. Fluxo de dados

Dados descem por props; mudanças sobem por callbacks. Essa direção única é o que torna a origem de qualquer mudança rastreável — desenvolvido em.

Consequência prática para agentes: quando um componente precisa alterar algo que não possui, a resposta **não** é uma ref para o pai nem um evento global. É elevar o estado (§ 2) ou compor (§ 3).

Organização de arquivos por capacidade, não por tipo técnico:. Separação por origem do dado:.

---

## 8. Antipadrões

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| Estado espelhando props via `useEffect` | dessincroniza e gera render extra | calcule no render, ou `key` para resetar |
| `useEffect` para buscar dados | race conditions, waterfalls, sem cache | TanStack Query |
| Prop booleana por variação de conteúdo | assinatura cresce sem limite | composição por children/slots |
| Context para estado de escrita frequente | re-renderiza todos os consumidores | store externa · |
| Estado elevado à raiz "por precaução" | re-render global, componente-depósito | ancestral comum mais próximo |
| Um Error Boundary só na raiz | qualquer erro vira tela branca | boundary por feature |
| `'use client'` no topo da árvore | anula o benefício de RSC | empurrar a fronteira para baixo |
| Mutar props ou estado direto | viola `REACT-PURE-03`, render inconsistente | criar novo valor |
| `index` como `key` em lista reordenável | estado gruda no índice errado | id estável do domínio |

O último merece exemplo, porque é o erro mais silencioso da lista:

```tsx
// ERRADO — ao remover o item 0, o estado interno de cada linha desloca
{items.map((item, i) => <Row key={i} item={item} />)}

// CERTO
{items.map((item) => <Row key={item.id} item={item} />)}
```

`index` como key só é aceitável quando a lista é estática, nunca reordenada e sem estado interno nas linhas.

---

## 9. Uso por um agente

Ao receber uma tarefa de estrutura ("onde coloco isso", "como organizo", "isso deveria ser um hook"), responda pela ordem da § 1 e cite a regra:

> `REACT-PAT-01` — `total` é derivável de `items`. Não crie estado; calcule no render.
> Contexto conceitual:.

Ao revisar código, a tabela da § 8 é a checklist. Ao propor refatoração, aponte o Zettel correspondente — ele carrega o raciocínio, esta nota carrega só a decisão.

---

## Relacionados

- [React.js](react-js.md) — hub, mapa da API e árvores de decisão
- [React - Hooks](react-hooks.md) — superfície de API por Hook
- [React - Rules of React](react-rules-of-react.md) — base normativa
- [Frontend roadmap](../pages/frontend-roadmap.md) — trilha de estudos que consome estas notas
### Zettels conectados — abra pelo que cada um entrega

Não abra todos: a regra de economia de contexto do hub continua valendo. A glosa diz o que você ganha.

| Zettel | O que entrega |
| --- | --- |
| | par antes/depois de lista + campo de busca. O mais útil desta lista |
| | critério de extração e o antes/depois de props booleanas → slots |
| | pureza com exemplo de mutação de array externo no render |
| | define *lifting* e por que a direção única torna a mudança rastreável |
| | quando extrair um Hook e quando não |
| | o conceito de boundary — a **implementação** está em [React - Suspense e Assincronia](react-suspense-e-assincronia.md) |
| | por que validar no servidor mesmo validando no cliente |
| | panorama; ancorado num Upload Widget, contexto alheio a outras tarefas |
| | metade é Zustand; abra só se o estado for de store |

## Fontes consultadas

- [React — Learn](https://react.dev/learn) e [Reference](https://react.dev/reference/react), verificados em 2026-08-14
- Zettels de frontend do vault, indexados em [Frontend roadmap](../pages/frontend-roadmap.md)
