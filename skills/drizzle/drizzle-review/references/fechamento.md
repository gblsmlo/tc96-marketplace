# Fechar a revisão


## Passo 7 — Fechar a revisão

1. **Transforme sonda em teste.** Todo achado das sondas S1–S3 vira um teste que falha na regressão: comparar exports × schema registrado, journal × snapshots, índice × prefixo. Achado que só existe no relatório volta em seis meses.
2. **Verifique se o banco já resolve.** Antes de propor invariante na aplicação, confira `CHECK`, unique parcial, exclusion constraint e RLS —.
3. **Separe o que exige decisão de produto.** Regra de agregação ambígua, teto de listagem e política de retenção não são bug até alguém decidir qual é o comportamento certo. Reporte como pergunta com opções, não como correção.
4. **Ordene por severidade**, não por arquivo.
5. **Declare o que não foi verificado.** Se uma sonda não rodou (banco fora do ar, flag de teste não destravada), diga — não confunda "não verificado" com "sem achado".

