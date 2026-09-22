# Antipadrões que esta skill evita, com ID

> Grade de conferência do Passo 6. Cada linha é uma decisão que, tomada por hábito,
> produz teste que custa e não paga. O texto da regra mora no satélite.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Escrever teste sem saber o que pode dar errado | `TS-CORE-01` | [[Teste de Software]] |
| E2E como default para qualquer coisa | `TS-CORE-02` | [[Teste de Software - Níveis e Escopo]] |
| Regra de negócio verificada em E2E | `TS-NIV-02` | [[Teste de Software - Níveis e Escopo]] |
| Mesma lógica verificada em três níveis | `TS-CORE-02` | [[Teste de Software - Níveis e Escopo]] |
| Forma invertida da suíte (*ice-cream cone*) | `TS-NIV-04` | [[Teste de Software - Níveis e Escopo]] |
| Proporção tratada como política global do repositório | `TS-NIV-08` | [[Teste de Software - Níveis e Escopo]] |
| Substituir colaborador interno que é código próprio | `TS-NIV-05` | [[Teste de Software - Níveis e Escopo]] |
| Confiar só no tipo compartilhado como teste de contrato | `TS-NIV-09` | [[Teste de Software - Níveis e Escopo]] |
| Não nomear o nível de componente (tudo vira E2E) | `TS-NIV-07` | [[Teste de Software - Níveis e Escopo]] |
| Testar só o caminho feliz | `TS-TIPO-02` | [[Teste de Software - Tipos e Atributos de Qualidade]] |
| Um valor inventado no meio da faixa | `TS-TEC-01` | [[Teste de Software - Técnicas de Design de Caso]] |
| Só as classes válidas | `TS-TEC-02` | [[Teste de Software - Técnicas de Design de Caso]] |
| Lista sempre com três itens, nunca vazia | `TS-TEC-03` | [[Teste de Software - Técnicas de Design de Caso]] |
| Só transições válidas de estado | `TS-TEC-04` | [[Teste de Software - Técnicas de Design de Caso]] |
| Combinação reduzida por escolha arbitrária | `TS-TEC-09` | [[Teste de Software - Técnicas de Design de Caso]] |
| Substituir o que o teste vem provar | `TS-CORE-03` | [[Teste de Software - Dublês de Teste]] |
| Chamar todo dublê de "mock" | `TS-DUB-01` | [[Teste de Software - Dublês de Teste]] |
| Fake sem fidelidade declarada | `TS-DUB-03` | [[Teste de Software - Dublês de Teste]] |
| Verificação de comportamento por default | `TS-DUB-04` | [[Teste de Software - Dublês de Teste]] |
| Esperar o tempo real passar | `TS-DUB-05` | [[Teste de Software - Dublês de Teste]] |
| Fake de repositório no lugar de banco controlado | `TS-DUB-08` | [[Teste de Software - Dublês de Teste]] |
| Requisito não funcional sem número | `TS-TIPO-05` | [[Teste de Software - Tipos e Atributos de Qualidade]] |
| Média em vez de percentil | `TS-TIPO-06` | [[Teste de Software - Tipos e Atributos de Qualidade]] |
| Não contar a camada estática na estratégia | `TS-TIPO-08` | [[Teste de Software - Tipos e Atributos de Qualidade]] |

**Antes de citar qualquer ID, confira `mapa-de-ids.md`:** `TS-NIV-01`, `TS-DUB-02` e
`TS-SUI-02` são **apelidos** e citá-los é achado inválido.
