# Roteiro das árvores de decisão

> Este arquivo **não copia** as árvores. Elas moram em [React.js](../../../../knowledge-base/docs/react-js.md) § 5 e mudam lá.
> Aqui está o que a árvore não diz: **qual** percorrer, qual é a pergunta que decide,
> onde o percurso costuma sair errado, e quando parar antes de chegar ao fim.

---

## Qual árvore, a partir do sintoma da tarefa

| A frase da tarefa contém… | Árvore em [React.js](../../../../knowledge-base/docs/react-js.md) § 5 | A pergunta que decide |
| --- | --- | --- |
| "guardar", "lembrar", "manter", "selecionado", "aberto/fechado" | *Preciso guardar um valor. Onde?* | **De onde vem o dado** — não "qual Hook" |
| "quando X mudar", "ao montar", "sincronizar", "listener", "timer" | *Preciso rodar um efeito colateral. Onde?* | **Isso responde a uma interação?** Se sim, acabou: é handler |
| "trava", "lento", "lag ao digitar", "lista grande" | *A UI trava durante uma atualização* | **Mediu?** Sem Profiler, o percurso nem começa |
| "carregar", "buscar", "await", "promise", "submeter" | *Preciso lidar com algo assíncrono* | **Onde o dado vive** — cache, servidor, ou lugar nenhum |

Se a tarefa contém duas frases dessas, ela é **duas** decisões. Percorra as duas árvores
separadamente, uma por dono de dado, antes de escrever qualquer linha.

---

## Os quatro erros de percurso

Cada um produz código que compila, roda, e está errado.

**1. Começar pela segunda pergunta da árvore de estado.**
A ordem é *qual mecanismo* → *em qual componente*. Escolher `useState` e só depois
perguntar onde ele mora garante que dado remoto e estado de URL virem estado local
(`REACT-PAT-03`, `REACT-PAT-10`). A primeira pergunta é sobre a **origem**.

**2. Tratar a árvore de efeito como classificação, não como filtro.**
Ela é desenhada para **eliminar** o Effect. Os dois primeiros ramos — interação, e
"existe sistema externo nomeável?" — descartam a maioria dos `useEffect` que se
escreve por hábito. Chegar em `useEffect` sem conseguir **nomear o sistema externo**
significa que o percurso foi pulado.

**3. Entrar na árvore de performance pelo passo 5.**
Os passos 0–3 são estado desnecessário, estado alto demais e composição. `memo` é
o passo 5, depois de medir (`REACT-PERF-01`). Com React Compiler ativo, memoização
manual é redundante (`REACT-PERF-02`) — confirme antes.

**4. Não conferir a ponte do stack.**
[React.js](../../../../knowledge-base/docs/react-js.md) § 8 lista o que **já está resolvido** neste stack: dado remoto, cache,
estado de URL, otimismo, validação de fronteira, formulário complexo, estado global
de escrita frequente. A primitiva crua onde a ponte existe não é simplicidade — é
regressão, e passa despercebida em revisão porque o código "funciona".

---

## Parar antes do fim: as quatro saídas curtas

| Se a resposta for… | Pare aqui | Não percorra o resto |
| --- | --- | --- |
| o dado vem do servidor | [TanStack Query](../../../../knowledge-base/docs/tanstack-query.md) ([React.js](../../../../knowledge-base/docs/react-js.md) § 8) | nenhum ramo de `useState` se aplica |
| o valor é derivável do que já existe | calcule no render | não há Hook a escolher |
| o estado deve sobreviver a refresh / ser compartilhável por link | search params do [TanStack Router](../../../../knowledge-base/docs/tanstack-router.md) | `useState` está fora de questão |
| o código responde a um clique, submit, tecla | event handler | não é Effect, não tem dependências |

Três das quatro saídas terminam **sem Hook nenhum**. Esse é o resultado esperado:
a árvore existe para reduzir a superfície, não para escolher entre APIs equivalentes.

---

## Depois de escolher a API

1. Confirme o **pacote de origem** em [React.js](../../../../knowledge-base/docs/react-js.md) § 3 — `react`, `react-dom`,
 `react-dom/client`. Metade dos erros de import morre aqui.
2. Descubra o **satélite** em [React.js](../../../../knowledge-base/docs/react-js.md) § 4 e abra **só ele**.
3. Se a API não está na § 4, ela **não foi verificada** nesta doc. Consulte react.dev,
 declare a limitação, e proponha atualizar a nota — não afirme comportamento
 ([React.js](../../../../knowledge-base/docs/react-js.md) § 7, invariante 1).

---

## Relacionados

- [React.js](../../../../knowledge-base/docs/react-js.md) § 5 — as árvores em si
- [React.js](../../../../knowledge-base/docs/react-js.md) § 8 — as pontes com o stack
- `habitos-de-ia.md` — o que o percurso evita, hábito por hábito
