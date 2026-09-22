# Formato do achado, e o corte

Quatro partes, o mesmo contrato de [[react-review]]:

```
`ID-DA-REGRA` — arquivo:linha
<o que está errado, uma frase>
Correção: <mudança concreta>
Ver [[Satélite correspondente]].
```

### Exemplo

```
`DRZ-RQB-01` — apps/api/src/features/tasks/repository.ts:265
A listagem chama a leitura de agregado uma vez por linha da página, dentro de Promise.all.
Correção: buscar os IDs da página e carregar referências e tags em uma query com inArray, agrupando por Map.
Ver [[Drizzle - Queries e Relations]].
```

Regras do formato:

- **ID canônico obrigatório**, conferido na § 6 antes de escrever.
- **Arquivo:linha sempre.** Para sonda, a evidência é a saída do script — cole-a.
- **Correção concreta.** Se o repositório já tem o padrão certo em outro arquivo, aponte esse arquivo: estender o padrão estabelecido vale mais que introduzir um novo.
- **Um link de satélite.**

---

## Passo 6 — O corte: achado × opinião

**Achado sem ID de regra é opinião**, com duas saídas legítimas:

1. **Existe ID** → achado, cite o canônico.
2. **Não existe ID, mas há nota normativa** (offset × cursor, retenção de log, ordem de deploy destrutivo) → cite a nota e a seção: "[[Paginação por offset e cursor]]". Não invente `DRZ-*`.
3. **Nem ID nem nota** → seção separada "Sugestões (sem regra)", nunca misturada.

**Nunca invente um ID.** Se a varredura encontrar um defeito recorrente e real sem regra correspondente, o produto certo é uma **proposta de regra** para [[Drizzle ORM]] § 6 — com ID sugerido, texto e o caso que a motivou — não uma citação falsa no relatório.

---
