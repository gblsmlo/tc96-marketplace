# Exemplo trabalhado — a sessão expira em 30 minutos

Tarefa: *"testar que a sessão expira 30 minutos após o último acesso"*.

**A tarefa é sobre tempo**, então a primeira decisão não é como escrever o teste — é qual API de tempo usar. As "três coisas que não se assumem de memória" já respondem: `useFakeTimers` **não** troca o construtor `Date`; congelar data é `setSystemTime`, e as duas são ortogonais (`BUN-TEST-20`).

```ts
import { test, expect, beforeEach, afterEach, setSystemTime, spyOn } from 'bun:test';
import { sessaoExpirou, registrarAcesso } from '../src/sessao';
import * as audit from '../src/audit';

const T0 = new Date('2026-03-10T12:00:00.000Z');

beforeEach( => setSystemTime(T0));
afterEach( => setSystemTime); // devolve o relógio real

test('sessão não expira antes de 30 min', => {
 registrarAcesso('s1');
 setSystemTime(new Date(T0.getTime + 29 * 60_000));
 expect(sessaoExpirou('s1')).toBe(false);
});

test('sessão expira exatamente em 30 min', => {
 registrarAcesso('s1');
 setSystemTime(new Date(T0.getTime + 30 * 60_000));
 expect(sessaoExpirou('s1')).toBe(true);
});

test('expiração é auditada uma vez', => {
 const log = spyOn(audit, 'registrar');
 registrarAcesso('s1');
 setSystemTime(new Date(T0.getTime + 31 * 60_000));
 sessaoExpirou('s1');
 expect(log).toHaveBeenCalledTimes(1);
 log.mockRestore; // restauração garantida
});
```

**As decisões, e o que cada uma evitou:**

| Decisão | Alternativa que fica **verde e errada** | Regra |
| --- | --- | --- |
| `setSystemTime` para congelar data | `useFakeTimers` — não troca `Date`, e o teste passa por acaso | `BUN-TEST-20` |
| `afterEach( => setSystemTime)` | relógio vazando para os testes seguintes | `BUN-TEST-20` |
| `log.mockRestore` explícito | spy vazando pela suíte inteira | `BUN-TEST-02` |
| 29 / 30 / 31 min | só "passou muito tempo" — não pega `>` × `>=` | valor limite, `Docs/Teste de Software - Técnicas de Design de Caso.md` |
| instante absoluto em UTC | `new Date` real, e o teste falha na virada do dia | `BUN-TEST-21` |
| `expect` no corpo, não em `catch` | asserção que nunca roda | `BUN-TEST-06` |

**O que foi executado**, que é a parte que costuma faltar:

```bash
bun test./test/sessao.test.ts # 3 pass, 0 fail
bun test --randomize # 41 pass — a suíte aguenta ordem aleatória
tsc --noEmit # sem erro
```

**O que não foi verificado:** o comportamento sob `--parallel`, porque este módulo mantém o registro de sessão em memória de processo — se ele passar a usar Redis, `BUN-TEST-10` entra em jogo e o teste precisa de chave por worker.

---

## Fronteira com as outras skills
