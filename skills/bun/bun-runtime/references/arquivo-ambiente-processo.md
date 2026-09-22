# Arquivo, ambiente, processo e shell

A árvore está na § 5 do hub. O resumo, e os quatro erros que ela evita:

```
É conteúdo de arquivo (ler, escrever, stream)?
├── SIM → Bun.file / Bun.write
└── NÃO — é operação de DIRETÓRIO (mkdir, readdir, rm, stat)
    → node:fs                                   (BUN-RT-01)
```

| Erro | Por quê | Regra |
| --- | --- | --- |
| tratar `Bun.file(path)` como leitura | a referência é **preguiçosa**; nada é lido até `.text()`/`.json()`/`.bytes()` | `BUN-RT-02` |
| checar existência por `size === 0` | é também o tamanho de um arquivo que não existe — use `await file.exists()` | `BUN-RT-03` |
| esquecer `.end()` num `FileSink` | o processo **não termina** | `BUN-RT-04` |
| usar `Bun.file` para `readdir`/`mkdir` | ele só trata conteúdo | `BUN-RT-01` |

`BUN-RT-03` é a mais insidiosa: o código parece funcionar, e o ramo de "arquivo ausente" nunca é exercitado.

---

## Passo 3 — Ambiente

| Regra | O que exige |
| --- | --- |
| `BUN-RT-05` | segredo de produção **nunca** vem de `.env` carregado pelo runtime |
| `BUN-RT-06` | variável de ambiente **validada na inicialização**; o tipo por interface merging não é garantia |
| `BUN-RT-07` | `$` literal num valor de `.env` **precisa** de `\` — Bun expande variáveis por padrão |

**`BUN-RT-06` é a que o stack já resolve:** validar com Zod na inicialização — [[Zod - Validação de Ambiente]] e [[Variáveis de ambiente validadas]]. Interface merging dá autocomplete e **não** garante que a variável existe; o tipo diz `string` e o valor é `undefined`.

**`BUN-RT-07` produz um bug que ninguém procura no lugar certo:** uma senha com `$` no `.env` chega truncada, e o sintoma é falha de autenticação.

---

## Passo 4 — Processo e shell

```
Preciso rodar algo externo?
├── comando com valor de runtime → Bun.$ com INTERPOLAÇÃO  (BUN-SYS-01)
├── processo de longa duração    → Bun.spawn
└── e NUNCA em handler HTTP      → Bun.spawnSync / *Sync de node:fs  (BUN-RT-08)
```

| Regra | O que exige |
| --- | --- |
| `BUN-RT-08` | handler de servidor **nunca** chama `Bun.spawnSync` nem `*Sync` de `node:fs` — bloqueia o event loop do processo inteiro |
| `BUN-RT-09` | subprocesso de duração não garantida recebe `timeout` ou `signal` |
| `BUN-SYS-01` | comando com valor de runtime usa interpolação de `Bun.$`; `child_process.exec` com string concatenada **nunca** |

**A interpolação de `Bun.$` escapa por você** — é o que torna `BUN-SYS-01` uma regra de segurança, não de estilo. Mas as garantias **param** dentro de um `sh -c`/`bash -c` (`BUN-SYS-02`), e argumento de runtime que começa com `-` precisa de `--` ou de rejeição (`BUN-SYS-03`).

**`BUN-RT-08` é a que mais aparece em código gerado:** um `readFileSync` num handler parece inofensivo e para o servidor inteiro sob carga.

---

