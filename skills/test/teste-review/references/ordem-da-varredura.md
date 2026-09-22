# A ordem da varredura

> Por impacto na capacidade de a suíte **dar sinal** — não por diretório.
> Se um passo produz achado que invalida o seguinte, **pare de auditar o interior** e
> reporte a mudança de forma.

| # | Pergunta | IDs | Por que nesta posição |
| --- | --- | --- | --- |
| 1 | **O portão mente?** | `TS-PROC-03`, `TS-CORE-05` | produz **falsa confiança institucional**, não só um teste ruim |
| 2 | **A forma está invertida?** | `TS-NIV-04`, `TS-CORE-02`, `TS-NIV-02` | massa em E2E; mesma lógica em três níveis; regra de negócio em E2E |
| 3 | **Há classe de risco descoberta?** | `TS-TIPO-02` | os cinco estados; o de **erro** é o mais ausente e o mais visível |
| 4 | **A camada estática conta?** | `TS-TIPO-08` | `strict` desligado, lint sem as regras que pegam o que o tipo não pega |
| 5 | **Atributo não funcional tem número?** | `TS-TIPO-05`, `TS-TIPO-06` | "deve ser rápido"; média em vez de percentil |
| 6 | **O contrato com o exterior está verificado?** | `TS-NIV-09` | tipo compartilhado tratado como teste completo |
| 7 | **A substituição está no lugar certo?** | `TS-CORE-03`, `TS-DUB-03`, `TS-DUB-08` | mock do que o teste vem provar; fake sem fidelidade |
| 8 | **Determinismo é decisão ou acidente?** | `TS-SUI-05`, `TS-DUB-05` | se houver flake ativo, **pare** e vá para `teste-diagnose` |
| 9 | **Reteste virou regressão?** | `TS-TIPO-03`, `TS-TIPO-04` | correção verificada só no ticket |
| 10 | **Exploratório existe?** | `TS-TIPO-09` | suíte automatizada como estratégia inteira: regressão excelente, descoberta zero |
| 11 | **Há teste que não paga?** | `TS-SUI-10` | duplicata de nível, teste de getter, teste escrito para meta de cobertura |

---

## As três conclusões, que não se misturam

Um relatório desta skill separa:

| Conclusão | De quem é |
| --- | --- |
| **não protegido** — classe de risco sem teste | desta skill |
| **no nível errado** — a forma | desta skill |
| **quebrado** — defeito no teste, `arquivo:linha` | `playwright-review` · `bun-test-review` |

Um repositório pode passar nas duas skills de ferramenta e falhar aqui — e é o caso mais
comum: 200 dos 214 testes são E2E, todos bem escritos, e nenhum cobre o estado de erro.

---

## Relacionados

- `sondas.md` — o que rodar antes
- `severidade-e-relatorio.md` — classificar e reportar
- `teste-diagnose` — quando a varredura encontra flake ativo
