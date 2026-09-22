# Exemplo trabalhado

Tarefa: *"job que lê um CSV de um diretório, valida, e chama um binário externo para converter"*.

```ts
import { readdir } from 'node:fs/promises'; // diretório é node:fs — BUN-RT-01
import { z } from 'zod';

const env = z.object({ // validado na inicialização — BUN-RT-06
 ENTRADA_DIR: z.string.min(1),
 CONVERSOR: z.string.min(1),
}).parse(process.env);

const arquivos = await readdir(env.ENTRADA_DIR);

for (const nome of arquivos) {
 const arquivo = Bun.file(`${env.ENTRADA_DIR}/${nome}`);

 if (!(await arquivo.exists)) continue; //.exists, não size === 0 — BUN-RT-03

 const texto = await arquivo.text; // só aqui houve leitura — BUN-RT-02
 if (!texto.trim) continue;

 // interpolação escapa o valor; nunca concatenação — BUN-SYS-01
 await Bun.$`${env.CONVERSOR} -- ${nome}`.quiet;
}
```

**O que as decisões evitaram:**

| Decisão | Alternativa que quebra | Regra |
| --- | --- | --- |
| `readdir` de `node:fs` | `Bun.file` para listar diretório | `BUN-RT-01` |
| `await arquivo.exists` | `arquivo.size === 0`, que não distingue vazio de ausente | `BUN-RT-03` |
| leitura só no `.text` | assumir que `Bun.file` já leu, e ramificar em dado vazio | `BUN-RT-02` |
| env validado com Zod | interface merging, que dá tipo sem garantia | `BUN-RT-06` |
| interpolação de `Bun.$` | `exec(\`${conversor} ${nome}\`)`, com injeção por nome de arquivo | `BUN-SYS-01` |
| `--` antes do argumento | nome começando com `-` interpretado como flag | `BUN-SYS-03` |
| job com `--watch`, não `--hot` | estado sujo entre execuções | `BUN-RT-11` |

E o que **não** aparece porque este é um job e não um handler: se fosse rota HTTP, o `Bun.$` síncrono e qualquer `*Sync` estariam proibidos (`BUN-RT-08`).

---

