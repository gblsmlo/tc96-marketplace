# Severidade, formato e o corte

---

## Classificação

| Severidade | O que entra |
| --- | --- |
| **Bloqueante** | portão de CI que não reprova (`TS-PROC-03`); `no-floating-promises` desligada com Playwright no projeto; defeito de produção recorrente sem teste (`TS-CORE-06`); flake acima de ~1% (`TS-CORE-04` — e vá para `teste-diagnose`) |
| **Alta** | forma invertida (`TS-NIV-04`); regra de negócio em E2E (`TS-NIV-02`); estado de erro sem cobertura em fluxo crítico (`TS-TIPO-02`); mock do que o teste vem provar (`TS-CORE-03`); meta de cobertura como indicador (`TS-CORE-05`) |
| **Média** | `strict` desligado (`TS-TIPO-08`); requisito não funcional sem número (`TS-TIPO-05`); dado pré-existente compartilhado (`TS-SUI-05`); reteste sem regressão (`TS-TIPO-04`); `skip` sem motivo (`TS-SUI-11`); proporção global (`TS-NIV-08`) |
| **Baixa** | preferência sem ID — **não é achado** |

Dois critérios decidem a fronteira:

- **Bloqueante × Alta:** *a suíte produz verde falso?* Portão que não reprova e asserção que
 não afirma **mentem**; suíte desequilibrada é ineficiente.
- **Alta × Média:** *o risco está descoberto hoje, ou a estrutura é subótima?* Estado de erro
 sem teste em pagamento é risco ativo; `strict` desligado é dívida.

---

## Formato

```
`ID-DA-REGRA` — <onde: arquivo, diretório, ou o workflow>
<o que está errado, uma frase>
Correção: <mudança concreta>
Ver Satélite correspondente.
```

**Para achado de forma, a evidência é a medida** — cole os números da sonda:

```
`TS-NIV-04` — e2e/ (187 casos) × packages/core/ (22 casos)
S1: 89% dos casos da suíte são E2E. A suíte leva 34 min (S2) e ninguém a roda antes do PR.
Amostragem de 10 arquivos de e2e/: 7 verificam regra de negócio, não jornada (TS-NIV-02).
Correção: mover as asserções de regra para unidade em packages/core; manter em E2E
 um caso por jornada crítica, verificando que a tela exibe o valor calculado.
 Começar por e2e/desconto.spec.ts, que tem 23 casos sobre faixas de desconto.
Ver Teste de Software - Níveis e Escopo.
```

Regras do formato:

- **ID conferido no `mapa-de-ids.md`**, e **nunca apelido**.
- **Localização sempre** — arquivo, diretório ou linha do workflow.
- **Números para achado de forma.** "Tem E2E demais" sem contagem é opinião.
- **Correção com ponto de partida.** Numa suíte desequilibrada, "mova as asserções" é inútil sem dizer por qual arquivo começar.

---

## O corte: quatro coisas que **não** são achado

Confundi-las queima a credibilidade do relatório inteiro.

| Não é achado | Vira achado quando… |
| --- | --- |
| **ausência de teste**, isolada | cruzada com **risco**: módulo de pagamento sem teste, ou defeito de produção que voltou (`TS-CORE-06`) |
| **a proporção não bater com pirâmide OU trophy** | só a **forma invertida** (`TS-NIV-04`) é achado — massa em integração é trophy, não erro |
| **cobertura baixa** | achado é a **meta** de cobertura (`TS-CORE-05`), ou uma classe de risco descoberta |
| **preferência de ferramenta** | nunca. "Deveriam usar Vitest em vez de `bun test`" não é achado desta skill |

E um caso **inválido**: citar apelido (`TS-NIV-01`, `TS-DUB-02`, `TS-SUI-02`).

Se a varredura encontrar defeito recorrente e real **sem regra correspondente**, o produto
certo é uma **proposta de regra** para [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md) § 6 — ID sugerido, texto e o
caso que a motivou — não uma citação falsa.

---

## Fechar a auditoria

1. **Transforme sonda em portão.** S3 vira regra de lint no CI; S4 vira o exit code corrigido; S6 vira lista de estados por fluxo crítico; S9 vira issue por `skip`. Achado que só existe no relatório volta em seis meses.
2. **Separe as três conclusões** — não protegido, no nível errado, quebrado.
3. **Ordene por severidade**, não por diretório.
4. **Dê o próximo passo, não a lista inteira.** Aponte o arquivo com maior razão entre casos e valor.
5. **Se houver flake ativo, o relatório para aqui** e continua em `teste-diagnose`: com a suíte não confiável, nenhuma conclusão sobre cobertura é interpretável (`TS-CORE-04`).
6. **Declare o que não foi verificado.** Sonda que não rodou — suíte não sobe, CI inacessível, sem histórico de git — diga qual e por quê. **"Não verificado" não é "sem achado"**.
