# As sete sondas — antes de ler o código

> Numa suíte de teste, **os piores defeitos são invisíveis à leitura**: o arquivo parece
> completo, os testes parecem certos, o CI está verde — e mesmo assim o arquivo nunca rodou,
> o portão nunca fechou, ou a suíte só passa na ordem de hoje.

```bash
bash ~/.claude/skills/bun-test-review/scripts/sondas.sh          # só as mecânicas
bash ~/.claude/skills/bun-test-review/scripts/sondas.sh --rodar  # + as que exigem a suíte de pé
```

| Sonda | Como | O que revela |
| --- | --- | --- |
| **S1. Teste que nunca roda** | `find . -path ./node_modules -prune -o -name '*[Tt]est*' -print \| grep -Ev '\.(test\|spec)\.[cm]?[jt]sx?$\|_(test\|spec)\.[cm]?[jt]sx?$'` | `BUN-TEST-01` — arquivo fora do padrão de descoberta não roda e não gera aviso |
| **S2. Dependência de ordem** | `bun test --randomize; echo "exit=$?"` — e, se falhar, `bun test --randomize --seed <n>` para reproduzir | `BUN-TEST-09` — a suíte passa na ordem de descoberta e quebra em qualquer outra |
| **S3. Dependência do global compartilhado** | `bun test --isolate` | quais arquivos só passavam porque outro rodou antes; sob `--parallel` isso é o CI de amanhã |
| **S4. Flaky que não é de ordem** | `bun test --rerun-each 20` | `await` faltando, timer real, concorrência — falha que a execução única esconde |
| **S5. O portão de cobertura fecha?** | `grep -nE 'coverageThreshold\|coverageReporter' bunfig.toml` e depois `bun test --coverage; echo "exit=$?"` | `BUN-TEST-27`, `BUN-TEST-28` — limiar sem reporter `text` (fora de `--parallel`), ou declarado em `statements`, **não reprova nada** |
| **S6. Restauração de mock existe?** | `grep -rn 'mock.restore()' $(grep -oE '"[^"]+\.ts"' bunfig.toml \| tr -d '"')` — ou `grep -rn 'preload' bunfig.toml` e ler cada arquivo | `BUN-TEST-02` — sem `mock.restore()` num preload, todo `spyOn` da suíte é candidato a vazamento |
| **S7. Marcas e comandos** | `grep -rn '\.only(\|\.skip(' --include='*.test.*' --include='*.spec.*' .` e `grep -rn 'update-snapshots\|--retry\|tsc --noEmit' package.json .github/` | `BUN-TEST-05`, `BUN-TEST-08`, `BUN-TEST-11`, `BUN-TEST-18` — marcas commitadas, `-u` no CI, retry global, typecheck ausente |

S1, S6 e S7 são leitura mecânica e rodam em segundos. S2, S3 e S4 exigem a suíte de pé. S5 exige as duas coisas: ler a configuração **e** conferir o exit code.

**Se S1 encontrar arquivo, ou S5 mostrar portão aberto, reporte antes de continuar.** Nos dois casos a revisão de conteúdo perde sentido: um arquivo que nunca rodou não tem defeito de asserção que importe, e um portão que nunca fecha torna qualquer discussão de cobertura decorativa.


---

## O que a sonda não pega

| Não detectável mecanicamente | Regra | Como achar |
| --- | --- | --- |
| `expect` em `catch`/callback sem contagem | `BUN-TEST-06` | procurar `catch (` no arquivo de teste e conferir se há `expect.assertions(n)` |
| mock de módulo esperando restauração | `BUN-TEST-03` | ler cada `mock.module()` e ver se algo conta com desfazer |
| preload caro ou não idempotente | `BUN-TEST-24` | ler o preload: servidor ou migração ali só quebra sob `--parallel` |
| `test.serial` usado para dependência **entre arquivos** | `BUN-TEST-09` | é correção errada: `serial` sequencia dentro do arquivo |

## Relacionados

- `ordem-da-varredura.md` — o que fazer com o que as sondas apontaram
- `severidade-e-relatorio.md` — classificar e escrever
- `mapa-de-ids.md` — onde cada `BUN-TEST-*` tem corpo
