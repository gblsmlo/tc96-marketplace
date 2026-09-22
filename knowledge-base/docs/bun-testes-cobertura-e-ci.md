---
titulo: Bun - Testes - Cobertura e CI
Link: https://bun.com/docs/test/code-coverage
tags:
 - bun
 - testing
 - ci
 - agent-context
source: "Documentação oficial — https://bun.com/docs/test/code-coverage, /reporters"
verificado-em: 2026-08-20
---

# Bun - Testes - Cobertura e CI

> Cobertura como portão, e as **duas condições silenciosas** que fazem o portão não fechar · reporters (`text`, `lcov`, `dots`, `junit`) e o que cada um serve · anotações automáticas no GitHub Actions · o workflow completo, com `--parallel`, `--shard` e `--changed` · onde `tsc --noEmit` entra.
>
> **Não cobre:** flags de execução e `bunfig.toml` em geral ([Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md)) · o que `--parallel`/`--shard` fazem com o isolamento ([Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 4 e § 7) · instalação de dependências em CI ([Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md)).

Entrada: [Bun - Testes](bun-testes.md) · Base normativa: [Bun - Testes](bun-testes.md) § 6 · Família: `BUN-TEST-*` (esta nota é dona de `27`, `28`, `29`)

---

## 1. Conceito: cobertura detecta ausência, não atesta presença

Cobertura responde a uma pergunta estreita e útil: **que linhas nenhum teste executou.** Ela não responde se o que executou foi verificado — um arquivo pode ter 100% de cobertura com zero `expect`, porque `import`, chamada e execução contam.

Daí os dois usos legítimos, e um ilegítimo:

- **Legítimo — encontrar o que ninguém testou.** Rodar `--coverage` e ler as linhas vermelhas de um módulo novo é o uso que paga.
- **Legítimo — impedir regressão de escopo.** Um limiar que falha o build impede que um PR grande acrescente 800 linhas sem nenhum teste.
- **Ilegítimo — número como meta.** Cobertura perseguida como número produz teste que executa sem verificar: o pior tipo, porque parece proteção e não é.

O limiar só vale se tiver sido **escolhido a partir da suíte real** — rode `--coverage`, veja o número de hoje, e coloque o portão um pouco abaixo dele. Copiar `0.9` de outro projeto produz uma de duas coisas: build vermelho no dia da adoção, ou portão que nunca é acionado.

---

## 2. Rodar e reportar

```bash
bun test --coverage
bun test --coverage --coverage-reporter=lcov
bun test --coverage --coverage-reporter=text --coverage-reporter=lcov --coverage-dir=coverage
```

| Reporter | O que produz | Para quê |
| --- | --- | --- |
| `text` | resumo no console | leitura humana, e — fora de `--parallel` — **a checagem de limiar** (§ 3) |
| `lcov` | `lcov.info` no `coverageDir` | Codecov, Coveralls, GitLab, extensão de editor |

Default: `["text"]`. Configuração persistente:

```toml
[test]
coverage = true
coverageReporter = ["text", "lcov"]
coverageDir = "coverage"
coverageSkipTestFiles = true # default
coveragePathIgnorePatterns = ["**/*.gen.ts", "src/mocks/**"]
```

**Excluído do relatório por default:** `node_modules`, arquivos carregados por loaders não-JS/TS (`.css`, `.txt`, salvo loader customizado), e os próprios arquivos de teste (`coverageSkipTestFiles = true`). `coveragePathIgnorePatterns` acrescenta exclusões por glob.

`coverageIgnoreSourcemaps` (default `false`) desliga o mapeamento por sourcemap — a fonte diz que raramente se quer isso fora de caso avançado. Num projeto TypeScript, ligar essa chave faz o relatório apontar linhas do código transpilado.

---

## 3. `coverageThreshold`: o portão, e as duas condições que o desligam em silêncio

```toml
[test]
coverageThreshold = 0.9 # escalar: linhas e funções
```

```toml
[test]
coverageThreshold = { lines = 0.9, functions = 0.85 } # por métrica
```

Valores são **fração** (`0.9`), não percentual (`90`). Declarar qualquer chave liga a falha: `bun test --coverage` sai com código diferente de zero quando a cobertura fica abaixo do limiar.

E aqui estão as duas armadilhas que transformam o portão em enfeite — as duas verificadas na fonte, as duas silenciosas:

**1. `statements` é aceito e não é aplicado.** A chave não causa erro de configuração; ela simplesmente não é verificada. Um projeto cujo portão é `coverageThreshold = { statements = 0.95 }` não tem portão nenhum, e nada o avisa. O que é aplicado é `lines` e `functions`.

**2. Fora de `--parallel`, a checagem de limiar só roda com o reporter `text` habilitado.** A fonte declara: execuções que usam apenas `--coverage-reporter=lcov` *"currently exit 0 regardless"*. É a configuração de CI mais natural do mundo — quem só quer o arquivo para o Codecov desliga o `text` — e ela desliga o portão junto.

```toml
# a forma segura: text SEMPRE presente, lcov ao lado quando precisa
[test]
coverage = true
coverageReporter = ["text", "lcov"]
coverageThreshold = { lines = 0.85, functions = 0.85 }
```

Sob `--parallel`, o coordenador funde a cobertura dos workers e avalia o limiar no resultado fundido — é a única configuração em que a dependência do reporter `text` não se aplica. Como a recomendação de CI desta doc **é** `--parallel`, o efeito prático é que os dois caminhos ficam corretos; o risco fica em quem roda cobertura localmente ou num job sequencial.

| ID | Regra |
| --- | --- |
| `BUN-TEST-27` | `coverageThreshold` **MUST** vir acompanhado do reporter `text` habilitado em toda execução fora de `--parallel` — com apenas `--coverage-reporter=lcov` o processo sai `0` mesmo abaixo do limiar. |
| `BUN-TEST-28` | `coverageThreshold` **NEVER** depende da chave `statements` — ela é aceita e **não** é aplicada; o portão real é `lines` e `functions`. |

---

## 4. Reporters de resultado

| Reporter | Como | Quando |
| --- | --- | --- |
| default | — | leitura local |
| dots | `--dots` ou `--reporter=dots` | suíte grande: um ponto por teste, detalhe completo só nas falhas |
| JUnit XML | `--reporter=junit --reporter-outfile=./junit.xml` | GitLab, Jenkins, qualquer CI que consome JUnit |

```toml
[test.reporter]
junit = "junit.xml"
```

**`--reporter=junit` exige `--reporter-outfile`.** A saída normal para stdout continua; o XML é escrito ao fim, e inclui informação de ambiente como `<properties>` (build, commit, hostname). Limitações declaradas: **não** inclui stdout/stderr dos testes individuais, nem timestamp preciso por caso.

**GitHub Actions não precisa de configuração.** `bun test` detecta que está rodando lá e emite anotações direto no console — as falhas aparecem no diff do PR, na linha certa, sem action extra.

Reporter customizado é possível: Bun estende o WebKit Inspector Protocol com os domínios `TestReporter` e `LifecycleReporter` (eventos `TestReporter.found`/`start`/`end`, `Console.messageAdded`, `LifecycleReporter.error`). É superfície de ferramenta, não de projeto — a menos que você esteja construindo um dashboard, não é aqui que o tempo rende.

| ID | Regra |
| --- | --- |
| `BUN-TEST-29` | `--reporter=junit` **MUST** vir acompanhado de `--reporter-outfile` — a fonte declara o par obrigatório. |

---

## 5. O workflow

### 5.1 O caso comum: um job

```yaml
name: CI
on: [push, pull_request]

jobs:
 test:
 runs-on: ubuntu-latest
 steps:
 - uses: actions/checkout@v4
 - uses: oven-sh/setup-bun@v2
 with:
 bun-version: 1.4.0 # pinado — BUN-TEST-15
 - run: bun ci # lockfile congelado — BUN-PKG-02
 - run: bun run typecheck # tsc --noEmit; bun test NÃO checa tipo
 - run: bun test --parallel --coverage
```

Quatro decisões, e cada uma tem um ID por trás:

- **Versão pinada** (`BUN-TEST-15`): flags do runner mudam entre minors.
- **`bun ci`** e não `bun install` (`BUN-PKG-02`, [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md)).
- **`typecheck` como passo próprio** (`BUN-TEST-18`): `expectTypeOf` é no-op em runtime, e nada mais no `bun test` olha tipo.
- **`--parallel`**: é o único ambiente em que o isolamento por arquivo é obrigatório, e é o que mantém a suíte honesta ([Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 4).

Sem `-u` em nenhuma linha (`BUN-TEST-05`), e sem `--retry` global.

### 5.2 Suíte grande: shard por máquina

```yaml
 test:
 runs-on: ubuntu-latest
 strategy:
 fail-fast: false
 matrix:
 shard: [1, 2, 3, 4]
 steps:
 - uses: actions/checkout@v4
 - uses: oven-sh/setup-bun@v2
 with: { bun-version: 1.4.0 }
 - run: bun ci
 - uses: actions/cache@v4
 with:
 path:.bun-timings.json
 key: bun-timings-${{ github.ref_name }}
 - run: bun test --shard=${{ matrix.shard }}/4 --timings=.bun-timings.json --parallel
```

`fail-fast: false` porque você quer o resultado de todos os shards, não o do primeiro que quebrou. O cache do arquivo de timings é o que faz `--timings` valer: sem persistência, cada execução divide por contagem de arquivos ([Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 7).

### 5.3 Job rápido de PR

```yaml
 - run: bun test --changed=origin/${{ github.base_ref }} --parallel
```

Roda só os arquivos cujo grafo de import alcança o diff. **Isso acelera o feedback; não substitui a suíte inteira no portão de merge** — o grafo de import não vê variável de ambiente, migração, fixture nem ordem de execução (`BUN-TEST-15` e [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 3.4).

### 5.4 CI que consome JUnit

```bash
bun test --parallel --coverage --reporter=junit --reporter-outfile=./junit.xml
```

Sob `--parallel`, o coordenador funde cobertura, XML e escrita de snapshot: um relatório, não um por worker.

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `coverageThreshold` com só `--coverage-reporter=lcov`, fora de `--parallel` | o limiar não é checado; o processo sai `0` abaixo do número | manter `text` na lista de reporters — `BUN-TEST-27` |
| `coverageThreshold = { statements = 0.95 }` | a chave é aceita e não é aplicada: não há portão | usar `lines` e `functions` — `BUN-TEST-28` |
| `coverageThreshold = 90` | o valor é fração, não percentual; `90` é inalcançável | `0.9` |
| Limiar copiado de outro projeto | build vermelho no dia da adoção, ou portão que nunca aciona | medir a suíte e colocar o portão logo abaixo — § 1 |
| Cobertura como meta de time | produz teste que executa sem verificar | usar cobertura para achar o não testado — § 1 |
| `--reporter=junit` sem `--reporter-outfile` | a fonte declara o par obrigatório | passar os dois — `BUN-TEST-29` |
| `coverageIgnoreSourcemaps = true` num projeto TypeScript | o relatório passa a apontar linhas do código transpilado | deixar no default `false` |
| `bun install` no CI | reescreve o lockfile e não falha em divergência | `bun ci` — `BUN-PKG-02` |
| `bun@latest` no CI | flags do runner mudam entre minors; quebra sem commit | pinar — `BUN-TEST-15` |
| CI sem passo de `tsc --noEmit` | nada no `bun test` verifica tipo | passo próprio — `BUN-TEST-18` |
| `--changed` como portão de merge | o grafo de import não vê env, migração, fixture nem ordem | suíte inteira no merge — § 5.3 |
| `--shard` sem cache do arquivo de `--timings` | a divisão volta a ser por contagem de arquivos | cachear o arquivo — § 5.2 |
| `-u` no comando de CI | o snapshot passa a registrar qualquer saída | `-u` é comando de pessoa — `BUN-TEST-05` |

---

## Checklist de revisão

- [ ] `coverageReporter` inclui `text` sempre que há `coverageThreshold`? → `BUN-TEST-27`
- [ ] O limiar usa `lines`/`functions`, não `statements`? → `BUN-TEST-28`
- [ ] O número do limiar foi medido, não copiado? → § 1
- [ ] `--reporter=junit` vem com `--reporter-outfile`? → `BUN-TEST-29`
- [ ] A versão do Bun está pinada? → `BUN-TEST-15`
- [ ] Existe passo separado de `tsc --noEmit`? → `BUN-TEST-18`
- [ ] O comando de CI está sem `-u` e sem `--retry` global? → `BUN-TEST-05`
- [ ] Se há `--shard`, o arquivo de timings é persistido? → § 5.2
- [ ] O portão de merge roda a suíte inteira, não `--changed`? → § 5.3
- [ ] A instalação em CI é `bun ci`? → `BUN-PKG-02`

---

## Relacionados

- [Bun - Testes](bun-testes.md) — hub, modelo mental, mapa da API, árvores de decisão
- [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) · [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) · [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) · [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) · [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md)
- [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) — `bun ci`, lockfile, pin de versão
- `Github Actions` — workflows e matriz
- — o que testar, antes de como

## Fontes consultadas

Verificadas em **2026-08-20**: [Code coverage](https://bun.com/docs/test/code-coverage) · [Test Reporters](https://bun.com/docs/test/reporters) · [Test configuration](https://bun.com/docs/test/configuration) · [Parallel & isolated test runs](https://bun.com/docs/test/parallel) · [Bun 1.4](https://bun.com/blog/bun-v1.4).
