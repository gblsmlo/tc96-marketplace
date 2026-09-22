# Hábitos automáticos que produzem violação

> Não são achados de revisão — são decisões a tomar **antes** de escrever.
> Cada linha nasce de um reflexo (de quem escreve React há anos, e de quem gera React
> a partir de exemplos antigos da internet). A coluna **Regra** é o ID canônico;
> confira em `mapa-de-ids.md` antes de citar.

---

## 1. Estado e dado

| Hábito | Por que falha | Em vez disso | Regra |
| --- | --- | --- | --- |
| `fetch` dentro de `useEffect` para carregar dados | não resolve race condition, cache, dedupe nem retry; e `<Suspense>` não funciona com ele | biblioteca de data fetching — [[TanStack Query]], via [[React.js]] § 8 | `REACT-EFFECT-06`, `REACT-ASYNC-03` |
| `useState` + `useEffect` para um valor calculável (total, percentual, item por id, lista filtrada) | dessincroniza e gera render extra | calcular no render, **no dono do estado**, e passar pronto aos filhos | `REACT-PAT-01` |
| Sincronizar prop em estado para "resetar" ao trocar de entidade | mesmo problema, com um render a mais | trocar a `key`: `<ProfileForm key={userId} />` | `REACT-PAT-01` |
| Guardar a resposta da API em `useState` como fonte de verdade | duas fontes de verdade; invalidação vira responsabilidade sua | cache da Query é a fonte; `useState` só para o que é do cliente | `REACT-PAT-03` |
| `useState` para filtro, aba, paginação, ordenação | não sobrevive a refresh, não é compartilhável por link, ignora o botão voltar | search params tipados do [[TanStack Router]] | `REACT-PAT-10` |
| Elevar estado à raiz "por precaução" | re-render global e componente-depósito | ancestral comum **mais próximo**, e pare ali | `REACT-PAT-02` |
| `setCount(count + 1)` quando o anterior importa | dois `set` no mesmo handler incrementam uma vez — estado é snapshot | forma updater: `setCount(c => c + 1)` | `REACT-STATE-01` |
| Booleanos paralelos (`isLoading` + `isError` + `data`) | admitem combinações impossíveis | union discriminada | `REACT-STATE-06` |
| Context para estado de escrita frequente | todo consumidor re-renderiza a cada tecla | store externa ([[Zustand]]) | `REACT-STATE-08` |

## 2. Efeitos

| Hábito | Por que falha | Em vez disso | Regra |
| --- | --- | --- | --- |
| Lógica de interação dentro de um Effect | roda fora do momento da interação e duplica em StrictMode | event handler | `REACT-EFFECT-05` |
| `eslint-disable` em `exhaustive-deps` para parar o loop | trata o sintoma; o loop é o Effect avisando que não deveria existir | remover o Effect, ou extrair a parte não reativa com `useEffectEvent` | `REACT-EFFECT-03` |
| `useEffect(async () => …)` | o callback passa a devolver Promise, e o React espera cleanup ali | declarar a função `async` **dentro** do Effect | `REACT-EFFECT-12` |
| Effect com subscription/timer/listener sem `return` | vaza entre renders e em StrictMode | cleanup que desfaz exatamente o setup | `REACT-EFFECT-01` |
| `useLayoutEffect` "para garantir que roda antes" | bloqueia o paint sem motivo | `useEffect`, a menos que haja medição de layout | `REACT-EFFECT-10` |

## 3. Composição e fronteiras

| Hábito | Por que falha | Em vez disso | Regra |
| --- | --- | --- | --- |
| Prop booleana nova a cada variação visual (`showFooter`, `hideHeader`) | a assinatura cresce sem limite e a combinação vira matriz | composição por `children`/slots | `REACT-PAT-04` |
| Quebrar arquivo grande em componentes por tamanho | fragmenta sem criar conceito; prop drilling aumenta | extrair só o que tem nome de domínio | `REACT-PAT-05` |
| Um Error Boundary só na raiz | qualquer erro vira tela branca | boundary no nível da feature | `REACT-PAT-06` |
| `<Suspense>` sem Error Boundary em fronteira de dados | a falha da promise não tem onde parar | boundary de erro ao lado de todo boundary de espera | `REACT-ASYNC-08` |
| Boundary sem botão de retry/reset | o usuário fica preso no fallback | caminho de recuperação explícito | `REACT-ASYNC-11` |
| Lançar erro esperado (validação, 404 de negócio, 403) para o boundary | boundary é para o inesperado | erro esperado é estado da UI / retorno da action | `REACT-ASYNC-09` |
| `index` como `key` em `.map()` | o estado interno gruda no índice errado ao reordenar ou remover | id estável do domínio; `index` só em lista estática, sem estado nas linhas | sem ID — [[React - Patterns]] § 8 |
| `fallback` de tamanho arbitrário | layout shift no momento da troca | fallback com a área aproximada do conteúdo real | `REACT-ASYNC-02` |

## 4. Performance

| Hábito | Por que falha | Em vez disso | Regra |
| --- | --- | --- | --- |
| `useMemo`/`useCallback`/`memo` "por precaução" | custo sem benefício comprovado | medir no Profiler e percorrer os passos 1–3 da árvore antes | `REACT-PERF-01` |
| Memoizar manualmente num projeto com React Compiler | redundante | confirmar se o compiler está ativo antes de qualquer memoização | `REACT-PERF-02` |
| `memo` num componente que recebe objeto/função criados inline | a igualdade rasa nunca dá true; só adiciona custo | estabilizar as props, ou não usar `memo` | `REACT-PERF-03` |
| `useMemo` para garantir identidade obrigatória | o cache pode ser descartado a qualquer momento | `useRef` quando a identidade é semanticamente necessária | `REACT-PERF-05` |
| Memoizar linha de uma lista de milhares de itens | o gargalo é volume de nós, não cálculo | virtualização ou paginação | `REACT-PERF-09` |
| `useTransition` para controlar campo de texto | transições não servem para valor de input | `useDeferredValue` no consumidor pesado | `REACT-PERF-10` |

## 5. Refs, DOM e entrypoint

| Hábito | Por que falha | Em vez disso | Regra |
| --- | --- | --- | --- |
| `forwardRef` em código novo | desnecessário desde o React 19 — `ref` é prop | receber `ref` como prop comum | `REACT-REF-03` |
| Ler ou escrever `ref.current` no corpo do render | viola pureza | handlers e Effects | `REACT-REF-01` |
| Guardar em ref algo que deve redesenhar a tela | a UI não atualiza | estado | `REACT-REF-02` |
| Portal e "pronto, é um modal" | foco, `Esc`, `role`/`aria-modal` e devolução de foco continuam sendo seus | acessibilidade explícita no portal | `REACT-REF-07` |
| `createRoot` sobre HTML vindo do servidor | descarta o HTML e perde o SSR | `hydrateRoot` | `REACT-DOM-01` |
| Ramificar o render em `typeof window` | divergência de hidratação | renderizar igual nos dois lados e ajustar em Effect | `REACT-DOM-03` |
| Remover `<StrictMode>` porque "roda duas vezes" | está revelando um bug de pureza, não causando | consertar a impureza | `REACT-DOM-06` |

## 6. Formulários, Actions e servidor

| Hábito | Por que falha | Em vez disso | Regra |
| --- | --- | --- | --- |
| `e.preventDefault()` com `<form action>` | o React já previne; isso quebra a Action | não chamar | `REACT-FORM-01` |
| Campo sem `name`, lido por estado | `FormData` é indexado por `name` | `name` em todo campo que a Action lê | `REACT-FORM-02` |
| `useFormStatus` no mesmo componente que renderiza o `<form>` | ele lê o `<form>` **ancestral** | chamar num descendente (o botão de submit) | `REACT-FORM-05` |
| `useOptimistic` sobre dado que vive no cache da Query | duas fontes de verdade divergindo | otimismo pertence à mutation, com snapshot e rollback | `REACT-FORM-07` |
| `'use client'` no topo do arquivo raiz | tudo importado a partir dali vai para o bundle | empurrar a fronteira para baixo | `REACT-RSC-03` |
| Client Component importando Server Component | a fronteira não permite | receber como `children`/props | `REACT-RSC-04` |
| Passar função ou instância de classe pela fronteira | props precisam ser serializáveis | dado serializável, ou Server Function | `REACT-RSC-05` |
| Confiar na validação do cliente numa Server Function | é endpoint público | autenticar, validar e autorizar na própria fronteira | `REACT-RSC-06` |
| `cache` como cache entre requests | o escopo é um passe de render | cache de verdade na camada de dados | `REACT-RSC-08` |

## 7. Hooks customizados

| Hábito | Por que falha | Em vez disso | Regra |
| --- | --- | --- | --- |
| Extrair para Hook lógica pura sem estado | é função comum, testável sem renderizar | função comum | `REACT-HOOK-05` |
| Nomear pela implementação (`useEventListener`) | o nome não diz a intenção da feature | `useOnlineStatus` | `REACT-HOOK-04` |
| Hook que devolve dez coisas | está escondendo um componente | retorno pequeno e explícito | `REACT-HOOK-06` |
| Chamar Hook de dentro de função comum ou de callback | as regras dos Hooks são herdadas | componente ou outro Hook | `REACT-HOOK-02`, `REACT-HOOK-07` |
| Hook guardado em variável ou passado como argumento | Hooks não são valores | chamar diretamente | `REACT-CALL-02` |

---

## Relacionados

- `mapa-de-ids.md` — onde cada ID está declarado
- `autoverificacao.md` — a segunda passada, sobre esta tabela
- [[React.js]] § 6.1 — as regras críticas que viajam com o caminho mínimo
