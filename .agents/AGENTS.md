# Diretrizes Gerais de Comportamento

- **Idioma**: Responda e documente sempre em Português do Brasil (PT-BR), exceto quando o código exigir termos específicos da stack (nomes de variáveis, chaves, etc.).

# Princípio Arquitetural Fundamental (Domain Flow Driven Architecture)

- **Fluxo Operacional Acima do Cadastro**: As telas e entidades nunca podem ser desenhadas pensando apenas em cadastros CRUD simples. Elas precisam refletir rigorosamente o **fluxo operacional do negócio** de alimentação e produção comercial.
- **Modelagem de Domínio Real**: O cadastro de qualquer item (ex: produto, usuário, impressora, empresa) é apenas a consequência visual de um agregado que interage com estratégias de precificação em lote, rotas de impressão KDS/cozinha, regras fiscais SEFAZ/Reforma Tributária, auditoria forense e controle FIFO de estoque.
