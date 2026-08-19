# Princípios da Plataforma (Platform Principles) — FINCORE

Este documento estabelece as 10 diretrizes fundamentais de engenharia e design de software que regem o desenvolvimento de qualquer produto dentro do ecossistema FINCORE.

---

## 🔟 Princípios Estruturais do Core

### Princípio 1: Single Source of Truth (Fonte Única de Verdade)
Cada dado ou estado tem um único dono definido. Configurações visuais partem de `ThemeController`, dados operacionais partem do repositório local SQLite e dados em nuvem sincronizam via Supabase. Duplicações de escrita ou leitura são terminantemente proibidas.

### Princípio 2: Nenhum Hardcode (Zero Hardcode)
Nenhuma tela ou serviço pode declarar cores literais, margens fixas, URLs estáticas ou segredos de ambiente no código. Todo comportamento visual consome tokens de design e variáveis injetadas.

### Princípio 3: Componentização Estrita
Nenhum componente de Level 1 ou Level 3 nasce dentro de um módulo isolado de negócio. Elementos visuais reutilizáveis nascem obrigatoriamente sob o controle de qualidade do pacote `fincore_design_system`.

### Princípio 4: Trilha Forense por Alteração
Qualquer mutação de dados relevante em tabelas transacionais gera automaticamente uma entrada na tabela de auditoria forense local (`AuditLogsTable`), permitindo o rastreamento retrospectivo completo da operação.

### Princípio 5: Operações baseadas em Outbox
Toda modificação local destinada à nuvem não faz requisições HTTP em linha. Ela é persistida localmente na tabela de `OutboxSync`, garantindo resiliência offline e ordenação topológica à prova de erros.

### Princípio 6: Offline First
Toda funcionalidade comercial essencial (caixa, catálogo, comandas, KDS) deve funcionar plenamente sem acesso à internet, sincronizando os dados em background de forma assíncrona.

### Princípio 7: Cloud Ready
O banco de dados e os serviços do core são projetados para escalar horizontalmente na nuvem Supabase/PostgreSQL com consistência de chaves UUIDv7 e baixo acoplamento físico.

### Princípio 8: White Label Ready
A plataforma apoia a customização completa de logotipos, cores, arredondamentos de botões e densidade física de layouts por tenant e por dispositivo.

### Princípio 9: Isolamento de Tenants (Multi Tenant)
Toda consulta a tabelas locais ou remotas é automaticamente filtrada pelo `tenantId` ativo no `TenantContext`, impedindo o vazamento de informações de empresas sob o mesmo hardware ou banco físico.

### Princípio 10: API First
A injeção de dependência e os contratos de serviços expõem interfaces abstratas e puras (`shared_contracts`), garantindo a substituição de conectores de infraestrutura (Supabase por Serverpod ou Firebase) sem alterar as telas.
