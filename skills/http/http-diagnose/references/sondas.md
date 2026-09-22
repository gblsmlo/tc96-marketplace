# As cinco sondas

```bash
bash ~/.claude/skills/http-diagnose/scripts/sondas-cors.sh https://api.local/faturas http://localhost:5173
```

O que separa esta skill de tentativa e erro. `curl` **não faz CORS** — e é exatamente por isso que ele é útil: ele mostra o que o servidor responde, sem o browser no meio.

```bash
# 1. o servidor responde? (elimina o primeiro nó da árvore)
curl -i https://api.local/faturas

# 2. o preflight é tratado?
curl -i -X OPTIONS https://api.local/faturas \
  -H 'Origin: http://localhost:5173' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type,authorization'

# 3. a origem é ecoada, e há Vary?
curl -isS https://api.local/faturas -H 'Origin: http://localhost:5173' \
  | grep -i 'access-control\|vary'

# 4. e quando a origem é RECUSADA — ainda há Vary: Origin?
curl -isS https://api.local/faturas -H 'Origin: https://malicioso.example' \
  | grep -i 'access-control\|vary'

# 5. charset
curl -isS https://api.local/relatorio.csv | grep -i 'content-type'
```

**A sonda 2 é a que mais rende:** se ela devolver `401`, `404` ou `405`, o problema é o preflight e não a chamada real. E **a sonda 4 é a que quase ninguém roda** — é ela que pega `HTTP-CORS-03` violada.

---

