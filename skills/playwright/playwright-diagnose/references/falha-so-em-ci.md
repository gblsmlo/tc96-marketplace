# Falha que só acontece em CI

> Quatro causas, em ordem de frequência.

| Causa | Sinal | Conserto |
| --- | --- | --- |
| **CI é mais lento** | timeout de 30 s numa espera legítima | leia o trace **antes** de subir timeout; normalmente o alvo nunca ficou acionável |
| **paridade de ambiente** | screenshot difere por antialiasing de fonte | gere a referência em container com a imagem do CI (`PW-SNAP-02`) |
| **estado de servidor** | workers disputando a mesma conta | conta por worker via `parallelIndex` (`PW-AUTH-03`) |
| **setup não rodou** | tudo falha apontando a tela de login | o setup gravou `storageState` sem verificar o login (`PW-AUTH-06`) |

---

## Duas armadilhas específicas de CI que aparecem como flake

- **Service Worker interceptando antes do `route`** — os eventos de rede simplesmente não
  aparecem. `serviceWorkers: 'block'` é a **primeira** hipótese a verificar, não a última
  (`PW-NET-03`).
- **Imagens bloqueadas por `route` numa suíte com screenshot** — a referência tem as
  imagens, a execução não (`PW-SNAP-06`).

---

## A regra que atravessa as quatro

Subir o timeout é a resposta certa **apenas** quando o trace mostra que o alvo ficou
acionável e o tempo não bastou. Nos outros três casos o timeout maior só adia a falha e
alonga toda execução.

---

## Relacionados

- [[Playwright - Execução, Retries e CI]] · [[Playwright - Snapshots e Visual]] · [[Playwright - Autenticação e Isolamento]]
- `arvore-de-hipoteses.md` — de onde esta ramificação sai
