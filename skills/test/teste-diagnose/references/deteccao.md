# O teste de trinta segundos

> Para a pergunta 3 das seis, e é a verificação de **maior retorno** desta skill.

---

## O procedimento

**Quebre o código de propósito e veja se algo fica vermelho.** Troque um sinal, inverta uma
condição, remova uma chamada, devolva `null`. Se nada quebrar, **a asserção não existe**
(`TS-SUI-04`).

Faça em três lugares, escolhidos por risco:

| Onde | O que quebrar |
| --- | --- |
| a regra de negócio mais crítica | inverter uma comparação |
| a validação de entrada mais usada | remover a checagem |
| o caminho de erro mais importante | fazer sucesso onde deveria falhar |

Se a suíte fica verde em **qualquer** um dos três, o achado é **bloqueante** — e explica
sozinho a pergunta 6 ("passa tudo e o defeito chega em produção").

---

## A versão rigorosa, e quando ela paga

**Teste de mutação**: o mutante que **sobrevive** aponta a asserção faltante com precisão
de linha (`TS-SUI-04`). É caro para rodar sempre; o uso realista é **pontual, no módulo
crítico**. A versão de trinta segundos serve todo dia e não precisa de ferramenta.

---

## O corolário que fecha a discussão sobre cobertura

**Cobertura não responde a essa pergunta.** Um teste que chama a função e não afirma nada
dá cobertura total (`TS-CORE-05`). É por isso que "96% de cobertura" e "o defeito passou"
convivem sem contradição.

Declarar a suíte suficiente **sem ter quebrado nada** é `TS-TEC-08`.

---

## Relacionados

- [[Teste de Software - Técnicas de Design de Caso]] — cobertura × mutação
- [[Teste de Software - Confiabilidade da Suíte]] — `TS-SUI-04`
- `medicao.md` — a outra medida obrigatória desta skill
