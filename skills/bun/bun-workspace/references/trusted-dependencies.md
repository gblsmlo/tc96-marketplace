# A regra que quebra o build inteiro

> **`trustedDependencies` SUBSTITUI a lista padrão. Não estende.**

Declarar um pacote ali **desliga os scripts de instalação de todo o resto** — `sharp`, `esbuild`, `better-sqlite3`, tudo. O sintoma não é erro de instalação: é um binário que não foi compilado, e a falha aparece em runtime, longe da causa.

```jsonc
// ✗ acabou de desligar os scripts de sharp, esbuild e de toda a lista padrão
"trustedDependencies": ["meu-pacote-interno"]

// ✓ reinclui o que ainda é necessário
"trustedDependencies": ["meu-pacote-interno", "sharp", "esbuild"]
```

`BUN-PKG-04`. E `BUN-PKG-03` completa: um PR que adiciona entrada ali **precisa** trazer no corpo a saída de `bun pm untrusted`, que mostra qual comando será executado. Liberar script de instalação é decisão de segurança — o script roda com as permissões de quem instala.

```bash
bun pm untrusted     # o que está bloqueado, e o comando de cada um
```

---

