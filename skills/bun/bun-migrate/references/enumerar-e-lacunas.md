# Enumerar antes de migrar, e as quatro lacunas

`BUN-SYS-07` é o passo que não se pode pular: enumere os módulos `node:*` usados **pelo código e pelas dependências transitivas**.

```bash
# no próprio código
grep -rnoE "from ['\"]node:[a-z_/]+" src/ | sort -u
grep -rnoE "require\(['\"]node:[a-z_/]+" src/ | sort -u

# e nas dependências — é a metade que costuma faltar
grep -rhoE "require\(['\"](node:)?(async_hooks|worker_threads|crypto|vm|cluster|dgram|inspector|perf_hooks|v8|repl)['\"]" node_modules/ 2>/dev/null | sort | uniq -c | sort -rn | head -20
```

**A segunda busca é a que muda o plano.** Uma dependência que usa `async_hooks` para tracing, ou `crypto` para uma cifra específica, decide a viabilidade da migração — e ela não aparece no código do projeto.

---

## Passo 2 — As quatro lacunas que importam

### 2.1 Cripto

`BUN-SYS-08`: código que depende de **`secp256k1`**, **`argon2`**, **`ed448`/`x448`** ou das cifras **CCM/OCB/XTS/`chacha20-poly1305`** não presume suporte — confira antes.

Isto elimina migrações inteiras: uma biblioteca de assinatura de blockchain (`secp256k1`) ou de token com curva Edwards de 448 bits para no dia 1. E `argon2` costuma vir por dependência de hash de senha — nesse caso a saída é `Bun.password`, que faz argon2id nativamente (`BUN-RT-10`).

### 2.2 Async hooks são stub

`BUN-SYS-09`: **observabilidade nunca se apoia em `createHook`, `executionAsyncId` ou `eventLoopUtilization()`** em Bun — são stubs que **devolvem valor** em vez de lançar.

Este é o pior tipo de incompatibilidade: o APM instala, roda, não dá erro, e produz trace vazio ou métrica constante. A ausência de exceção é o que faz a falha passar pela migração e aparecer semanas depois, como "perdemos observabilidade".

### 2.3 `AsyncLocalStorage` não cruza `Worker`

`BUN-SYS-06`: contexto de rastreamento (trace id, request id) **precisa ir explícito na mensagem** ao `Worker`. `AsyncLocalStorage` não atravessa a fronteira.

Sintoma: o trace some quando o trabalho é delegado a worker, e as duas metades da requisição aparecem desconectadas.

### 2.4 IPC entre runtimes

`BUN-SYS-10`: IPC entre processo Bun e processo Node **usa JSON**. `serialization: "advanced"` só funciona **entre dois Bun**.

Sintoma: mensagem chega deformada ou vazia num pipeline híbrido, sem erro claro.

---

## Passo 3 — O que não vai para produção

`BUN-SYS-05`: **`bun:ffi` e `cc()` nunca entram em caminho de produção** — a própria doc os declara experimentais e recomenda Node-API. Se a migração depende de FFI, o caminho é Node-API, não `bun:ffi`.

---

