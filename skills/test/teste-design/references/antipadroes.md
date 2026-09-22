# Antipadrões que esta skill evita, com ID

> Grade de conferência do Passo 6. Cada linha é uma decisão que, tomada por hábito,
> produz teste que custa e não paga. O texto da regra mora no satélite.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Escrever teste sem saber o que pode dar errado | `TS-CORE-01` | [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md) |
| E2E como default para qualquer coisa | `TS-CORE-02` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Regra de negócio verificada em E2E | `TS-NIV-02` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Mesma lógica verificada em três níveis | `TS-CORE-02` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Forma invertida da suíte (*ice-cream cone*) | `TS-NIV-04` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Proporção tratada como política global do repositório | `TS-NIV-08` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Substituir colaborador interno que é código próprio | `TS-NIV-05` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Confiar só no tipo compartilhado como teste de contrato | `TS-NIV-09` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Não nomear o nível de componente (tudo vira E2E) | `TS-NIV-07` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Testar só o caminho feliz | `TS-TIPO-02` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/docs/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Um valor inventado no meio da faixa | `TS-TEC-01` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| Só as classes válidas | `TS-TEC-02` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| Lista sempre com três itens, nunca vazia | `TS-TEC-03` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| Só transições válidas de estado | `TS-TEC-04` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| Combinação reduzida por escolha arbitrária | `TS-TEC-09` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| Substituir o que o teste vem provar | `TS-CORE-03` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Chamar todo dublê de "mock" | `TS-DUB-01` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Fake sem fidelidade declarada | `TS-DUB-03` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Verificação de comportamento por default | `TS-DUB-04` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Esperar o tempo real passar | `TS-DUB-05` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Fake de repositório no lugar de banco controlado | `TS-DUB-08` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Requisito não funcional sem número | `TS-TIPO-05` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/docs/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Média em vez de percentil | `TS-TIPO-06` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/docs/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Não contar a camada estática na estratégia | `TS-TIPO-08` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/docs/teste-de-software-tipos-e-atributos-de-qualidade.md) |

**Antes de citar qualquer ID, confira `mapa-de-ids.md`:** `TS-NIV-01`, `TS-DUB-02` e
`TS-SUI-02` são **apelidos** e citá-los é achado inválido.
