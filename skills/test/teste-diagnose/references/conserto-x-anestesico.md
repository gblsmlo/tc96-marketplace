# Conserto × anestésico

> Sete "correções" que fazem o vermelho desaparecer sem resolver nada. Se você está
> propondo uma delas, volte às dez causas.

| Anestésico | O que esconde | Regra |
| --- | --- | --- |
| retry | um defeito diagnosticável, e o vermelho verdadeiro junto | `TS-SUI-03` |
| espera por tempo fixo | a condição que deveria ser esperada | `TS-SUI-07` |
| um worker só | acoplamento entre testes | `TS-SUI-09` |
| prefixo numérico nos arquivos | dependência de ordem, agora codificada | § 8.4 do satélite |
| `skip` sem issue | a dívida, agora anônima | `TS-SUI-11` |
| `try/catch` no corpo do teste | o teste inteiro — ele nunca falha | § 5 do satélite |
| remover a asserção que falha | exatamente o que o teste verificava | `TS-SUI-04` |

**Os dois últimos são os mais graves porque são invisíveis em revisão**: o arquivo continua
parecendo um teste. O inventário de `scripts/medir-flakiness.sh` procura os dois.

**Retry merece nota.** Ele tem uso legítimo: absorver instabilidade **residual** de uma
suíte já sã, com o trace da tentativa gravado. Acima de ~1% de flake, deixa de ser rede e
passa a ser tapa-olho.

---

## Antipadrões mais frequentes, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Conviver com flaky como escolha pragmática | `TS-CORE-04` | [[Teste de Software - Confiabilidade da Suíte]] |
| Retry para calar flake | `TS-SUI-03` | [[Teste de Software - Confiabilidade da Suíte]] |
| Espera por tempo fixo | `TS-SUI-07` | [[Teste de Software - Confiabilidade da Suíte]] |
| Um worker como solução | `TS-SUI-09` | [[Teste de Software - Confiabilidade da Suíte]] |
| Limpeza no setup do próximo em vez do teardown | `TS-SUI-08` | [[Teste de Software - Confiabilidade da Suíte]] |
| Dado pré-existente compartilhado no ambiente | `TS-SUI-05` | [[Teste de Software - Confiabilidade da Suíte]] |
| Teste que não pode falhar, mantido | `TS-SUI-10` | [[Teste de Software - Confiabilidade da Suíte]] |
| `skip` sem motivo nem prazo | `TS-SUI-11` | [[Teste de Software - Confiabilidade da Suíte]] |
| Culpar o refactor pelo teste que quebrou | `TS-SUI-06` | [[Teste de Software - Confiabilidade da Suíte]] |
| Asserção que não detecta quebra | `TS-SUI-04` | [[Teste de Software - Confiabilidade da Suíte]] |
| Teste observando implementação | `TS-CORE-07` | [[Teste de Software - Confiabilidade da Suíte]] |
| Cobertura como prova de detecção | `TS-CORE-05` | [[Teste de Software - Técnicas de Design de Caso]] |
| Declarar suíte suficiente sem quebrar nada | `TS-TEC-08` | [[Teste de Software - Técnicas de Design de Caso]] |
| Mockar o que o teste vem provar | `TS-CORE-03` | [[Teste de Software - Dublês de Teste]] |
| Relógio real em teste sobre tempo | `TS-DUB-05` | [[Teste de Software - Dublês de Teste]] |
| Fake infiel usado para verificar contrato | `TS-DUB-03` | [[Teste de Software - Dublês de Teste]] |
| Suíte lenta que ninguém roda (forma invertida) | `TS-NIV-04` | [[Teste de Software - Níveis e Escopo]] |
| Estado de erro sem cobertura | `TS-TIPO-02` | [[Teste de Software - Tipos e Atributos de Qualidade]] |
| Defeito recorrente corrigido pontualmente | `TS-PROC-08` | [[Teste de Software - Processo e Artefatos]] |
| Defeito de produção sem teste que o pegue | `TS-CORE-06` | [[Teste de Software]] |
| Suíte verde tratada como adequação ao usuário | `TS-CORE-08` | [[Teste de Software]] |

Confira o ID em `mapa-de-ids.md` antes de citar: `TS-SUI-02`, `TS-NIV-01` e `TS-DUB-02` são
apelidos.
