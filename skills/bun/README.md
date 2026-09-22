# Skills de Bun

Cinco skills: duas de teste, três de runtime, pacote e migração.

| Skill | A pergunta que responde | Fonte | Apoio interno |
| --- | --- | --- | --- |
| [[bun-test-build]] | como escrevo este teste, e como configuro a suíte? | [[Bun - Testes]] | 4 referências + 1 script |
| [[bun-test-review]] | esta suíte tem defeito? por que este teste flakeia? | [[Bun - Testes]] | 5 referências + 2 scripts |
| [[bun-runtime]] | como escrevo isto com as APIs do runtime? | [[Bun - Runtime e APIs]] | 6 referências + 2 scripts |
| [[bun-workspace]] | dependência, lockfile, workspace, instalação | [[Bun - Gerenciador de Pacotes]] | 5 referências + 1 script |
| [[bun-migrate]] | veio do Node e não roda — é incompatibilidade? | [[Bun - Shell, FFI e Compat Node]] | 4 referências + 1 script |

## As três novas, e o que cada script faz

| Script | O que faz |
| --- | --- |
| `bun-workspace/scripts/sondas.sh` | lê o `package.json` **como JSON** e diz quais pacotes da lista padrão o `trustedDependencies` desligou |
| `bun-migrate/scripts/enumerar.sh` | enumera `node:*` no código **e nas dependências transitivas** |
| `bun-runtime/scripts/autoverificar.sh` | invariantes do binário, `tsc --noEmit` no CI, hash de senha, `--watch` × `--hot` |

**A sonda de `trustedDependencies` precisou de JSON, não de grep.** A regra é que a lista
**substitui** a padrão em vez de estender (`BUN-PKG-04`), e o sintoma aparece em **runtime**
— binário não compilado, longe da causa. Um `grep` num `package.json` de uma linha responde
"está lá" para o arquivo inteiro; a checagem correta compara `dependencies` com a lista
declarada, item a item.

**A busca 2 de `enumerar.sh` é a que muda o plano.** Uma dependência transitiva que usa
`async_hooks` — que no Bun é **stub que não lança** — decide a viabilidade da migração, e
não aparece no código do projeto. Sem `node_modules` instalado, o script **diz que a
enumeração é parcial** em vez de fingir cobertura.

## As duas de teste

`bun-test-build` e `bun-test-review` dividem **modo de trabalho**, não fonte: a família
`BUN-TEST-*` inteira é declarada na § 6 do hub, e o corpo de cada regra mora no satélite dono.

| Skill | Ganhou | Lacuna que fechou |
| --- | --- | --- |
| `bun-test-build` | **`scripts/autoverificar.sh`** | a checklist de 10 itens era leitura; agora aponta arquivo e linha |
| `bun-test-review` | **`scripts/sondas.sh`** (com `--rodar`) | S2, S3, S4 e S5 exigem a suíte de pé — o script separa o que roda sem ela |

`autoverificar.sh` marca explicitamente os quatro itens **heurísticos** (asserção em
`catch`, fuso, `cleanup()`, `userEvent` aguardado): ele aponta o arquivo, e a confirmação é
leitura. Sonda que finge certeza é pior que sonda ausente.

## Os mapas de IDs — dois, e a coluna que só esta família tem

São **dois geradores**, porque as famílias não se misturam:

| Gerador | Família | IDs |
| --- | --- | --- |
| `bun-test-review/scripts/gerar-mapa-de-ids.sh` | `BUN-TEST-*` | **29** — a faixa completa `01`–`29`, conferência contra ID inventado |
| `bun-runtime/scripts/gerar-mapa-de-ids.sh` | `BUN-CORE/RT/PKG/SYS-*` | **43** |

O segundo **exclui** `Docs/Bun - Testes*` de propósito: misturar as duas famílias num mapa
só faria a coluna de satélite perder sentido.

Como a família **inteira** é declarada na § 6 do hub, a coluna "declarada em" seria uniforme
e inútil. O gerador acrescenta então **"corpo no satélite"**: para cada ID, qual dos seis
satélites carrega o raciocínio, e em que seção. É a informação que a skill precisa para
carregar **um** satélite em vez de seis.

```bash
bash Skills/bun/bun-test-review/scripts/gerar-mapa-de-ids.sh
bash Skills/instalar.sh
```

<!-- tokens:inicio -->
## Orçamento de contexto

Medido por `skill-validator` (tiktoken), em 2026-09-05. **O número que importa é o da
coluna `SKILL.md`**: é o que entra no contexto antes de a skill decidir o que abrir.
As referências carregam sob demanda, uma por vez.

| Skill | `SKILL.md` | maior `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| [[bun-migrate]] | 1.036 | `mapa-de-ids.md` (1.772) | 5.365 | 5 |
| [[bun-runtime]] | 1.035 | `mapa-de-ids.md` (1.772) | 5.856 | 7 |
| [[bun-test-build]] | 1.718 | `por-tarefa.md` (1.938) | 7.344 | 5 |
| [[bun-test-review]] | 1.565 | `mapa-de-ids.md` (1.632) | 8.899 | 6 |
| [[bun-workspace]] | 973 | `mapa-de-ids.md` (1.772) | 5.436 | 6 |

Carregar as 5 skills deste grupo de uma vez custaria **6.327 tokens** só de `SKILL.md`,
e **32.900** com todas as referências. É por isso que cada skill declara o que **nunca** carregar.

Regenerar: `bash Skills/tokens.sh`
<!-- tokens:fim -->

## Relacionados

- [[Skills/README|Skill — Índice]] · [[Bun - Testes]] § 7 — o contrato
- [[Skills/teste/README|Skills/teste/]] — decide o nível, antes destas
- [[Skills/playwright/README|Skills/playwright/]] — o nível E2E
