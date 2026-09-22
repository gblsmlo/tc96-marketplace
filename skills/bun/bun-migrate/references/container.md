# Container

Dois requisitos que decidem se o deploy é seguro, e que costumam faltar.

### 4.1 Encerramento

`BUN-SYS-11`: serviço em container **registra listener de `SIGTERM` (e `SIGINT`)** que drena o servidor.

```ts
const server = Bun.serve({ /* … */ });

for (const sinal of ['SIGTERM', 'SIGINT'] as const) {
 process.on(sinal, async => {
 await server.stop; // drena: para de aceitar, termina o que está em voo
 process.exit(0);
 });
}
```

Sem isso, o orquestrador manda `SIGTERM`, o processo morre imediatamente, e **as requisições em voo são cortadas** — o sintoma é erro de cliente durante todo deploy, e ele é atribuído à rede.

### 4.2 Dockerfile

`BUN-SYS-12`: a imagem de produção **instala com `bun install --frozen-lockfile --production`**, roda como **`USER bun`**, e não usa a tag `latest`.

```dockerfile
FROM oven/bun:1.4.0 # tag fixa, nunca latest
WORKDIR /app
COPY package.json bun.lock./
RUN bun install --frozen-lockfile --production
COPY..
USER bun # não root
CMD ["bun", "run", "start"] # forma explícita — BUN-CORE-06
```

E lembre de `BUN-RT-12`: em produção, `node_modules` presente ou `--no-install`. Sem isso o auto-install resolve dependência **no boot**, e a imagem passa a depender da rede para subir.

---

