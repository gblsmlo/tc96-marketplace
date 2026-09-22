# O vault, aposentado como origem

Até 2026-09-22 a `knowledge-base/` era **projeção** de um vault Obsidian fora do
repositório: `sincronizar.sh` copiava as notas que `dominio.txt` declarava, e o
MANIFESTO registrava o caminho de origem.

A decisão mudou: o workspace resolve como projeto e **não aponta para arquivo
fora dele**. As 95 notas passaram a ser conteúdo daqui, cada uma com o próprio
`titulo:` no frontmatter, e o índice é gerado por `build/indexar.sh`.

Os dois arquivos ficam como registro de proveniência — não rode nenhum deles.
