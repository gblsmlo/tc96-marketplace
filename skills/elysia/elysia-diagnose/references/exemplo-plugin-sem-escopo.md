# Exemplo trabalhado — plugin de auth que não protege o consumidor

### Exemplo

```
`ELYSIA-LIFE-01` — packages/auth/src/plugin.ts:14
Sintoma: as rotas de apps/server passam sem credencial; as rotas de teste dentro do
 próprio plugin são rejeitadas corretamente.
Evidência: o teste do Passo 6 sobre a instância consumidora devolveu 200, não 401.
 O plugin declara `.onBeforeHandle(verificar)` sem escopo.
Causa: o default do escopo é `local` — o hook não atravessa para a instância que usa
 o plugin. O teste que existia rodava dentro do plugin, então nunca pegou.
Correção: declarar `.onBeforeHandle({ as: 'scoped' }, verificar)`, e mover o teste
 para a instância consumidora (ELYSIA-LIFE-08). Se o hook deve valer em toda a
 árvore, o escopo é `global` (ELYSIA-LIFE-09).
Ver Elysia - Lifecycle e Plugins.
```

Regras do formato: **ID conferido na § 6**; **evidência é teste ou ordem de registro**, não impressão; correção concreta; um link de satélite.

---


---

## O percurso que levou até ali

```
$ bash scripts/sondas.sh src

== S1. Hook registrado DEPOIS da rota
 (nada) ← a hipótese mais comum caiu
== S2. Escopo não declarado em plugin
 packages/auth/src/plugin.ts:14.onBeforeHandle(verificar)
 -- plugins com `name` declarado: NENHUM ← ELYSIA-LIFE-03 também em aberto
```

S1 limpo e S2 apontando o plugin: a hipótese é escopo. **A sonda não prova** — quem prova é
o teste na instância consumidora (`prova-de-escopo.md`), que devolveu 200 onde deveria dar 401.

## O que este exemplo demonstra

| Decisão | Onde está a regra |
| --- | --- |
| a ordem foi conferida **antes** do escopo | `duas-causas.md` |
| a evidência é um teste, não impressão | § *Formato do achado* |
| o teste que existia rodava dentro do plugin, e por isso nunca pegou | `prova-de-escopo.md` |
| a correção nomeia `scoped` **e** diz quando seria `global` | `ELYSIA-LIFE-09` |
