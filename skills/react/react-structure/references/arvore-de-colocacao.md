# Onde este arquivo mora

> A árvore e as cinco perguntas vêm de [Feature-Based Architecture](../../../../knowledge-base/pages/feature-based-architecture.md) § 3, § 4 e § 10.
> Aqui está o percurso e o que costuma sair errado nele — o texto normativo mora na nota.

---

## As cinco perguntas antes de criar uma feature

Ordem normativa. Responda **por escrito**, uma frase cada, antes do primeiro `mkdir`.

| # | Pergunta | Se a resposta travar |
| --- | --- | --- |
| 1 | Isto é um **domínio**? | sem vocabulário próprio de produto, não é feature — pare, o problema é de definição |
| 2 | O domínio **já existe**? | feature nova exige capacidade nova, não tela nova |
| 3 | O dado é **remoto**? | se sim, `api/` com `queryOptions` — nunca `stores/` |
| 4 | Isto é **público**? | só entra no barrel o que outra camada consome de fato |
| 5 | **Quem** vai importar isto? | outra feature → confirme `REACT-ARCH-05` e registre o contador de `REACT-ARCH-08` |

**A exceção da pergunta 5:** quando a própria especificação já nomeia **três** consumidores,
o terceiro não é previsão — crie direto em `features/core/` (§ 4, "Capacidade que nasce
compartilhada").

Não abra as sete subpastas de uma vez. Critério em § 3.

---

## A árvore

Percorra na ordem; a primeira resposta "sim" decide.

```
Ele conhece vocabulário de alguma capacidade do produto?
├─ NÃO → é genérico. Qual tipo?
│ ├─ componente visual.......... components/ui/ ou components/layout/
│ ├─ hook........................ hooks/
│ ├─ infraestrutura, formatador.. libs/
│ └─ tipo/contrato............... types/
│ ⚠ REACT-ARCH-06: se ele precisar importar de @features/ para
│ funcionar, ele NÃO é genérico. Volte e trate como domínio.
│ Se ele só precisa EXIBIR domínio (um cabeçalho com um seletor
│ de moeda), continua genérico: receba por slot e componha no
│ shell. Ver § 4, "Camada genérica que precisa exibir domínio".
│
└─ SIM → é domínio. Quantas capacidades o consomem?
 ├─ 1......... features/<capacidade>/, privado
 ├─ 2......... continua onde está; a segunda importa o barrel
 │ (REACT-ARCH-05). Não duplique, não extraia.
 └─ 3 ou +.... features/core/<capacidade>/ e corte as arestas
 diretas (REACT-ARCH-08)
```

Dentro da feature, o subdiretório sai do **tipo** do arquivo — `api/`, `components/`,
`hooks/`, `stores/`, `types/`, `utils/`, conforme § 3. Teste fica colocalizado ao lado do
arquivo testado, nunca no barrel.

---

## O erro mais comum: confundir três movimentos

`REACT-ARCH-08` responde *quando criar módulo compartilhado* — **não** *se posso importar*.
A tabela de § 4 ("Importar, duplicar e extrair são três movimentos diferentes") desempata:

| Movimento | Quando | Custo de errar |
| --- | --- | --- |
| **importar** o barrel da outra feature | 2 consumidores | nenhum; é o caminho normal (`REACT-ARCH-05`) |
| **duplicar** | quase nunca — só quando as duas cópias vão divergir de propósito | duas verdades que ninguém sincroniza |
| **extrair** para `features/core/` | 3 consumidores reais, contados | extração prematura vira `libs/` que conhece domínio (`REACT-ARCH-06`) |

---

## Quando **não** usar esta estrutura

§ 9 da nota-fonte. App de domínio único não precisa de fatia vertical, e impor a estrutura
nele é o antipadrão desta skill. Confira § 9 **antes** de decidir que algo é overkill — e
antes de propor a migração de um repositório inteiro.

---

## Relacionados

- [Feature-Based Architecture](../../../../knowledge-base/pages/feature-based-architecture.md) § 3, § 4, § 9, § 10 — a fonte
- `varredura-de-imports.md` — auditar o que já está colocado
- `mapa-de-ids.md` — ID → severidade → quem faz valer
