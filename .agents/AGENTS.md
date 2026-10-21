# Diretrizes Gerais de Comportamento

- **Idioma**: Responda e documente sempre em Português do Brasil (PT-BR), exceto quando o código exigir termos específicos da stack (nomes de variáveis, chaves, etc.).

# Princípio Arquitetural Fundamental (Domain Flow Driven Architecture)

- **Fluxo Operacional Acima do Cadastro**: As telas e entidades nunca podem ser desenhadas pensando apenas em cadastros CRUD simples. Elas precisam refletir rigorosamente o **fluxo operacional do negócio** de alimentação e produção comercial.
- **Modelagem de Domínio Real**: O cadastro de qualquer item (ex: produto, usuário, impressora, empresa) é apenas a consequência visual de um agregado que interage com estratégias de precificação em lote, rotas de impressão KDS/cozinha, regras fiscais SEFAZ/Reforma Tributária, auditoria forense e controle FIFO de estoque.

# Diretriz Obrigatória de Versionamento e Releases

- **Incremento de Versão a Cada Nova Entrega**: Nunca mantenha a mesma versão do sistema após correções ou novas funcionalidades serem entregues. A cada novo ciclo de entrega/compilação, incremente a versão semântica (`patch` para correções e ajustes, `minor` para novas funcionalidades de domínio, `major` para quebras de arquitetura).
- **Comando Oficial de Release**: Sempre utilize o script oficial `build_release.bat` (ou `tools/build_and_package.ps1`), que por padrão já executa o incremento automático de versão (`-Bump patch`), sincroniza `pubspec.yaml`, `app_constants.dart`, empacota os pacotes `FULL` e `UPDATE` em `releases/`, atualiza o histórico `RELEASES.md` e espelha os binários na pasta raiz `fincore_food\`.

