# Exemplo trabalhado — auditoria de uma suíte

Repositório de e-commerce, 214 casos, CI verde há meses, e defeito chegando em produção.

---

## Passo 1 — as sondas, antes de abrir teste nenhum

```
$ bash scripts/sondas-suite.sh.

== S1. A forma da suíte
 e2e/ 187 casos
 packages/ 22 casos
 apps/ 5 casos
 ─── total: 214 casos ← 87% em E2E
== S3. A camada estática conta?
 tsconfig.json:4: "strict": false ← e há Playwright no projeto
 -- no-floating-promises: AUSENTE ← bloqueante
== S4. O portão fecha?
.github/workflows/ci.yml:41: continue-on-error: true
== S5. Meta de cobertura
 package.json:22: "coverageThreshold": { "global": { "lines": 80 } }
== S6. Classes de risco
 error 2 arquivos ← de 214 casos
 vazio 0 arquivos
== S9. skip
 e2e/pagamento.spec.ts:14: test.skip("3DS",...)
```

**Duas paradas dispararam ao mesmo tempo** (S1 invertida, S4 sem reprovação). Reporte-as
antes de auditar qualquer interior.

## Passo 2 — o que a leitura acrescenta

Amostragem de 10 arquivos de `e2e/`: **7 verificam regra de negócio**, não jornada
(`TS-NIV-02`). Isso não é forma ruim por acaso — é a causa da forma.

## Passo 3 — o relatório

```markdown
## Auditoria de estratégia de teste — loja

### Bloqueante (2)

`TS-PROC-03` —.github/workflows/ci.yml:41
S4: o job de testes tem continue-on-error: true. O CI nunca reprovou por teste vermelho.
Correção: remover a linha. Se o objetivo era não bloquear enquanto a suíte é instável,
 o caminho é teste-diagnose, não um portão que mente.
Ver Teste de Software - Processo e Artefatos.

`TS-TIPO-08` — tsconfig.json:4 + ausência de no-floating-promises
S3: strict desligado, e sem no-floating-promises num projeto com Playwright — pode haver
 qualquer quantidade de `expect(...)` sem await, e nenhuma aparece como falha.
Correção: ligar strict e a regra de lint; rodar uma vez e tratar o que aparecer como
 inventário de asserções que não afirmam nada.
Ver Teste de Software - Tipos e Atributos de Qualidade, e Playwright PW-CORE-04.

### Alta (3)

`TS-NIV-04` — e2e/ (187 casos) × packages/ (22 casos)
S1: 87% dos casos são E2E. Amostragem de 10 arquivos: 7 verificam regra de negócio.
Correção: mover asserções de regra para unidade; um E2E por jornada. Começar por
 e2e/desconto.spec.ts (23 casos sobre faixas de desconto).
Ver Teste de Software - Níveis e Escopo.

`TS-TIPO-02` — toda a suíte
S6: 2 arquivos mencionam erro, nenhum menciona estado vazio, em 214 casos.
Correção: por fluxo crítico, listar os cinco estados e cobrir erro e vazio no nível de
 componente, que é onde eles custam menos. Começar por checkout e pagamento.
Ver Teste de Software - Tipos e Atributos de Qualidade.

`TS-CORE-05` — package.json:22
S5: coverageThreshold de 80% tratado como portão de qualidade.
Correção: substituir a meta por classe de risco coberta. A cobertura pode continuar
 sendo medida — só não como critério de aprovação.
Ver Teste de Software - Técnicas de Design de Caso.

### Média (1)

`TS-SUI-11` — e2e/pagamento.spec.ts:14
S9: test.skip("3DS") sem motivo nem issue. Pagamento é o fluxo de maior risco do produto.
Correção: issue com prazo, ou remover o teste. Skip anônimo em fluxo crítico é a pior
 combinação: parece coberto e não está.
Ver Teste de Software - Confiabilidade da Suíte.

### Não é achado (registrado para não voltar à discussão)

- Cobertura de 62% em packages/: cobertura baixa não é achado (TS-CORE-05).
- Massa em integração em apps/bff: é trophy, não forma invertida.

### Não verificado

- S2 (duração): a suíte não sobe nesta máquina — sem Docker do banco. A medida por nível
 fica aberta, e ela decide se o portão é executável antes do PR.
- S8 (escape): sem acesso ao histórico completo; o clone é raso.
```

## O que este exemplo demonstra

| Decisão | Onde está a regra |
| --- | --- |
| duas paradas dispararam e vieram antes de tudo | `sondas.md` § *Três paradas obrigatórias* |
| a amostragem de leitura explicou a forma que a sonda mediu | `sondas.md` § *O que a sonda não mede* |
| cobertura baixa e massa em integração **não** viraram achado | `severidade-e-relatorio.md` § *O corte* |
| cada correção tem ponto de partida nomeado | `severidade-e-relatorio.md` § *Formato* |
| o que não rodou foi declarado, não omitido | `severidade-e-relatorio.md` § *Fechar* |
