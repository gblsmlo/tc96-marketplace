# Hash, senha, e `--watch` × `--hot`

```
É senha, token ou segredo?
├── SIM → Bun.password (argon2id por default)
└── NÃO → Bun.hash (não criptográfico — cache key, dedup)
```

`BUN-RT-10` é categórica: `Bun.hash` **nunca** toca senha, token ou segredo. Os nomes são parecidos e as garantias são opostas.

---

## Passo 6 — `--watch` × `--hot`

| Flag | O que faz | Quando |
| --- | --- | --- |
| `--watch` | reinicia o processo | quando o estado precisa ser limpo |
| `--hot` | recarrega **mantendo** o estado do processo | desenvolvimento de servidor |

`BUN-RT-11`: `--hot` **nunca** onde o resultado depende de estado limpo — teste, job, verificação de inicialização. O sintoma é resultado que muda entre execuções sem o código mudar.

E em produção, `BUN-RT-12`: `node_modules` presente ou `--no-install`. Sem isso o **auto-install** resolve dependência em runtime, o que faz a imagem depender da rede no boot.

---

