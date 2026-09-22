# Exemplo trabalhado — revisão de suíte sob `bun test`

Monorepo, 180 testes, CI verde, e um defeito de pagamento chegou em produção.

---

## Passo 1 — as sondas, antes de ler teste nenhum

```
$ bash scripts/sondas.sh --rodar

== S1. Teste que nunca roda
./apps/api/test/webhookTests.ts ← fora do padrão de descoberta
== S6. Restauração de mock existe?
 bunfig.toml:4: preload = ["./test/setup.ts"]
 NENHUM mock.restore na suíte
== S7. Marcas e comandos
 apps/web/test/carrinho.test.ts:12: test.only(
.github/workflows/ci.yml:29: bun test -u
== S5. O portão de cobertura fecha?
 bunfig.toml:8: coverageThreshold = { statements = 80 }
== S2. Dependência de ordem → exit≠0 (FALHOU)
== S3. Dependência do global → exit=0 (passou)
== S4. Flaky que não é de ordem → exit=0
```

**S1 e S5 dispararam parada.** E S2 falhando com S3 passando é a assinatura clássica:
o estado vaza pelo `globalThis` compartilhado, e `--isolate` esconde o sintoma.

## Passo 2 — a leitura, guiada pelas sondas

`test/setup.ts` não tem `afterEach( => mock.restore)`. Dois arquivos usam `spyOn` sem
restaurar. E `apps/api/test/pagamento.test.ts:34` tem `expect` dentro de `catch`, sem
contagem — o teste passa quando `cobrar` **não** lança, que é exatamente o defeito que
chegou em produção.

## O relatório

```markdown
## Revisão de suíte — bun test

### Bloqueante (4)

`BUN-TEST-01` — apps/api/test/webhookTests.ts
S1: o nome não casa nenhum padrão de descoberta. O arquivo nunca rodou, e nada avisa.
Correção: renomear para webhook.test.ts. Rodar depois: ele pode estar vermelho há meses.
Ver Bun - Testes - Execução e Configuração.

`BUN-TEST-06` — apps/api/test/pagamento.test.ts:34
A asserção vive no catch e o teste passa quando cobrar não lança: nenhuma asserção roda.
Correção: expect.assertions(1) no topo, ou trocar por
 await expect(cobrar(...)).rejects.toThrow(PagamentoRecusado).
Ver Bun - Testes - Escrita e Asserções.

`BUN-TEST-28` — bunfig.toml:8
S5: coverageThreshold declarado em `statements`, que não é a métrica avaliada.
O portão nunca reprovou.
Correção: usar `lines`/`functions`, e manter o reporter `text` na lista (BUN-TEST-27).
Ver Bun - Testes - Cobertura e CI.

`BUN-TEST-05` —.github/workflows/ci.yml:29
S7: `bun test -u` no CI reescreve os snapshots a cada execução: eles nunca falham.
Correção: remover o -u. Atualizar snapshot é ato local e revisado.
Ver Bun - Testes - Escrita e Asserções.

### Alta (2)

`BUN-TEST-02` — test/setup.ts (ausência) + apps/web/test/preco.test.ts:9
S6 + S2: o preload não restaura mocks, e `bun test --randomize` falha. Dois arquivos usam
 spyOn sem restaurar; o estado vaza pelo globalThis compartilhado (S3 passou, que é a
 assinatura desse vazamento).
Correção: afterEach( => mock.restore) no preload — uma linha que fecha a classe inteira.
 Depois, rodar --randomize de novo: o que continuar falhando é dependência de ordem real.
Ver Bun - Testes - Mocks e Tempo.

`BUN-TEST-08` — apps/web/test/carrinho.test.ts:12
S7: test.only commitado. Se o CI rodar esse arquivo, ele roda 1 teste de N.
Correção: remover.
Ver Bun - Testes - Escrita e Asserções.

### Não é achado (registrado)

- Cobertura de 61% em apps/api: cobertura baixa não é achado desta skill — o achado é o
 limiar decorativo, acima.
- "Deveriam usar Vitest": preferência de ferramenta, fora de escopo.

### Não verificado

- S4 rodou com a suíte já quebrada por S2; repetir depois de corrigir o preload.
- Comportamento sob `--parallel` não foi exercitado: se algum teste usa recurso externo,
 BUN-TEST-10 entra em jogo e exige chave derivada de BUN_TEST_WORKER_ID.
```

## O que este exemplo demonstra

| Decisão | Onde está a regra |
| --- | --- |
| duas paradas dispararam antes da leitura | `sondas.md` |
| S2 falhando **com** S3 passando nomeou a causa | `ordem-da-varredura.md` § *Diagnóstico de flaky* |
| a correção do vazamento é **uma linha no preload**, não arquivo por arquivo | `BUN-TEST-02` |
| cobertura baixa não virou achado; o limiar decorativo virou | `severidade-e-relatorio.md` |
| a sonda que rodou sobre suíte quebrada foi declarada como não conclusiva | § *Fechar* |
