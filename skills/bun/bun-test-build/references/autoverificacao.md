# Autoverificação antes de entregar

Não entregue teste sem passar por esta lista. Cada linha é uma falha que fica **verde**:

- [ ] O arquivo casa um padrão de descoberta? → `BUN-TEST-01`
- [ ] Toda asserção em `catch`, callback ou `if` tem `expect.assertions(n)`? → `BUN-TEST-06`
- [ ] Todo `spyOn` tem restauração garantida? → `BUN-TEST-02`
- [ ] Nenhum `mock.module` conta com restauração automática? → `BUN-TEST-03`
- [ ] Nenhum `.only`, e bug conhecido está em `test.failing`? → `BUN-TEST-08`, `BUN-TEST-11`
- [ ] Nenhum `Bun.sleep` esperando render ou timer?
- [ ] Snapshot de objeto com campo variável usa property matchers? → `BUN-TEST-19`
- [ ] Componente: `cleanup` presente e todo `userEvent` aguardado? → `BUN-TEST-26`
- [ ] Data formatada tem fuso fixo? → `BUN-TEST-21`
- [ ] Teste concorrente não compartilha estado mutável? → `BUN-TEST-23`

E as duas que exigem execução, não leitura:

```bash
bun test./caminho/do-novo.test.ts # passa isolado
bun test --randomize # a suíte ainda passa em ordem aleatória
tsc --noEmit # o runner não checa tipo — BUN-TEST-18
```

**Rode as três de verdade.** "Deve passar" não é verificação: se não rodou, declare que não rodou. Se `--randomize` quebrou depois do seu teste, você acabou de introduzir dependência de ordem (`BUN-TEST-09`): o setup de que ele depende precisa entrar no próprio arquivo, e nenhuma flag substitui isso. O diagnóstico completo é `bun-test-review`.

---

## O que entregar

Três partes, sempre, e a terceira é a que costuma faltar:

1. **O código** — o teste ou a configuração, no padrão que a suíte já usa. Se o repositório tem o padrão certo em outro arquivo, estenda esse padrão em vez de introduzir um novo.
2. **O que foi executado**, com o resultado: quais dos três comandos acima rodaram e o que devolveram. Cole a saída quando ela for o argumento.
3. **O que não foi verificado**, nomeado. Suíte que não sobe, banco fora do ar, `tsc` não rodado: diga qual e por quê. **"Deve passar" não é resultado** — declarar a lacuna é o que separa entrega verificada de entrega plausível.

---


---

## Script

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-test-build/scripts/autoverificar.sh test/sessao.test.ts
```

Ele cobre os itens mecânicos e marca como **heurísticos** os quatro que exigem leitura
(asserção em `catch`, fuso, `cleanup`, `userEvent` aguardado).
