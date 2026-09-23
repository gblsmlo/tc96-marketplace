---
titulo: Bun - Dados e Persistência
Link: https://bun.com/docs/runtime/sql
tags:
  - bun
  - database
  - agent-context
source: "Documentação oficial — https://bun.com/docs"
verificado-em: 2026-08-15
---

# Bun - Dados e Persistência

> `bun:sqlite` (`Database`, `query` × `prepare`, `.get`/`.all`/`.run`/`.iterate`, `strict`, `safeIntegers`, transações, WAL) · `Bun.sql` / `Bun.SQL` (tagged template, pooling, `sql.begin`, savepoints, `sql.unsafe`) · cliente Redis nativo · cliente S3 e presigned URLs · quando ORM ainda paga o próprio peso.
>
> **Não cobre:** o handler HTTP que consome o driver ([Bun - HTTP e Servidor](bun-http-e-servidor.md)) · `Bun.file` e I/O de arquivo local ([Bun - Runtime e APIs](bun-runtime-e-apis.md)) · seed e fixtures em teste ([Bun - Testes](bun-testes.md)) · variáveis de ambiente em container ([Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md)).

Entrada: [Bun](bun.md) § 5 (árvores de decisão) · § 6 (regras normativas) · Base normativa: [Bun](bun.md)

Versão verificada: **Bun 1.3.14** (`bun@latest` no registry npm, 2026-08-15).

---

## 1. Conceito: driver embutido remove dependência, não remove política

Bun embute quatro clientes de dados: SQLite (`bun:sqlite`), SQL genérico com pooling (`Bun.sql`), Redis (`Bun.redis`) e S3 (`Bun.s3`). Zero dependências, zero instalação, tipos incluídos.

> **`Bun.sql` não é um cliente Postgres.** É uma API única sobre **PostgreSQL, MySQL e SQLite** — a fonte é literal: *"a unified Promise-based API that supports PostgreSQL, MySQL, and SQLite"*. O adapter é **detectado pelo formato da URL de conexão**: `mysql://` e `mysql2://` selecionam MySQL; `:memory:`, `sqlite://`, `sqlite:`, `file://` e `file:` selecionam SQLite; qualquer outra coisa cai em PostgreSQL, que é o default. Rotular `Bun.sql` como "o driver Postgres do Bun" faz o leitor procurar um driver de MySQL que não precisa existir, e faz o revisor não perceber que uma `DATABASE_URL` trocada muda o dialeto inteiro em silêncio.

Note que existem **duas** portas para SQLite, e elas não são a mesma coisa: `bun:sqlite` é síncrona e modelada em `better-sqlite3` (§ 2); `Bun.sql` com uma URL de SQLite é assíncrona e usa a mesma API das outras duas bases. Para SQLite local, `bun:sqlite` é o caminho; `Bun.sql` sobre SQLite serve a quem quer o **mesmo código** rodando contra SQLite em teste e Postgres em produção.

Isso resolve exatamente um problema: **a dependência**. Não resolve nenhum dos outros quatro que um serviço com banco tem:

| Problema | O driver embutido resolve? |
| --- | --- |
| Instalar e versionar um cliente | **sim** — é isso que ele resolve |
| Política de conexão (pool, timeout, lifetime) | não — você configura, e o default pode não servir |
| Migração de schema | **não** — não existe nada disso em Bun |
| Validação do que sai do banco | **não** — o retorno é `any` |
| Impedir SQL injection | **parcialmente** — a ferramenta é segura; o hábito de concatenar não some sozinho |

A última linha é a que mais custa. `bun:sqlite` e `Bun.sql` oferecem parametrização segura e, no caso da tagged template, **segura por default**. Mas nada impede escrever `db.query("SELECT * FROM users WHERE id = " + id)`. É o bug número um desta nota, tem seção própria (§ 3), e é o único item cuja violação é sempre vulnerabilidade, nunca só estilo.

Sobre migração: a ausência é literal. Bun não tem sistema de migração. `sql.file(...)` e `` sql`...`.simple() `` executam scripts de migração; **decidir a ordem, registrar o que já rodou e reverter é seu**, ou de uma ferramenta externa..

---

## 2. `bun:sqlite`: síncrono, e as escolhas que parecem sinônimos

**Conceito.** A API é síncrona e modelada em `better-sqlite3`. Síncrona não é ressalva: para SQLite local, uma leitura é uma leitura de página em disco/cache, e o custo de fazer isso assíncrono seria maior que o de fazer.

**`.query()` × `.prepare()`** — a diferença é o cache, não o comportamento:

| | `db.query(sql)` | `db.prepare(sql)` |
| --- | --- | --- |
| Cacheia o statement compilado | **sim**, por string de SQL | não |
| Tamanho do cache | `Database.MAX_QUERY_CACHE_SIZE`, default **20** | — |
| Dono do statement | a `Database` (finalizado no `close`) | você |
| Serve para | SQL fixo, repetido | SQL gerado dinamicamente, uso único |

O cache guarda a **bytecode compilada**, não os resultados. Reutilizar um statement cacheado com parâmetros diferentes é seguro — os valores são religados a cada execução. Gerar SQL dinâmico e passar por `.query()` enche o cache de entradas de uso único e evicta as quentes; é para isso que existe `.prepare()`.

**Os executores:**

| Método | Devolve | Uso |
| --- | --- | --- |
| `.get(params?)` | primeira linha como objeto, ou **`null`** | busca por id |
| `.all(params?)` | array de objetos | listagem |
| `.run(params?)` | `{ lastInsertRowid, changes }` | escrita, DDL |
| `.iterate()` / `for..of` | uma linha por vez | resultado grande, sem carregar tudo em memória |
| `.values(params?)` | array de arrays | export, CSV |

`.get()` devolvendo `null` é o detalhe que produz `TypeError: cannot read property of null` em produção. O tipo do retorno não força o tratamento.

**`strict: true` — ligue.** O default de `bun:sqlite` exige o prefixo (`$`, `:`, `@`) no objeto de bind **e não lança quando um parâmetro falta**. Um typo em `{ messag: ... }` passa silenciosamente e a query roda com o valor faltando. Com `strict: true`, o prefixo vira opcional e o parâmetro ausente vira erro.

```ts
import { Database } from "bun:sqlite";

const db = new Database("pedidos.sqlite", {
  create: true,
  strict: true, // erro em parâmetro faltando; bind sem prefixo
});

// WAL: recomendado pela doc para praticamente toda aplicação
db.run("PRAGMA journal_mode = WAL;");

// statement criado UMA vez, reutilizado
const buscarPedido = db.query<
  { id: string; cliente_id: string; total: number },
  { id: string }
>("SELECT id, cliente_id, total FROM pedidos WHERE id = $id");

export function obterPedido(id: string) {
  const pedido = buscarPedido.get({ id }); // strict: sem prefixo no objeto
  if (pedido === null) return null;         // .get() devolve null, não undefined
  return pedido;
}
```

**Inteiros.** SQLite guarda inteiros de 64 bits; JavaScript representa com segurança até 2^53. Por default `bun:sqlite` devolve `number` — valores maiores perdem precisão **em silêncio**. `safeIntegers: true` na `Database` faz o retorno vir como `bigint` e valida que `bigint` de entrada cabe em 64 bits.

**Fechar.** `db.close(false)` (default) mantém vivos os statements de `.prepare()` até serem finalizados; `db.close(true)` finaliza tudo e lança se o SQLite reportar erro. `using db = new Database(...)` chama `close(true)` na saída do bloco.

| ID | Regra |
| --- | --- |
| `BUN-DATA-01` | `new Database(...)` **MUST** ser aberta com `strict: true`, e com `safeIntegers: true` quando alguma coluna puder exceder 2^53 — os defaults não lançam em parâmetro ausente e truncam inteiros grandes em silêncio. |
| `BUN-DATA-02` | Statement usado repetidamente **MUST** ser criado uma vez fora do caminho quente; SQL gerado dinamicamente **MUST** usar `.prepare()` para não evictar o cache de 20 entradas. |

---

## 3. Interpolação de string é o bug de segurança número um aqui

**Conceito.** As duas APIs oferecem o caminho seguro por default, e as duas são triviais de contornar. Este é o único ponto desta nota em que a violação é sempre uma vulnerabilidade.

```ts
// ❌ SQL injection. `id` vem do request; `'; DROP TABLE pedidos; --` é uma string válida.
db.query(`SELECT * FROM pedidos WHERE id = '${id}'`).get();

// ❌ mesma falha, escondida por um helper "só de formatação"
const where = `status = '${statusDoUsuario}'`;
db.query(`SELECT * FROM pedidos WHERE ${where}`).all();

// ✅ parâmetro: o valor nunca é parseado como SQL
db.query("SELECT * FROM pedidos WHERE id = $id").get({ id });
```

Em `Bun.sql` o mecanismo é a própria tagged template. **A interpolação `${}` dentro de `` sql`...` `` vira parâmetro, não texto.** Trocar a tag por uma string comum destrói isso:

```ts
import { sql } from "bun";

// ✅ ${email} é enviado como parâmetro
const [usuario] = await sql`SELECT * FROM usuarios WHERE email = ${email}`;

// ❌ string comum passada a sql.unsafe: nada é escapado
await sql.unsafe(`SELECT * FROM usuarios WHERE email = '${email}'`);
```

`sql.unsafe` existe para casos legítimos (script de migração com múltiplos comandos, SQL vindo de arquivo confiável) e a doc é explícita: *"it does not escape user input"*. Ele **aceita** parâmetros posicionais — `sql.unsafe("SELECT … WHERE id = $1", [id])` — e essa é a única forma aceitável quando há valor de runtime envolvido.

**O caso que confunde: identificador não é valor.** Nome de tabela e de coluna não podem ser parâmetro em SQL nenhum. `Bun.sql` resolve com o helper `sql()`, que **escapa identificadores**:

```ts
await sql`SELECT * FROM ${sql("public.pedidos")}`;                 // identificador escapado
await sql`UPDATE usuarios SET ${sql(dados, "nome", "email")} WHERE id = ${id}`;
await sql`SELECT * FROM pedidos WHERE id IN ${sql([1, 2, 3])}`;    // lista de valores
```

Escapado não é o mesmo que validado. Passar um nome de coluna vindo do usuário direto para `sql(...)` continua sendo superfície de ataque — o correto é validar contra uma allowlist antes.

| ID | Regra |
| --- | --- |
| `BUN-DATA-03` | Valor de runtime **NEVER** entra em SQL por concatenação ou por template string fora da tag `sql` — **MUST** ser parâmetro (`$nome`/`?` em `bun:sqlite`, `${}` dentro da tagged template de `Bun.sql`). |
| `BUN-DATA-04` | `sql.unsafe` **NEVER** recebe string construída com entrada externa; com valores de runtime, **MUST** usar a forma com parâmetros posicionais. |
| `BUN-DATA-05` | Nome de tabela ou coluna vindo de entrada externa **MUST** ser validado contra uma allowlist antes de passar pelo helper `sql(...)`. |

---

## 4. Transações: SQLite embrulha função, `Bun.sql` embrulha callback

**Conceito.** O modelo é o mesmo nas duas APIs — o driver emite `BEGIN`, roda seu código, e faz `COMMIT` no retorno normal ou `ROLLBACK` na exceção — mas a ergonomia difere.

**`bun:sqlite`:** `db.transaction(fn)` devolve uma **função nova** que embrulha `fn`. Nada roda até você chamar essa função. Argumentos e retorno passam através dela.

```ts
const inserirItem = db.query("INSERT INTO itens (pedido_id, sku, qtd) VALUES ($pedido, $sku, $qtd)");
const marcarPago  = db.query("UPDATE pedidos SET status = 'pago' WHERE id = $id");

// db.transaction devolve uma função; nada executou ainda
const registrarPagamento = db.transaction((pedidoId: string, itens: Item[]) => {
  for (const item of itens) inserirItem.run({ pedido: pedidoId, sku: item.sku, qtd: item.qtd });
  marcarPago.run({ id: pedidoId });
  return itens.length;
});

const total = registrarPagamento("ped_123", itens); // aqui roda, atômico
```

Chamar uma função de transação **dentro** de outra transforma a interna em `SAVEPOINT`. Há variantes de modo: `.deferred()`, `.immediate()`, `.exclusive()`.

**`Bun.sql`:** `sql.begin(async tx => { … })` reserva uma conexão dedicada do pool para PostgreSQL. **Todas as queries da transação têm de sair do `tx`** — usar o `sql` global lá dentro pega outra conexão do pool, e essa query fica fora da transação. É o erro mais caro desta seção, porque o código funciona e só perde a atomicidade.

```ts
import { sql } from "bun";

await sql.begin(async (tx) => {
  const [pedido] = await tx`
    INSERT INTO pedidos (cliente_id, total) VALUES (${clienteId}, ${total}) RETURNING *
  `;

  await tx.savepoint(async (sp) => {
    // pode falhar sem abortar a transação inteira
    await sp`UPDATE estoque SET qtd = qtd - ${qtd} WHERE sku = ${sku}`;
  });

  await tx`INSERT INTO auditoria (acao, pedido_id) VALUES ('criado', ${pedido.id})`;
});
```

Para pipelining, o callback pode devolver um array de queries em vez de aguardar uma a uma. `sql.beginDistributed(nome, cb)` + `sql.commitDistributed` / `sql.rollbackDistributed` cobrem two-phase commit (prepared transactions no PostgreSQL, XA no MySQL).

**"Escritas relacionadas" não é um critério de revisão.** É julgamento, e julgamento não falha um PR. O critério que falha é de contagem: **conte as instruções de escrita que uma mesma função emite**. Duas ou mais (`INSERT`, `UPDATE`, `DELETE`, DDL) contra o mesmo banco significam que existe um instante em que a primeira já foi aplicada e a segunda não — e a pergunta deixa de ser "elas são relacionadas?" para virar "esse instante é um estado que o resto do sistema aceita ler?".

Na prática:

| O que a função faz | Precisa de transação? |
| --- | --- |
| Uma escrita, nenhuma leitura dependente | não |
| Duas escritas (criar pedido + baixar estoque) | **sim** — o meio-termo é pedido sem baixa |
| Uma escrita + leitura posterior que decide outra escrita | **sim** — sem transação a leitura enxerga uma janela onde outro processo já mudou a linha |
| Muitas escritas idênticas em loop (importação, seed) | **sim**, e também por performance: uma transação por lote em vez de um commit por linha |
| Uma escrita seguida de um `INSERT` em tabela de auditoria/log | **sim** por default — auditoria que sobrevive ao rollback do fato auditado é registro falso |

Ficar de fora é legítimo (fila que já é idempotente, evento cuja perda é aceitável) — mas **`BUN-DATA-06` exige que a exceção esteja escrita como comentário**, nomeando o estado intermediário aceito. Uma exceção não comentada é indistinguível de um esquecimento, que é exatamente o que a regra existe para pegar.

**WAL em SQLite.** A doc recomenda para a maioria das aplicações: `db.run("PRAGMA journal_mode = WAL;")` no boot, porque melhora muito o caso de muitos leitores com um escritor. O detalhe operacional verificado: em **macOS**, Bun usa o SQLite do sistema, que a Apple compila com WAL persistente, então os arquivos `-wal` e `-shm` **permanecem** após o `close()`. Em Linux e Windows, o SQLite estaticamente linkado costuma removê-los. Para uniformizar, `db.fileControl(constants.SQLITE_FCNTL_PERSIST_WAL, 0)` seguido de `PRAGMA wal_checkpoint(TRUNCATE)` antes de fechar.

| ID | Regra |
| --- | --- |
| `BUN-DATA-06` | Função ou handler que emite **duas ou mais** instruções de escrita (`INSERT`, `UPDATE`, `DELETE`, DDL) contra o mesmo banco **MUST** envolvê-las em `db.transaction(...)` (SQLite) ou `sql.begin(...)` (`Bun.sql`); ficar de fora exige um comentário no código declarando qual estado intermediário é aceitável. |
| `BUN-DATA-07` | Dentro de `sql.begin`, toda query **MUST** ser emitida pelo `tx` recebido — o `sql` global usa outra conexão do pool e fica fora da transação. |
| `BUN-DATA-08` | Banco SQLite em arquivo **MUST** habilitar `PRAGMA journal_mode = WAL` na inicialização. |

---

## 5. `Bun.sql`: pool, e o que "estável" significa aqui

**Conceito.** `Bun.sql` é uma API unificada baseada em Promise sobre **PostgreSQL, MySQL e SQLite**. `sql` (o singleton exportado de `bun`) lê a configuração do ambiente; `new SQL(url | options)` configura explicitamente.

**Status verificado: a página de SQL não traz nenhuma marcação de experimental, beta ou preview.** Isso contraria a memória de quando o cliente Postgres era novo. Autenticação suportada: SCRAM-SHA-256 (SASL), MD5 e Clear Text.

### As variáveis de ambiente, por nome

"Lê a configuração do ambiente" não é acionável no dia 1. Os nomes, verificados na fonte:

| Adapter | URL de conexão, na ordem em que a fonte as lista |
| --- | --- |
| **PostgreSQL** | `POSTGRES_URL` (a fonte a chama de *primary*) → `DATABASE_URL` (*alternative, auto-detected*) → `PGURL` → `PG_URL` → `TLS_POSTGRES_DATABASE_URL` → `TLS_DATABASE_URL` (as duas últimas são as variantes com SSL/TLS) |
| **MySQL** | `MYSQL_URL` — a fonte marca no exemplo: *"Primary connection URL (checked first)"* → `DATABASE_URL` com protocolo `mysql://`/`mysql2://` → `TLS_MYSQL_DATABASE_URL` |
| **SQLite** | `DATABASE_URL` contendo `:memory:`, `sqlite://…` ou `file://…` |

Sem nenhuma URL, Bun monta a conexão a partir dos parâmetros individuais:

| PostgreSQL | Fallbacks | Default |
| --- | --- | --- |
| `PGHOST` | — | `localhost` |
| `PGPORT` | — | `5432` |
| `PGUSERNAME` | `PGUSER`, `USER`, `USERNAME` | `postgres` |
| `PGPASSWORD` | — | vazio |
| `PGDATABASE` | — | o nome do usuário |
| `PGSSLMODE` | — | **`disable`** |

Para MySQL o par correspondente é `MYSQL_HOST` (`localhost`), `MYSQL_PORT` (`3306`), `MYSQL_USER` (`root`), `MYSQL_PASSWORD` (vazio) e `MYSQL_DATABASE` (`mysql`).

Três coisas que essa tabela deixa de armadilha:

1. **`DATABASE_URL` é o único nome compartilhado pelos três adapters**, e é ele que decide o dialeto pelo formato. Trocar `postgres://…` por `mysql://…` numa variável de ambiente troca o banco **e o dialeto de SQL** sem tocar em uma linha de código — e a doc avisa que variáveis específicas de PostgreSQL como `POSTGRES_URL` e `PGHOST` são **ignoradas** quando o adapter resolvido é SQLite.
2. **`PGSSLMODE` tem default `disable`**, igual à opção `ssl` do construtor. A variável de ambiente não conserta o default; ver `BUN-DATA-09`.
3. **`POSTGRES_URL` vence `DATABASE_URL`** segundo os rótulos da fonte (*primary* × *alternative*). Uma máquina que tem as duas apontando para bancos diferentes — típico de quem herdou `DATABASE_URL` de outra ferramenta — conecta na que você não esperava.

A fonte **rotula** as variáveis (*primary*, *alternative*) em vez de numerar uma precedência; não há na página um algoritmo explícito de resolução. Trate a ordem acima como o que a fonte declara, e **defina uma variável só** em ambiente de produção em vez de confiar na desambiguação.

Há ainda um flag de runtime relacionado: `bun --sql-preconnect index.js` estabelece a conexão PostgreSQL na inicialização, usando essas mesmas variáveis, para que a primeira query não pague a latência de conexão. Falha de conexão nesse caminho é tratada sem derrubar a aplicação.

**O pool não abre conexão até a primeira query.** Configuração e defaults relevantes:

```ts
import { SQL } from "bun";

const sql = new SQL({
  // ou a URL: postgres://user:senha@host/db?sslmode=verify-full
  max: 20,                // conexões simultâneas
  idleTimeout: 30,        // s até fechar conexão ociosa
  maxLifetime: 3600,      // s de vida máxima de uma conexão
  connectionTimeout: 10,  // s para estabelecer
  ssl: "verify-full",     // disable | prefer | require | verify-ca | verify-full
});

// encerramento ordenado: espera as queries em voo
await sql.close();
await sql.close({ timeout: 5 }); // ou com prazo; { timeout: 0 } fecha na hora
```

**`ssl` tem default `"disable"`.** A tabela da doc é literal: *"Default mode if none specified"*. Conexão a banco gerenciado sem declarar `sslmode` falha ou trafega em claro — nunca deixe implícito em produção.

**Conexão reservada.** `sql.reserve()` tira uma conexão do pool para uso isolado (`SET LOCAL`, advisory lock, `LISTEN`). **Precisa ser devolvida**: `reserved.release()` no `finally`, ou `using reserved = await sql.reserve()`. Esquecer vaza uma conexão do pool por chamada, e o serviço trava quando `max` é atingido.

**Outras primitivas verificadas:**

- **Queries são lazy** — só executam no `await` ou em `.execute()`. `query.cancel()` cancela uma em andamento.
- **`` sql`…`.simple() ``** roda múltiplos statements num único comando (protocolo simples do PostgreSQL) e **não aceita parâmetros**. É o caminho para migração.
- **`sql.file(caminho, params?)`** lê e executa SQL de arquivo.
- **`LISTEN`/`NOTIFY`** com `sql.listen()` / `sql.notify()` — barramento leve entre processos que compartilham o banco (invalidação de cache, acordar worker).
- **`sql.array([...])`** gera literal de array do PostgreSQL. A doc ressalva: **PostgreSQL apenas**, e *"multi-dimensional arrays and NULL elements may not be supported yet"*.

Ver `PostgreSQL` para o lado do servidor e para o desenho das listagens.

| ID | Regra |
| --- | --- |
| `BUN-DATA-09` | Conexão a banco remoto **MUST** declarar `ssl` explicitamente — o default de `Bun.sql` é `"disable"`. |
| `BUN-DATA-10` | Conexão obtida por `sql.reserve()` **MUST** ser liberada por `release()` em `finally` ou pelo `using` — caso contrário vaza do pool. |

---

## 6. Redis e S3: os outros dois clientes embutidos

**Redis.** `import { redis, RedisClient } from "bun"`. O singleton lê, nesta ordem de precedência, `REDIS_URL`, depois `VALKEY_URL`, com fallback para `redis://localhost:6379`. A conexão é lazy: abre no primeiro comando. Requisito declarado: **Redis 7.2 ou superior**.

Cobertura verificada: strings (`get`/`set`/`getBuffer`/`del`/`exists`/`expire`/`ttl`), numéricos (`incr`/`decr`), hashes (`hmset`/`hmget`/`hget`/`hincrby`/`hincrbyfloat`), sets (`sadd`/`srem`/`sismember`/`smembers`/`srandmember`/`spop`).

**Pub/Sub entrou em Bun 1.2.23 e está marcado experimental** — a doc diz esperar que seja estável, mas ainda coletando feedback. Não é base para entrega crítica de mensagem hoje.

**S3.** `Bun.s3` é um singleton equivalente a `new Bun.S3Client()`. `client.file(chave)` devolve uma **referência preguiçosa**: nenhuma rede acontece até você chamar algo. `S3File` estende `Blob`, então `.text()`, `.json()`, `.arrayBuffer()`, `.slice(a, b)` e `.stream()` funcionam. Upload multipart de arquivo grande é automático; `.writer({ retry, queueSize, partSize })` dá controle.

Três pontos que mudam arquitetura:

1. **Presign** substitui proxy. `s3.presign(chave, { expiresIn, method, acl, contentDisposition })` gera URL assinada; o browser fala direto com o S3 e seu servidor não vira intermediário de bytes. **O default é `GET` expirando em 24 horas** — longo demais para quase tudo.
2. **`new Response(s3file)` devolve um `302`** com `Location` apontando para uma URL presignada. É o jeito mais barato de servir download a partir de um handler.
3. **Credenciais são lidas na inicialização, e não de `process.env`.** A doc é literal: Bun lê de arquivos `.env` ou do ambiente do processo *"at initialization time (Bun does not use `process.env` for this)"*. Atribuir `process.env.S3_ACCESS_KEY_ID` em runtime **não** afeta o cliente. Ordem: `S3_*` primeiro, `AWS_*` como fallback.

```ts
import { S3Client } from "bun";

const bucket = new S3Client({ bucket: "uploads-app", endpoint: process.env.S3_ENDPOINT });

Bun.serve({
  routes: {
    // o cliente envia direto ao S3; o servidor só assina
    "/uploads/:chave": {
      POST: (req) => {
        const url = bucket.presign(req.params.chave, {
          expiresIn: 300,        // 5 min — o default de 24 h é longo demais
          method: "PUT",         // sem isto, seria GET
          type: "application/pdf",
        });
        return Response.json({ url });
      },

      // 302 para URL presignada, sem passar os bytes pelo servidor
      GET: (req) => new Response(bucket.file(req.params.chave)),
    },
  },
});
```

O terceiro ponto é exatamente o que descreve, e o motivo de importar em produção.

| ID | Regra |
| --- | --- |
| `BUN-DATA-11` | Presigned URL **MUST** declarar `expiresIn` e `method` explicitamente (o default é `GET` por 24 h), e as credenciais de S3 **MUST** estar no ambiente antes da inicialização — atribuição a `process.env` em runtime **NEVER** é lida pelo cliente. |

---

## 7. A fronteira: o driver devolve `any`

**Conceito.** Nenhum dos clientes valida o formato do que volta. Uma consulta `` sql`SELECT * FROM usuarios` `` devolve linhas cujo tipo você **declarou**, não que foi verificado. O schema mudou, uma coluna virou nula, uma migração rodou pela metade — o TypeScript continua satisfeito e o erro aparece três camadas adiante.

Isso não é defeito do driver: é a fronteira normal entre um sistema externo e o seu. A resposta é a mesma de qualquer outra fronteira — validar na borda com e derivar o tipo do schema em vez de escrever os dois.

```ts
import { z } from "zod";
import { sql } from "bun";

const Pedido = z.object({
  id: z.string().uuid(),
  cliente_id: z.string().uuid(),
  total: z.number().nonnegative(),
  criado_em: z.coerce.date(),
});
type Pedido = z.infer<typeof Pedido>;   // tipo derivado do schema, fonte única

export async function listarPedidos(clienteId: string): Promise<Pedido[]> {
  const linhas = await sql`SELECT * FROM pedidos WHERE cliente_id = ${clienteId}`;
  return z.array(Pedido).parse(linhas); // erro aqui, não três camadas adiante
}
```



| ID | Regra |
| --- | --- |
| `BUN-DATA-12` | Resultado de query que cruza a fronteira HTTP **MUST** passar por validação de schema — o driver devolve `any` tipado por declaração, não por verificação. |

---

## 8. ORM: onde ainda paga o próprio peso

Com drivers embutidos, a pergunta "ainda preciso de ORM?" tem resposta por eixo, não por gosto. A doc oficial mantém guias para Drizzle e Prisma rodando sob Bun (`Prisma`).

| O que você precisa | Driver embutido | ORM |
| --- | --- | --- |
| Executar SQL, tipado por declaração | **suficiente** | overhead |
| **Migração versionada e reversível** | não existe em Bun | **é o motivo principal** |
| Tipos gerados a partir do schema real | não | **sim** |
| Query builder componível para filtro dinâmico | `sql()` cobre casos simples | **melhor** em filtros combinatórios |
| Relacionamento com carga em uma query | você escreve o JOIN | **sim** |
| Um schema, vários bancos | `Bun.sql` já unifica PG/MySQL/SQLite | equivalente |
| Latência mínima, controle total do SQL | **melhor** | camada a mais |
| Superfície de dependência mínima (edge, binário compilado) | **melhor** | pesa |

Leitura curta: **migração e geração de tipos são o que se compra com um ORM.** Se o projeto já resolve migração com outra ferramenta e o schema é estável, o driver embutido cobre bem. Se o schema evolui toda semana e várias pessoas mexem, a ausência de migração em Bun vira o gargalo — e Drizzle, mais leve, costuma ser o meio-termo: gera migração e tipos, e continua deixando você escrever SQL. Referência conduzida em [Drizzle ORM](drizzle-orm.md).

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `` db.query(`… WHERE id = '${id}'`) `` | **SQL injection.** O valor é parseado como SQL | parâmetro `$id` / `?` — `BUN-DATA-03` |
| `` sql.unsafe(`… WHERE email = '${email}'`) `` | `sql.unsafe` não escapa nada, por definição | parâmetro posicional `$1` — `BUN-DATA-04` |
| Nome de coluna do usuário direto em `sql(coluna)` | escapar identificador não é validar; a coluna pode ser qualquer uma da tabela | allowlist antes — `BUN-DATA-05` |
| `new Database(path)` sem `strict: true` | parâmetro nomeado com typo não lança; a query roda errada em silêncio | `strict: true` — `BUN-DATA-01` |
| `db.query(...)` dentro do loop | recompila/consulta o cache a cada iteração e evicta entradas quentes (cache de 20) | statement fora do loop — `BUN-DATA-02` |
| Usar `.get()` sem testar `null` | `.get()` devolve `null` quando não há linha; o acesso seguinte lança | checar antes de acessar propriedade |
| Ler `bigint` do banco sem `safeIntegers` | acima de 2^53 a precisão some sem erro nenhum | `safeIntegers: true` — `BUN-DATA-01` |
| `sql` global dentro de `sql.begin` | a query pega outra conexão do pool e fica fora da transação; o rollback não a alcança | usar o `tx` — `BUN-DATA-07` |
| `sql.reserve()` sem `release()` | vaza uma conexão por chamada até `max`; o serviço trava | `finally` ou `using` — `BUN-DATA-10` |
| SQLite em arquivo sem WAL | leitores bloqueiam o escritor e vice-versa | `PRAGMA journal_mode = WAL` — `BUN-DATA-08` |
| Conectar em Postgres gerenciado sem `sslmode` | o default de `Bun.sql` é `"disable"`, e o de `PGSSLMODE` também | `ssl: "verify-full"` — `BUN-DATA-09` |
| Tratar `Bun.sql` como "o driver Postgres do Bun" | a mesma API cobre MySQL e SQLite; o adapter sai do **formato da URL** | reconhecer que trocar `DATABASE_URL` troca o dialeto — § 1 |
| Definir `POSTGRES_URL` e `DATABASE_URL` apontando para bancos diferentes | a fonte rotula `POSTGRES_URL` como *primary*; conecta-se na que você não esperava | uma variável só por ambiente — § 5 |
| Duas escritas na mesma função sem transação e sem comentário | existe um instante lido por outro processo com metade aplicada | `sql.begin` / `db.transaction`, ou comentar a exceção — `BUN-DATA-06` |
| `s3.presign(chave)` sem opções | URL `GET` válida por 24 h vazando em log ou histórico | `expiresIn` + `method` — `BUN-DATA-11` |
| Setar `process.env.S3_*` no boot da app | o cliente S3 lê o ambiente na inicialização, não de `process.env` | exportar antes do processo — `BUN-DATA-11` |
| Devolver a linha do banco direto no `Response.json` | o tipo foi declarado, não verificado; drift de schema vira erro no cliente | validar na fronteira — `BUN-DATA-12` |

---

## Checklist de revisão

- [ ] Nenhum SQL montado por concatenação ou template fora da tag `sql`? → `BUN-DATA-03`
- [ ] Nenhum `sql.unsafe` com entrada externa? → `BUN-DATA-04`
- [ ] Identificadores dinâmicos validados por allowlist? → `BUN-DATA-05`
- [ ] `strict: true` (e `safeIntegers` onde couber) em toda `Database`? → `BUN-DATA-01`
- [ ] Statements fora dos loops quentes? → `BUN-DATA-02`
- [ ] Todo `.get()` trata `null`?
- [ ] Toda função com duas ou mais escritas está em transação (ou tem a exceção comentada), e todas as queries saem do `tx`? → `BUN-DATA-06`, `BUN-DATA-07`
- [ ] A conexão vem de **uma** variável de ambiente definida, e o adapter resolvido é o esperado? → § 5
- [ ] WAL habilitado no SQLite em arquivo? → `BUN-DATA-08`
- [ ] `ssl` declarado na conexão remota? → `BUN-DATA-09`
- [ ] Toda `reserve()` tem `release()`? → `BUN-DATA-10`
- [ ] Presign explícito e credenciais no ambiente antes do boot? → `BUN-DATA-11`
- [ ] Resultado validado antes de sair pela API? → `BUN-DATA-12`
- [ ] Existe uma ferramenta de migração escolhida? (Bun não tem uma)

---

## Relacionados

- [Bun](bun.md) — hub
- [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Bun - Runtime e APIs](bun-runtime-e-apis.md) · [Bun - Bundler e Build](bun-bundler-e-build.md) · [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) · [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) · [Bun - Testes](bun-testes.md)
- `PostgreSQL` · [Drizzle ORM](drizzle-orm.md) · `Prisma` · ·
- · ·
- ·
- ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [SQLite](https://bun.com/docs/runtime/sqlite) — `Database`, `strict`, `query`/`prepare`, executores, transações, WAL, `safeIntegers`
- [SQL](https://bun.com/docs/runtime/sql) — tagged template, helpers, pooling, `begin`/`savepoint`, `unsafe`, `simple`, SSL, `LISTEN`/`NOTIFY`
- [S3](https://bun.com/docs/runtime/s3) — `S3Client`, `S3File`, presign, credenciais
- [Redis](https://bun.com/docs/runtime/redis) — cliente, env vars, Pub/Sub
- [Drizzle com Bun](https://bun.com/docs/guides/ecosystem/drizzle) · [Prisma com Bun](https://bun.com/docs/guides/ecosystem/prisma)
- Versão: `https://registry.npmjs.org/bun/latest` → **1.3.14**

**Notas de verificação** — pontos em que a fonte contraria o que se assume por hábito:

- **`Bun.sql` não é marcado como experimental** em nenhum ponto da página, e cobre **PostgreSQL, MySQL e SQLite** pela mesma API — **não é um cliente Postgres**. O adapter é escolhido pelo **formato da URL**: `mysql://`/`mysql2://` → MySQL; `:memory:`, `sqlite://`, `sqlite:`, `file://`, `file:` → SQLite; qualquer outro formato → PostgreSQL, que é o default.
- **As variáveis de ambiente de `Bun.sql` têm nome, e a doc os lista.** PostgreSQL: `POSTGRES_URL` (*primary*), `DATABASE_URL` (*alternative, auto-detected*), `PGURL`, `PG_URL`, `TLS_POSTGRES_DATABASE_URL`, `TLS_DATABASE_URL`; sem URL, `PGHOST`/`PGPORT`/`PGUSERNAME` (com fallbacks `PGUSER`, `USER`, `USERNAME`)/`PGPASSWORD`/`PGDATABASE`/`PGSSLMODE`. MySQL: `MYSQL_URL` (*checked first*), `MYSQL_HOST`/`MYSQL_PORT`/`MYSQL_USER`/`MYSQL_PASSWORD`/`MYSQL_DATABASE`, `TLS_MYSQL_DATABASE_URL`. **Não verificado:** um algoritmo explícito de precedência — a fonte rotula (*primary* × *alternative*) em vez de numerar.
- **`PGSSLMODE` também tem default `disable`**, então usar variável de ambiente em vez da opção `ssl` não conserta o default.
- **Variáveis específicas de PostgreSQL (`POSTGRES_URL`, `PGHOST`) são ignoradas quando o adapter resolvido é SQLite** — a doc diz isso explicitamente.
- **Existe `bun --sql-preconnect`**, que abre a conexão PostgreSQL antes do código da aplicação rodar; falha de conexão ali não derruba o processo.
- **O default de `ssl` em `Bun.sql` é `"disable"`**, declarado literalmente na tabela de SSL modes.
- **O default de `bun:sqlite` NÃO lança quando um parâmetro nomeado falta.** Só com `strict: true`. É a razão de `strict` ser regra e não sugestão.
- **`db.query()` cacheia o statement compilado; o cache tem 20 entradas** (`Database.MAX_QUERY_CACHE_SIZE`). `.prepare()` não cacheia — é a opção certa para SQL dinâmico.
- **`.get()` devolve `null`** (não `undefined`) quando não há linha.
- **Credenciais de S3 são lidas na inicialização e não de `process.env`** — a doc afirma isso explicitamente.
- **`new Response(s3File)` produz um `302`** para URL presignada, não o conteúdo do arquivo.
- **Redis Pub/Sub é experimental**, adicionado em Bun 1.2.23. O restante do cliente Redis não tem essa marcação.
- **`sql.array` é exclusivo de PostgreSQL**, e a doc ressalva que arrays multidimensionais e elementos `NULL` podem não funcionar.
- **Em macOS os arquivos `-wal` e `-shm` persistem após `close()`** porque Bun usa o SQLite do sistema, que a Apple compila com WAL persistente. Em Linux e Windows costumam ser removidos.
- **Bun não tem sistema de migração.** `sql.file` e `.simple()` executam scripts; versionamento e rollback são externos.
- Transações de `bun:sqlite` aninhadas viram **savepoints**, e há variantes `.deferred()`, `.immediate()`, `.exclusive()`.
