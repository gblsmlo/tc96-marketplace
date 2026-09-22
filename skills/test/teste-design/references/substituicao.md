# O que substituir por dublê

> Passo 5. A árvore é a § 4.2 de [[Teste de Software]]; o corpo é
> [[Teste de Software - Dublês de Teste]].

---

## A pergunta única, antes de qualquer escolha

> **Se a dependência real divergisse do meu dublê, este teste deveria quebrar?**

```
SIM → não substitua. Pegar a divergência é o ponto inteiro (TS-CORE-03)
NÃO → substitua, e escolha o tipo certo:
      só preencher parâmetro  → dummy
      resposta pronta         → stub
      implementação que roda  → fake  (e declare a fidelidade — TS-DUB-03)
      verificar QUE chamou    → mock ou spy
```

---

## Duas regras que valem em qualquer nível

- **Relógio e aleatoriedade: substitua sempre** (`TS-DUB-05`). É onde determinismo se
  compra barato, e é o antídoto de toda espera por tempo real.
- **Estado do servidor: não mocke — crie de verdade** pela API quando houver endpoint
  (`TS-CORE-03`, e `PW-NET-06` em [[Playwright - Rede e Mocking]]).

---

## O vocabulário decide a pergunta seguinte

Um servidor de mentira **que funciona** é um **fake**, não um mock (`TS-DUB-01`). Nomear
certo faz aparecer sozinha a pergunta que decide tudo — *ele honra o contrato real?*

Fake de repositório no lugar de banco controlado é `TS-DUB-08`: o fake passa, e o SQL real
quebra em produção.

---

## Relacionados

- [[Teste de Software - Dublês de Teste]] — a fonte
- [[Teste de Software]] § 4.2 — a árvore
- `arvore-de-nivel.md` — o nível que veio antes
