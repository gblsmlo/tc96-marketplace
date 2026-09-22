# Fechar a auditoria

1. **Transforme sonda em teste.** S3, S4, S5 e S6 são verificáveis em teste de API — `Docs/Playwright - Rede e Mocking.md` § 5. Achado que só existe no relatório volta em seis meses (`TS-CORE-06` em [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md)).
2. **Separe "erro do time" de "o framework não faz".** A § 8 do hub decide: em `Bun.serve` cru toda regra é responsabilidade explícita; em Hono e Elysia há built-in, e o achado passa a ser o middleware não montado.
3. **Ordene por severidade**, não por arquivo.
4. **Reporte o corpo de erro inconsistente separado.** É contrato público, e cada rota nova amplia o custo (`HTTP-SPEC-08`).
5. **Se houver dado sensível em query string ou CORS como autorização**, reporte primeiro e à parte — são achados de segurança, com prazo diferente.
6. **Declare o que não foi verificado.** Sonda que não rodou — serviço não sobe, ambiente inacessível, CDN no meio — diga qual e por quê. **"Não verificado" não é "sem achado"**, e é a invariante 5 da § 7 do hub: "funcionou no Chrome" não é verificação.

---

