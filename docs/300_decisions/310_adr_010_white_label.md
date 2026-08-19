# ADR-010: Arquitetura White-Label e Overrides por App

## Status
Aprovado (Freeze V1)

## Contexto
O FINCORE é vendido e implantado em diferentes empresas parceiras (tenants). O sistema deve permitir que cada empresa tenha sua própria identidade visual (cores de marca, logotipo, densidade do layout, arredondamento de botões) refletida dinamicamente no aplicativo. Além disso, diferentes aplicativos do mesmo cliente podem exigir comportamentos visuais distintos (ex: ERP corporativo exige visual denso e cantos sóbrios de 8px; o aplicativo do cliente final exige visual arredondado e amigável de 20px).

## Decisão
Adotamos as seguintes regras estruturais de White-Labeling:
1. **Configurações Centralizadas por Tenant**: A tabela de configurações da empresa (`EmpresaConfiguracaoTable`) armazena no SQLite o JSON estruturado do tema. O `ThemeController` carrega esses dados na inicialização da aplicação.
2. **Dynamic ThemeData Injection**: O `ThemeFactory` consome os tokens gerados a partir da cor de marca salva para fabricar dinamicamente o `ThemeData` do MaterialApp.
3. **Mecanismo de Overrides por Aplicativo**: Os widgets de fundação no pacote do Design System permitem a passagem opcional de parâmetros de override por app (ex: passar `baseRadius: 20` no App do Consumidor, ignorando o padrão de `8` do ERP) mantendo a mesma cor base.
4. **Validação WCAG de Contraste**: Ao persistir ou alterar uma cor de marca, a plataforma calcula e atesta a legibilidade em relação ao texto (contraste mínimo de 3.0:1 para elementos de ação bold).

## Consequências
- **Positivas**:
  - Personalização de marca rica, dinâmica e segura.
  - Reutilização absoluta do mesmo core técnico entre o ERP, PDV e aplicativos nativos.
  - Segurança de contraste nativa.
- **Negativas**:
  - Não é possível usar construtores const em temas globais de aplicação.
