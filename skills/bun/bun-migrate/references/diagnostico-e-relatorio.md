# Diagnóstico, formato do achado e o corte

| Sintoma | Causa provável | Regra |
| --- | --- | --- |
| `Bun is not defined` | rodando sob `node`, ou shebang `node` sem `--bun` | `BUN-CORE-01` |
| erro de tipo só em runtime | não há `tsc --noEmit` no CI | `BUN-CORE-02` |
| `require()` falha num módulo do projeto | top-level `await` no módulo | `BUN-CORE-04` |
| flag de runtime ignorada | veio depois do subcomando | `BUN-CORE-07` |
| trace vazio, métrica constante | `async_hooks` é stub | `BUN-SYS-09` |
| trace some ao entrar em worker | `AsyncLocalStorage` não cruza | `BUN-SYS-06` |
| mensagem deformada entre processos | IPC "advanced" entre Bun e Node | `BUN-SYS-10` |
| cifra ou curva não suportada | lacuna de cripto | `BUN-SYS-08` |
| erro de cliente em todo deploy | sem dreno de `SIGTERM` | `BUN-SYS-11` |
| container não sobe sem rede | auto-install no boot | `BUN-RT-12` |
| comando externo com injeção | `child_process.exec` concatenado | `BUN-SYS-01` |

**As duas primeiras linhas resolvem a maior parte dos "não roda"**, e nenhuma delas é sobre compatibilidade de módulo.

---

## Passo 6 — Formato de saída de um achado

```
`ID-DA-REGRA` — <onde>
Sintoma: <como se apresenta>
Evidência: <a saída do comando de enumeração, ou o log>
Causa: <uma frase>
Correção: <mudança concreta, ou "bloqueia a migração">
Ver [[Satélite correspondente]].
```

### Exemplo

```
`BUN-SYS-09` — node_modules/@elastic/apm-node (dependência transitiva)
Sintoma: após migrar, o APM instala e roda, sem erro, e nenhum trace aparece no painel.
Evidência: Passo 1, segunda busca — 14 ocorrências de require('async_hooks') dentro de
  @elastic/apm-node; nenhuma no nosso código.
Causa: createHook e executionAsyncId são stubs em Bun — devolvem valor em vez de lançar,
  então a instrumentação registra e nunca é chamada.
Correção: não é conserto de configuração. Ou o serviço fica em Node, ou a observabilidade
  passa a ser instrumentação explícita (OpenTelemetry com propagação manual de contexto,
  e o trace id na mensagem ao worker — BUN-SYS-06).
Ver [[Bun - Shell, FFI e Compat Node]].
```

Regras do formato: **ID conferido na § 6**; **evidência é a saída da enumeração**, não impressão; e quando a lacuna **bloqueia**, diga isso em vez de propor contorno.

---

## Passo 7 — O corte: o que não é incompatibilidade

Quatro casos que se apresentam como "o Bun não suporta" e não são:

| Sintoma | Não é compatibilidade — é |
| --- | --- |
| erro de tipo em runtime | `tsc --noEmit` ausente (`BUN-CORE-02`) |
| `Bun is not defined` | processo errado (`BUN-CORE-01`) |
| dependência não instalou o binário | `trustedDependencies` substituindo a lista padrão — [[bun-workspace]] (`BUN-PKG-04`) |
| resultado muda entre execuções | `--hot` onde precisava de `--watch` (`BUN-RT-11`) |

**E o inverso, mais perigoso:** concluir que "funciona" porque não deu erro. Os stubs de `async_hooks` (§ 2.2) são exatamente isso — e é a razão de `BUN-CORE-05` proibir supor.

---

