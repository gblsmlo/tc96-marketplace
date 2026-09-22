# The five probes

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/http-diagnose/scripts/sondas-cors.sh https://api.local/invoices http://localhost:5173
```

What separates this skill from trial and error. `curl` **does not do CORS** — and that is exactly why it is useful: it shows what the server answers, without the browser in the way.

```bash
# 1. does the server answer? (eliminates the tree's first node)
curl -i https://api.local/invoices

# 2. is the preflight handled?
curl -i -X OPTIONS https://api.local/invoices \
 -H 'Origin: http://localhost:5173' \
 -H 'Access-Control-Request-Method: POST' \
 -H 'Access-Control-Request-Headers: content-type,authorization'

# 3. is the origin echoed, and is there a Vary?
curl -isS https://api.local/invoices -H 'Origin: http://localhost:5173' \
 | grep -i 'access-control\|vary'

# 4. and when the origin is REFUSED — is Vary: Origin still there?
curl -isS https://api.local/invoices -H 'Origin: https://malicious.example' \
 | grep -i 'access-control\|vary'

# 5. charset
curl -isS https://api.local/report.csv | grep -i 'content-type'
```

**Probe 2 pays most:** if it returns `401`, `404` or `405`, the problem is the preflight and not the real call. And **probe 4 is the one almost nobody runs** — it is what catches a violated `HTTP-CORS-03`.
