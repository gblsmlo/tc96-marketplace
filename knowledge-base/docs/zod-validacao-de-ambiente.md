---
titulo: Zod - Validação de Ambiente
Link: https://zod.dev/
tags:
 - zod
 - typescript
 - configuration
 - security
 - agent-context
source: "Documentação oficial Zod, Vite e Node.js · verificado contra zod 4.4.3, tsc 7.0.2, node 22.23.2, bun 1.3.14"
verificado-em: 2026-08-15
---

# Zod - Validação de Ambiente

> O módulo de configuração como única porta de entrada de `process.env` · schema, coerção e o tipo derivado · mensagens de erro que listam tudo que falta de uma vez · a fronteira cliente/servidor e por que variável prefixada é conteúdo público · Node, Bun e Vite/TanStack Start · seis armadilhas verificadas em runtime · quando validar: boot, build ou CI.
>
> **Não cobre:** o porquê conceitual de validar configuração · a API geral do Zod · onde segredos devem morar em produção (`Arquivos.env não substituem secret management`) · `strict` e resolução de módulos.

Entrada conceitual: · API do Zod:

---

## 1. Conceito: a configuração é uma fronteira de dados, igual à HTTP

`process.env` é entrada externa não confiável. Ninguém aceitaria um corpo de request sem validar;
configuração recebe o mesmo tratamento pela mesma razão. A diferença é o momento da falha: um
request inválido devolve 400, uma configuração inválida **não deve deixar o processo subir**.

O erro estrutural que essa regra evita não é o valor errado — é o valor errado descoberto tarde. Sem
validação no boot, uma variável ausente vira `undefined`, atravessa três camadas, e reaparece como
`Cannot read properties of undefined` numa rota que ninguém associa a deploy.

O padrão tem uma forma só: **um módulo, no boot, que valida tudo e exporta apenas o resultado
validado.** Todo o resto do app importa esse objeto e nunca toca `process.env`.

---

## 2. O módulo de configuração

```typescript
// src/env.ts
import { z } from 'zod'

const envSchema = z.object({
 PORT: z
.string('PORT é obrigatória')
.pipe(
 z.coerce
.number<string>('PORT deve ser numérica')
.min(1024, 'PORT deve estar entre 1024 e 65535')
.max(65535, 'PORT deve estar entre 1024 e 65535'),
 ),
 DATABASE_URL: z.url('DATABASE_URL deve ser uma URL válida'),
 NODE_ENV: z.enum(
 ['development', 'test', 'production'],
 'NODE_ENV deve ser development, test ou production',
 ),
 LOG_LEVEL: z
.enum(['debug', 'info', 'warn', 'error'], 'LOG_LEVEL inválido')
.default('info'),
})

const resultado = envSchema.safeParse(process.env)

if (!resultado.success) {
 console.error('Configuração inválida:\n' + z.prettifyError(resultado.error))
 process.exit(1)
}

export const env = resultado.data
export type Env = z.infer<typeof envSchema>
```

**O `<string>` em `z.coerce.number<string>` não é decoração.** Sem ele o schema roda mas **não
compila** — ver § 6.7. É o detalhe mais fácil de perder deste arquivo inteiro.

Quatro decisões nesse arquivo, cada uma com uma razão:

- **`safeParse` e não `parse`.** `parse` lança, e o stack trace de uma exceção do Zod no boot é ruído
 para quem só precisa saber qual variável falta. Com `safeParse` você controla a mensagem.
- **`process.exit(1)`.** Configuração inválida não é recuperável. Continuar com defaults é como o app
 decide sozinho que vai rodar errado.
- **`NODE_ENV` sem `.default`.** Um default aqui faz uma variável esquecida virar silenciosamente um
 ambiente. Ver sobre por que o default de `production` engana.
- **`LOG_LEVEL` com `.default`.** Este pode ter default: é preferência operacional, não decisão de
 ambiente. O critério é se a omissão muda o comportamento de forma que alguém precise saber.

### O tipo vem do schema

`z.infer` deriva `Env` do schema — não existe uma segunda declaração para sair de sincronia. Depois
de `safeParse` com sucesso, `resultado.data.PORT` é `number`, com o `min`/`max` já garantidos. É a
mesma disciplina de aplicada à
configuração.

---

## 3. Mensagens que servem

O modo de falha que importa é o primeiro deploy num ambiente novo, onde faltam **cinco** variáveis.
Um erro por vez significa cinco ciclos de deploy.

`z.prettifyError` (Zod 4) formata todos os problemas de uma vez:

```
Configuração inválida:
✖ PORT é obrigatória
 → at PORT
✖ DATABASE_URL deve ser uma URL válida
 → at DATABASE_URL
```

Escreva a mensagem em cada campo. O texto padrão do Zod descreve o schema
(`Invalid input: expected number`), não o que a pessoa precisa fazer. Quem lê esse log está num
terminal de CI às onze da noite, sem o código aberto.

**Nunca logue o valor recebido.** A mensagem de erro de `DATABASE_URL` não pode conter a URL — logs
de CI são frequentemente públicos ou amplamente legíveis. Diga o nome da variável e o formato
esperado, nunca o conteúdo. Ver `Arquivos.env não substituem secret management`.

---

## 4. A fronteira cliente/servidor

Esta é a seção com consequência de segurança, e a que o artigo de origem não trata.

O princípio está em: o prefixo não protege,
declara. A documentação do Vite diz que os valores são "bundled into your source code at build time".
O que segue aqui é a implementação e os **dois vetores** de vazamento, que são diferentes e exigem
defesas diferentes.

### O que conta como segredo

`ZOD-ENV-04` só é acionável com um critério. Duas perguntas resolvem quase todos os casos:

1. **Quem possui esse valor consegue agir em nome do sistema?** Credencial de banco, chave de API com
 permissão de escrita, segredo de assinatura de sessão ou JWT — sim, é segredo.
2. **Se vazasse, seria preciso rotacionar?** Se a resposta é sim, é segredo, mesmo que pareça inócuo.

Não são segredos: valores que o navegador já revelaria de qualquer forma — a URL pública da API
(visível em qualquer request), um identificador que o servidor valida por outro meio, uma chave
explicitamente publicável. A convenção de prefixo de vários provedores já codifica isso: `pk_` é
publicável, `sk_` é secreta. Uma variável `VITE_*` contendo `sk_` é a violação canônica.

Na dúvida, trate como segredo: o custo de manter algo no servidor é uma chamada a mais; o custo de
publicar uma chave é rotação e incidente.

Os dois schemas ficam em arquivos separados:

```typescript
// src/server-env.ts — sem o sufixo.server., ver abaixo. Nunca importado por código de cliente.
import { z } from 'zod'

const serverSchema = z.object({
 DATABASE_URL: z.url,
 STRIPE_SECRET_KEY: z.string.startsWith('sk_'),
 SESSION_SECRET: z.string.min(32),
})

const r = serverSchema.safeParse(process.env)
if (!r.success) { console.error(z.prettifyError(r.error)); process.exit(1) }
export const serverEnv = r.data
```

```typescript
// src/client-env.ts — tudo aqui vai para o bundle
import { z } from 'zod'

const clientSchema = z.object({
 VITE_API_URL: z.url,
 VITE_SENTRY_DSN: z.string.optional,
})

export const clientEnv = clientSchema.parse(import.meta.env)
```

A separação não é organização: é a única coisa que impede um import distraído de arrastar
`STRIPE_SECRET_KEY` para dentro do bundle. Um arquivo de servidor importado por engano num
componente vira segredo publicado no próximo deploy, sem nenhum aviso.

O `parse` do cliente pode lançar sem `process.exit` — no navegador não há processo a derrubar, e uma
exceção no boot do app é o comportamento correto.

### Separar arquivos não basta: existem dois vetores

A separação acima fecha o vetor do **bundle** — o segredo não é inlined no JavaScript enviado ao
navegador. Ela **não** fecha o vetor do **SSR**: se um componente que renderiza no servidor lê
`serverEnv.STRIPE_SECRET_KEY` e coloca o valor em qualquer lugar do JSX, ele sai em texto no HTML da
resposta. Verificado numa app TanStack Start real: o valor apareceu no corpo de um `curl`, dentro de
um elemento com `display:none` — que não esconde nada de quem lê a resposta.

| Vetor | O que o fecha |
| --- | --- |
| Bundle do cliente | schemas separados por arquivo (`ZOD-ENV-05`) |
| Renderização SSR | segredo só é lido dentro de fronteira de servidor (`ZOD-ENV-11`) |

Fronteira de servidor significa `createServerFn`, route handler, action, loader que não serializa o
valor para o cliente — nunca o corpo de um componente. Ver.

### O nome do arquivo pode colidir com o framework

O TanStack Start trata sufixos `*.server.*` e `*.client.*` como marcadores de import protection e
**recusa o build** quando um componente isomórfico importa qualquer um dos dois. Isso quebra o caso
legítimo de uma rota que precisa de `serverEnv` no loader e de `clientEnv` no componente.

A saída é nomear `server-env.ts` e `client-env.ts`, sem o sufixo reservado. Mas repare no que se
perde: com o sufixo, o framework **falha o build** se um segredo for referenciado no lugar errado;
sem ele, o mesmo código compila e roda. Trocar o nome remove uma rede de segurança automática, e é
exatamente por isso que `ZOD-ENV-11` existe como regra explícita — ela substitui, por disciplina, o
que o nome de arquivo garantia sozinho.

---

## 5. Por runtime

| Runtime | De onde vem o `.env` | Objeto a validar | Prefixo público |
| --- | --- | --- | --- |
| **Node 22** | não carrega sozinho; `node --env-file=.env` ou um loader | `process.env` | — (servidor) |
| **Bun 1.3** | carregado automaticamente, sem dependência | `process.env` ou `Bun.env` | — (servidor) |
| **Vite / TanStack Start** | carregado pelo Vite por modo | `import.meta.env` no cliente | `VITE_` |
| **Next.js App Router** | carregado pelo framework | `process.env` nos dois lados | `NEXT_PUBLIC_` |

Verificado: no mesmo diretório com um `.env`, `bun -e` enxerga a variável e `node -e` devolve
`undefined`. O Node ganhou `--env-file` (e `--env-file-if-exists`, que apenas avisa quando o arquivo
não existe), então dotenv deixou de ser necessário para o caso simples.

O Vite carrega em ordem de precedência: variáveis já presentes no ambiente, depois
`.env.[mode].local`, `.env.[mode]`, `.env.local` e `.env`. Os arquivos `.local` vão para o
`.gitignore`.

**Em produção, nada disso.** `.env` é interface de desenvolvimento. Em produção os valores chegam
pelo mecanismo da plataforma ou por um gerenciador de segredos — ver
`Arquivos.env não substituem secret management` e. O módulo de validação é o mesmo nos
dois casos; só a origem dos valores muda, e é justamente por isso que ele funciona como fronteira.

---

## 6. Armadilhas verificadas

Cada item abaixo foi executado contra zod 4.4.3, tsc 7.0.2 e node 22.23.2. Nenhum é teórico.

### 6.1 Aumentar `NodeJS.ProcessEnv` não compila

A técnica "avançada" do artigo de origem:

```typescript
declare global {
 namespace NodeJS {
 interface ProcessEnv extends z.infer<typeof envSchema> {}
 }
}
```

Com qualquer campo não-string no schema, o resultado é:

```
error TS2411: Property 'PORT' of type 'number' is not assignable to
 'string' index type 'string | undefined'.
```

`ProcessEnv` declara `[key: string]: string | undefined`. Um membro `number` viola a index signature.
Não é ressalva de estilo — não compila.

### 6.2 Com schema só de strings, compila e mente

Se todos os campos forem `z.string`, a augmentation passa no compilador. Aí o problema é outro:
o TypeScript passa a dizer que `process.env.APP_NAME` é `string`, sem `| undefined`. Verificado com a
variável genuinamente ausente:

```
typeof = undefined
.length => TypeError: Cannot read properties of undefined
```

O tipo declarado não valida nada; ele apenas remove o aviso que teria evitado o erro. É exatamente a
troca ruim: menos segurança, com aparência de mais. Ver.

**Regra:** não aumente `ProcessEnv`. Importe o objeto validado.

### 6.3 `parse` não altera `process.env`

```
env.PORT = 3000 typeof number
process.env.PORT = '3000' typeof string
```

A validação produz um objeto novo. `process.env` continua sendo o que sempre foi. Quem ler
`process.env.PORT` depois do parse recebe a string — é por isso que `ZOD-ENV-02` proíbe ler
`process.env` fora do módulo de configuração.

### 6.4 `z.coerce.number` sozinho esconde variável ausente

```typescript
PORT: z.coerce.number.min(1000)
```

Com `PORT` ausente, `Number(undefined)` é `NaN` e a mensagem vira:

```
Invalid input: expected number, received NaN
```

Que não diz que a variável falta. A correção é validar a presença **antes** de coagir:

```typescript
PORT: z.string('PORT é obrigatória').pipe(z.coerce.number<string>.min(1000))
```

Verificado: a mesma entrada ausente passa a produzir `PORT é obrigatória`. Sobre o `<string>`, § 6.7.

### 6.5 Atribuir a `process.env` coage para string

```
process.env.A = undefined → "undefined" (string, 9 caracteres)
process.env.B = 42 → "42"
process.env.C = null → "null"
```

Um `process.env.X = valorTalvezIndefinido` não apaga a variável: cria a string literal `"undefined"`,
que é truthy e passa em `z.string.min(1)`. Não escreva em `process.env`.

### 6.6 Booleano de string não existe

`z.coerce.boolean` aplica a regra de truthiness do JavaScript: `Boolean("false")` é `true`. Toda
string não vazia vira `true`, inclusive `"0"` e `"no"`. Trate explicitamente:

```typescript
DEBUG: z.enum(['true', 'false']).default('false').transform((v) => v === 'true')
```

### 6.7 `z.coerce.number` dentro de `.pipe` roda mas não compila

A armadilha mais cara desta nota, porque o código **funciona** quando executado e só falha no
`tsc` — quem testar com `node` ou `tsx` não vê nada de errado.

```typescript
// não compila
PORT: z.string('obrig').pipe(z.coerce.number('num').min(1024).max(65535))
```

```
error TS2345: Argument of type 'ZodCoercedNumber<unknown>' is not assignable
 to parameter of type '$ZodType<any, string,...>'.
 Type 'unknown' is not assignable to type 'string'.
```

A assinatura é `z.coerce.number<T = unknown>`. Sem argumento de tipo, o `input` do schema coagido é
`unknown`, e `.pipe` exige que o `input` do destino aceite o `output` da origem — `string`. O erro
só aparece quando há um refinamento encadeado (`.min`, `.max`); `z.string.pipe(z.coerce.number)`
puro compila, o que torna a falha ainda mais confusa.

Duas correções, ambas verificadas com `tsc --noEmit --strict` e com mensagens de runtime idênticas:

```typescript
// preferida: declare o input coagido
PORT: z.string('obrig').pipe(z.coerce.number<string>('num').min(1024).max(65535))

// alternativa: separe coerção de refinamento
PORT: z.string('obrig').pipe(z.coerce.number('num')).pipe(z.number.min(1024).max(65535))
```

---

## 7. Quando validar

| Momento | O que pega | Custo |
| --- | --- | --- |
| **Boot** | tudo, no ambiente real | o app não sobe — é o comportamento desejado |
| **Build** | variáveis de cliente, que são inlined no bundle | falha o build, antes de publicar |
| **CI** | ausência de variável nova que ninguém adicionou ao ambiente | falha o pipeline, antes do deploy |

Boot é obrigatório. Build só se aplica a variáveis de cliente, e é onde a falha custa menos. O de CI
exige uma checagem separada, porque o schema completo do servidor não pode ser satisfeito com
segredos reais dentro do pipeline — valide a **presença das chaves**, não os valores.

O parágrafo do artigo de origem sobre "validar em build ou CI conforme a necessidade" é vago nesse
ponto: os três momentos não são alternativas, são camadas com alcances diferentes.

### O `process.exit(1)` e a suíte de testes

O módulo valida no import. Isso é o que se quer em produção e é um problema em teste: o runner
importa o módulo, a configuração do ambiente de teste não tem `DATABASE_URL`, e o processo morre
antes do primeiro `it`. O sintoma é uma suíte que encerra sem rodar nada e sem erro de teste.

Três saídas, em ordem de preferência:

1. **Um `.env.test` versionado, com valores falsos e válidos.** Não há segredo real ali — `PORT=3000`,
 `DATABASE_URL=postgres://localhost/test`. É a opção que mantém o schema honesto e ainda documenta
 o que a app exige. Carregue-o no setup do runner.
2. **Fixture de configuração nos testes**, injetando o objeto validado em vez de importar o módulo —
 funciona se o código recebe `env` por parâmetro em vez de importar direto.
3. **Adiar a validação** para uma função chamada no entrypoint, em vez de rodar no topo do módulo.
 Resolve o teste, mas perde a garantia de que nada consegue importar configuração não validada.

A opção 1 é a que mantém `ZOD-ENV-01` intacto. Para o preload do runner, ver [Bun - Testes](bun-testes.md).

---

## 8. Regras normativas

| ID | Regra | Severidade |
| --- | --- | --- |
| `ZOD-ENV-01` | Toda a configuração é validada num módulo só, no boot, que exporta apenas o objeto validado. | crítica |
| `ZOD-ENV-02` | Nenhum outro arquivo lê `process.env` ou `import.meta.env`. | crítica |
| `ZOD-ENV-03` | Não aumente `NodeJS.ProcessEnv`. Ver § 6.1 e § 6.2. | crítica |
| `ZOD-ENV-04` | Segredo nunca leva prefixo público (`VITE_`, `NEXT_PUBLIC_`). Prefixo declara conteúdo público. | crítica |
| `ZOD-ENV-05` | Schemas de cliente e de servidor ficam em arquivos separados. | crítica |
| `ZOD-ENV-11` | Variável de servidor só é lida dentro de fronteira de servidor, nunca no corpo de um componente. Fecha o vetor SSR, que a separação de arquivos não fecha. | crítica |
| `ZOD-ENV-06` | Configuração inválida encerra o processo; não há fallback silencioso. | crítica |
| `ZOD-ENV-07` | Campo numérico ou booleano valida presença antes de coagir (`z.string.pipe(...)`). | alta |
| `ZOD-ENV-08` | A falha reporta todos os campos inválidos de uma vez (`z.prettifyError`). | alta |
| `ZOD-ENV-09` | Mensagem de erro cita o nome e o formato da variável, nunca o valor recebido. | alta |
| `ZOD-ENV-10` | Nada escreve em `process.env`. Ver § 6.5. | média |

Achado de revisão cita o ID, o arquivo e a linha:

> `ZOD-ENV-02` — `src/features/faturas/api/faturas-client.ts:4`
> Lê `process.env.API_URL` direto, fora do módulo de configuração.
> Correção: importar `env` de `@libs/env` e usar `env.API_URL`.

### Antipadrões

| Antipadrão | Por que dói | ID |
| --- | --- | --- |
| `process.env.X ?? 'default'` espalhado pelo código | o default vive longe do schema; dois arquivos discordam sobre o valor | `ZOD-ENV-02` |
| `catch` que exporta objeto de fallback | o app sobe configurado errado, e o log de erro vira ruído que ninguém lê | `ZOD-ENV-06` |
| `declare global { namespace NodeJS { … } }` | não compila com campo não-string; com só-strings, mente sobre presença | `ZOD-ENV-03` |
| `z.coerce.number` cru num campo obrigatório | variável ausente vira `NaN` e a mensagem não diz o que falta | `ZOD-ENV-07` |
| `z.coerce.boolean` | `Boolean('false')` é `true`; todo valor não vazio vira `true` | `ZOD-ENV-07` |
| `console.error(JSON.stringify(process.env))` | despeja todos os segredos no log de CI | `ZOD-ENV-09` |
| Segredo renomeado para `VITE_*` "para o front conseguir usar" | publica a chave no bundle | `ZOD-ENV-04` |
| `serverEnv.SECRET` dentro de um componente | sai em texto no HTML do SSR, mesmo fora do bundle JS | `ZOD-ENV-11` |
| Schema único para cliente e servidor | um import distraído leva o segredo para o bundle | `ZOD-ENV-05` |

### Checklist de revisão

Ordenada por frequência de falha:

- [ ] Algum arquivo além do módulo de configuração lê `process.env` / `import.meta.env`? → `ZOD-ENV-02`
- [ ] A falha de validação encerra o processo, sem fallback? → `ZOD-ENV-06`
- [ ] Campo numérico ou booleano valida presença antes de coagir, com `<string>` no `pipe`? → `ZOD-ENV-07`, § 6.7
- [ ] Alguma variável com prefixo público carrega segredo? → `ZOD-ENV-04`
- [ ] Cliente e servidor em arquivos separados? → `ZOD-ENV-05`
- [ ] Alguma variável de servidor é lida fora de fronteira de servidor? → `ZOD-ENV-11`
- [ ] A mensagem de erro cita valor recebido? → `ZOD-ENV-09`
- [ ] Existe `declare global` sobre `ProcessEnv`? → `ZOD-ENV-03`
- [ ] Alguém escreve em `process.env`? → `ZOD-ENV-10`
- [ ] `pnpm tsc --noEmit` passa? A § 6.7 falha só no compilador.

---

## 9. Uso por um agente

```
AO CRIAR O MÓDULO DE ENV: § 2 (padrão base) + § 4 se houver cliente
AO ADICIONAR UMA VARIÁVEL: § 2 (default sim/não) + § 4 (é pública?)
AO REVISAR: § 8 (regras) + § 6 (armadilhas)
AO ESCOLHER RUNTIME: § 5
```

Ordem das decisões ao adicionar uma variável:

1. **Ela vai para o cliente?** Se sim, é pública — e um segredo não pode ir. Schema de cliente.
2. **A omissão dela muda comportamento que alguém precisa saber?** Se sim, sem `.default`.
3. **É número ou booleano?** Valide presença antes de coagir (`ZOD-ENV-07`).
4. **A mensagem diz o que fazer sem citar o valor?** (`ZOD-ENV-09`)

Invariantes: **o que não passou pelo schema não é configuração** — se um valor é lido de
`process.env` em outro lugar, ele não foi validado, independentemente do tipo que o TypeScript
mostra. E **a fonte vence**: divergência entre esta nota e o comportamento real do Zod, do Node ou do
Vite é bug desta nota.

---

## Relacionados

- — o conceito; esta nota é a implementação
- — API do Zod, `parse` × `safeParse`, `input` × `output`
-
-
- `Arquivos.env não substituem secret management` — onde os valores devem morar
- — a mesma disciplina na fronteira HTTP
- — `strict`, sem o qual metade disso não ajuda
- `Env type safety and validation` — artigo de origem

## Fontes consultadas

**Verificado por execução** — `zod 4.4.3`, `tsc 7.0.2`, `node 22.23.2`, `bun 1.3.14`:

- § 2, o schema completo — compila com `tsc --noEmit --strict` e roda nos quatro modos de falha
- § 6.1 a § 6.7 — cada armadilha reproduzida, incluindo as mensagens de erro literais
- § 5, carregamento de `.env` — `bun` automático, `node` só com `--env-file`
- § 3, formato de `z.prettifyError`

**Documentação consultada:**

- `Env type safety and validation` — creatures.sh, artigo de origem
- [Zod](https://zod.dev/)
- [Vite — Env Variables and Modes](https://vite.dev/guide/env-and-mode)
- [Node.js — `--env-file`](https://nodejs.org/api/cli.html#--env-fileconfig)

**Relatado por terceiro, não reproduzido aqui:** a colisão de `*.server.*` / `*.client.*` com o
import protection do TanStack Start (§ 4) veio de uma execução em app real durante a revisão desta
nota; o vazamento por SSR foi confirmado via `curl`, mas o comportamento do plugin pode mudar entre
versões do framework. Confirme antes de depender do nome de arquivo como proteção.
