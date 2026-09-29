# Worked example

Task: *"a job that reads a CSV from a directory, validates it, and calls an external binary to convert it"*.

```ts
import { readdir } from 'node:fs/promises'; // directory is node:fs — BUN-RT-01
import { z } from 'zod';

const env = z.object({ // validated at startup — BUN-RT-06
 INPUT_DIR: z.string.min(1),
 CONVERTER: z.string.min(1),
}).parse(process.env);

const files = await readdir(env.INPUT_DIR);

for (const name of files) {
 const file = Bun.file(`${env.INPUT_DIR}/${name}`);

 if (!(await file.exists)) continue; //.exists, not size === 0 — BUN-RT-03

 const text = await file.text; // only here did a read happen — BUN-RT-02
 if (!text.trim) continue;

 // interpolation escapes the value; never concatenation — BUN-SYS-01
 await Bun.$`${env.CONVERTER} -- ${name}`.quiet;
}
```

**What these decisions prevented:**

| Decision | Alternative that breaks | Rule |
| --- | --- | --- |
| `readdir` from `node:fs` | `Bun.file` to list a directory | `BUN-RT-01` |
| `await file.exists` | `file.size === 0`, which does not tell empty from missing | `BUN-RT-03` |
| read only at `.text` | assuming `Bun.file` already read, and branching on empty data | `BUN-RT-02` |
| env validated with Zod | interface merging, which gives a type without a guarantee | `BUN-RT-06` |
| `Bun.$` interpolation | `exec(\`${converter} ${name}\`)`, with injection through the file name | `BUN-SYS-01` |
| `--` before the argument | a name starting with `-` read as a flag | `BUN-SYS-03` |
| job with `--watch`, not `--hot` | dirty state between runs | `BUN-RT-11` |

And what does **not** appear here because this is a job and not a handler: were it an HTTP route, synchronous `Bun.$` and any `*Sync` would be forbidden (`BUN-RT-08`).
