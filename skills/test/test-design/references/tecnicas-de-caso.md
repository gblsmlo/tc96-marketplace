# Derivar os casos

> Passo 4. A árvore é a § 4.3 de [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md). Quando há entrada a exercitar,
> esta é a etapa de maior retorno da skill.

---

## A técnica, pela forma da entrada

| A entrada tem… | Técnica | Regra |
| --- | --- | --- |
| faixa ou limite de tamanho | **análise de valor limite** | `TS-TEC-01` |
| classes de valor | partição de equivalência, **incluindo as inválidas** | `TS-TEC-02` |
| combinação de condições | tabela de decisão | — |
| dependência do estado anterior | transição de estado, **incluindo as inválidas** | `TS-TEC-04` |
| muitos parâmetros independentes | pairwise, ou redução por risco | `TS-TEC-09` |

**Se for para aplicar uma técnica, é valor limite.** Ela converte "testei com 5" em quatro
casos que pegam off-by-one, `>` × `>=` e o zero esquecido.

---

## As fronteiras não numéricas — as mais esquecidas

| Fronteira | Casos |
| --- | --- |
| coleção | **vazia**, um elemento, muitos, o máximo (`TS-TEC-03`) |
| string | vazia, um caractere, o máximo, acima |
| texto | espaço nas pontas, acento, emoji, RTL |
| opcional | ausente, `null`, presente e vazio |
| data | fim de mês, ano bissexto, virada de fuso, horário de verão |
| número | zero, negativo, precisão de ponto flutuante |

**Coleção vazia é a fronteira que mais quebra UI** — e é o estado "vazio" que `TS-TIPO-02`
exige.

---

## Os cinco estados de um fluxo

Carregando · vazio · sucesso · erro · recuperação (`TS-TIPO-02`).

Cobrir só o caminho feliz é a omissão mais comum. Os estados não-felizes são **baratos no
nível de componente** — é onde eles custam menos e valem mais (`storybook-story`).

Decidir "não cobrir" é resposta válida; **não decidir** é a lacuna.

---

## Relacionados

- [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) — a fonte
- [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/docs/teste-de-software-tipos-e-atributos-de-qualidade.md) — os cinco estados e os atributos
- `substituicao.md` — o passo seguinte, quando houver dependência
