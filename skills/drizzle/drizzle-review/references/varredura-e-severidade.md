# A ordem da varredura, e a severidade

6. **Escrita e transaction** — `DRZ-TX-01`, `DRZ-TX-03`, `DRZ-QUERY-04`, `DRZ-QUERY-06`.
7. **Projeção e SQL cru** — `DRZ-QUERY-01`, `DRZ-QUERY-03`.
8. **Validação de fronteira** — `DRZ-ZOD-01`, `DRZ-ZOD-02`.

Se um passo produz achado que invalida o seguinte (a API relacional está desligada; a listagem inteira deveria ser paginada), **pare de revisar o interior** e reporte a mudança de forma, não o detalhe.

---

## Passo 4 — Classificar severidade

| Severidade | O que entra |
| --- | --- |
| **Bloqueante** | perda de isolamento entre tenants, `update`/`delete` sem `where` (`DRZ-QUERY-04`), `push` em produção (`DRZ-MIG-02`), migração destrutiva sem rollback |
| **Alta** | `DRZ-REL-05`, `DRZ-RQB-01`, `DRZ-TX-01`, `DRZ-TX-03`, snapshot dessincronizado, leitura sem teto em tela de volume aberto |
| **Média** | índice ausente para filtro quente, índice redundante, `DRZ-QUERY-01`, `DRZ-QUERY-06`, `DRZ-ZOD-01` |
| **Baixa** | preferência sem ID — **não é achado**, ver Passo 6 |

Custo medido vence custo suposto. "Isso pode ficar lento" sem número nem plano de execução é Baixa, não Média.

---

## Passo 5 — Formato de saída de um achado

Quatro partes, o mesmo contrato de [[react-review]]:

```
`ID-DA-REGRA` — arquivo:linha
<o que está errado, uma frase>
Correção: <mudança concreta>
Ver [[Satélite correspondente]].
```

### Exemplo

