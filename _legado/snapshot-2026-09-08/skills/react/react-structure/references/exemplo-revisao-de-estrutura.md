# Exemplo trabalhado — revisão de estrutura num PR

PR: *"extrai formatação de fatura para reuso e adiciona a tela de cobranças"*.

---

## Passo 1 — sondas antes de abrir arquivo

```
$ bash scripts/sondas-imports.sh src

== 0. Enforcement
   -- biome.json: AUSENTE                      ← já é achado, e é o primeiro
   -- aliases: tsconfig.json 4 | vite.config.ts 4 | vitest.config.ts sem alias
== 1. Direção invertida
   src/libs/formatar-fatura.ts:3  from '@features/faturas'
== 2. Deep import
   src/routes/cobrancas.tsx:2     from '@features/faturas/components/linha-fatura'
== 3. Alias próprio dentro da feature
   src/features/cobrancas/components/lista.tsx:1  from '@features/cobrancas'
== 4. Barrel com lógica
   src/features/cobrancas/index.ts
== 6. Convenção de nome
   src/features/cobrancas/components/ListaCobrancas.tsx
```

Seis minutos. Nenhum é achado ainda — são candidatos com localização.

## Passo 2 — leitura, e o que ela muda

`libs/formatar-fatura.ts` importa `@features/faturas` para ler o tipo `Fatura` e a tabela
de impostos. Confirma `REACT-ARCH-06`: a camada genérica deixou de ser genérica.

`features/cobrancas/` tem **uma** tela e nenhum vocabulário próprio — "cobranças" aqui é
o nome do botão, não de uma capacidade. Isso a sonda não vê: é `REACT-ARCH-01`, e **muda
o resto do relatório**, porque se a feature não deveria existir, os achados 3, 4 e 6
dentro dela deixam de ser corrigíveis onde estão.

## Passo 3 — o relatório

```markdown
## Revisão de estrutura — PR #91 (cobranças)

**Enforcement** (sonda 0): biome.json **AUSENTE** · alias ausente em vitest.config.ts

### Crítica (3)

`REACT-ARCH-01` — src/features/cobrancas/
"Cobranças" é uma tela de faturas, não uma capacidade com vocabulário próprio: não há
entidade, api/ nem store que não sejam de faturas.
Correção: mover o conteúdo para src/features/faturas/components/ e apagar a feature;
a rota compõe o que já existe.
Ver [[Feature-Based Architecture]] § 3.

`REACT-ARCH-06` — src/libs/formatar-fatura.ts:3
Regra de domínio dentro da camada genérica; libs/ deixa de ser reutilizável.
Correção: mover para src/features/faturas/utils/formatar-fatura.ts e exportar no barrel
se algum consumidor externo precisar.
Ver [[Feature-Based Architecture]] § 6.

`REACT-ARCH-05` — src/routes/cobrancas.tsx:2
Deep import em @features/faturas/components/linha-fatura.
Correção: importar pelo barrel — from '@features/faturas'.
Ver [[Feature-Based Architecture]] § 4.

### Alta (1)

`REACT-ARCH-08` — src/libs/formatar-fatura.ts:1
A extração foi feita com **um** consumidor. A regra do terceiro consumidor não disparou.
Correção: a mesma do REACT-ARCH-06 — devolver à feature dona. Extrair de novo só quando
houver três importadores reais.
Ver [[Feature-Based Architecture]] § 4.

### Média (1)

`REACT-ARCH-12` — src/features/cobrancas/components/ListaCobrancas.tsx
Nome em PascalCase; a convenção é kebab-case em arquivo e diretório.
Correção: renomear para lista-cobrancas.tsx no mesmo commit em que o arquivo se mudar.
Ver [[Feature-Based Architecture]] § 4.

### Não reportado, e por quê

- `REACT-ARCH-04` (alias próprio) e `REACT-ARCH-03` (lógica no barrel) estavam dentro de
  `features/cobrancas/`, que sai inteira pelo REACT-ARCH-01. Corrigi-los onde estão seria
  trabalho jogado fora.
- Tamanho de `linha-fatura.tsx` (190 linhas) não tem ID — vai para Sugestões, se for o caso.

### Fechamento

Sem `biome.json`, `REACT-ARCH-04`, `-05`, `-06`, `-07` e `-10` dependem de revisão humana e
voltam no próximo PR. Ligar as regras de § 7 é o item de maior retorno — mais do que
qualquer achado individual acima.
```

## O que este exemplo demonstra

| Decisão | Onde está a regra |
| --- | --- |
| a leitura reclassificou o relatório inteiro (`REACT-ARCH-01`) | `varredura-de-imports.md` § *O que a sonda não pega* |
| dois achados dentro da feature condenada **não** foram reportados | § 6 — pare quando um achado invalida o seguinte |
| o mesmo arquivo saiu com `-06` **e** `-08`, que são defeitos diferentes | § 4 — importar × duplicar × extrair |
| a ausência de lint virou o fechamento, não nota de rodapé | § 7 |
| o achado de estrutura vem antes do de interior | esta skill, `## Quando usar` |
