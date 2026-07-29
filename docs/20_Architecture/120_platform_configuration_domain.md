---
Title: Platform Configuration Domain
Status: Active
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# Centro de Configuração da Plataforma (Platform Configuration Domain)

> **Document ID**: 120  
> **Version**: 1.3.0  
> **Status**: ✍️ Ativo  
>
> Este documento conceitua a arquitetura e estruturação do Centro de Configurações da FINCORE Platform, definindo a separação por agregados modulares, o escopo do Platform Core, metadados de sincronização, auditoria, gerenciamento de contexto de tenant e regras de herança.

---

## 🎯 Visão Estratégica

> O Centro de Configuração da Plataforma constitui a fundação operacional da FINCORE Platform. Todos os módulos funcionais dependerão direta ou indiretamente deste domínio para obtenção de parâmetros operacionais, regras de negócio, integrações e comportamento da aplicação.

---

## 🏗️ 1. Escopo do Platform Core

O Platform Core é composto por dois pilares complementares que garantem o funcionamento distribuído e consistente do ecossistema:

### 1.1 Core de Domínio
Representa os modelos lógicos e regras de negócio da fundação da plataforma:
- **Empresa (Tenant)**: Identidade da organização, faturamento, internacionalização.
- **Usuário**: Identificação de operadores, perfis de acesso e sessões.
- **Centro de Configuração**: Agregados modulares de parametrização da aplicação.

### 1.2 Core Técnico
Representa os serviços e infraestrutura compartilhados:
- **BaseRepository**: Interface genérica para persistência com multi-tenancy nativo.
- **TenantContext**: Gerenciador dinâmico de sessão e localização.
- **OutboxService**: Mecanismo transacional local de persistência diferida.
- **SyncEngine**: Mecanismo de sincronização reativa bidirecional.
- **AuditService**: Auditoria estrita de mutação de dados.

---

## 🔄 2. Hierarquia de Contexto e Tenancy (SaaS)

Para operar de forma robusta como uma plataforma SaaS multi-inquilino, o ecossistema é modelado na seguinte ordem lógica de dependência e herança:

```text
Tenant (Empresa) ➔ Usuários ➔ Centro de Configuração
```

### 2.1 Entidade Empresa (Tenant)
A entidade `Empresa` representa a identidade corporativa do cliente contratante na plataforma, contendo dados fiscais, comerciais, contratuais, além de parâmetros de internacionalização e auditoria básica.

- **Campos da Entidade `Empresa`**:
  - `id` (String UUID / tenantId): Identificador único global e chave de isolamento lógico de tenancy.
  - `razaoSocial` (String): Nome de registro legal.
  - `nomeFantasia` (String): Nome comercial de exibição.
  - `documentoFiscal` (String): CNPJ ou CPF para empresas individuais.
  - `email` (String): Contato administrativo/financeiro principal.
  - `telefone` (String): Telefone comercial.
  - `status` (Enum): `Ativo`, `Suspenso` ou `Bloqueado`.
  - `plano` (Enum): Nível de assinatura (ex: `Bronze`, `Prata`, `Ouro`) para habilitar capacidades da plataforma.
  - `timezone` (String): Fuso horário da operação (ex: 'America/Sao_Paulo').
  - `locale` (String): Localização de idioma/formatação (ex: 'pt_BR').
  - `currency` (String): Símbolo monetário (ex: 'BRL').
  - `country` (String): País de origem da operação (ex: 'BR').
  - `createdFrom` (String): Canal de criação da conta (ex: 'Web', 'Mobile').
  - `version` (int): Controle de concorrência.
  - `metadata` (SyncMetadata): Metadados estruturados de auditoria e sync.

### 2.2 Entidade Usuário (Usuario)
Os usuários pertencem a uma Empresa e possuem perfis de acesso, permissões e dados de auditoria de sessão.

- **Campos da Entidade `Usuario`**:
  - `id` (String UUID)
  - `tenantId` (String UUID)
  - `nome` (String)
  - `email` (String)
  - `perfil` (Enum: Administrador, OperadorCaixa, Cozinha, Entregador)
  - `permissoes` (List<String>)
  - `ativo` (Boolean)
  - `ultimoLogin` (DateTime, opcional)
  - `ultimoSync` (DateTime, opcional)
  - `avatar` (String URL, opcional)
  - `preferencias` (String JSON, opcional)
  - `metadata` (SyncMetadata)

---

## ⚡ 3. Infraestrutura Compartilhada do Core

### 3.1 SyncMetadata (Versionamento e Rastreamento)
Todas as entidades sincronizadas na FINCORE Platform herdam ou incorporam a classe `SyncMetadata`, padronizando as informações necessárias para a sincronização offline-first:
- `version` (int): Contador incremental para concorrência otimista.
- `createdAt` (DateTime): Data/hora de criação.
- `updatedAt` (DateTime): Data/hora da última alteração.
- `createdBy` (String UUID): Usuário que criou.
- `updatedBy` (String UUID): Usuário que alterou.
- `deletedAt` (DateTime, opcional): Exclusão lógica (soft delete).
- `syncStatus` (Enum): `Pending`, `Processing`, `Synced`, `Failed`, `Retrying`, `Resolved`.
- `lastSyncedAt` (DateTime, opcional): Data/hora da última sincronização bem-sucedida.

### 3.2 Estados de Sincronização (Fila Outbox)
Cada operação registrada localmente no `Outbox` assume uma máquina de estados estrita até ser consolidada no banco remoto:
1. `Pending` (Pendente): Operação gravada localmente offline e aguardando processamento.
2. `Processing` (Processando): Transação enviada e em trânsito/processamento pelo Serverpod.
3. `Synced` (Sincronizado): Operação aplicada no servidor remoto com sucesso.
4. `Failed` (Falhou): Erro persistente ou falha de validação lógica (exige intervenção ou resolução de conflitos).
5. `Retrying` (Retentando): Erro temporário de conectividade, escalonando novas tentativas automáticas.
6. `Resolved` (Resolvido): Conflito resolvido manualmente ou por política automática de reconciliação de dados.

### 3.3 Auditoria (AuditService)
O `AuditService` registra logs imutáveis de mutações em todas as entidades da plataforma, contendo no mínimo os campos de `AuditEvent`:
- `entity` (String): Nome da entidade modificada (ex: 'Empresa', 'Produto').
- `entityId` (String UUID): Identificador do registro.
- `tenantId` (String UUID): Tenant associado.
- `action` (Enum): `CREATE`, `UPDATE`, `DELETE`.
- `before` (String JSON, opcional): Estado do registro antes da mutação.
- `after` (String JSON, opcional): Estado do registro após a mutação.
- `performedBy` (String UUID): Usuário executor.
- `performedAt` (DateTime): Data/hora exata da ação.
- `deviceId` (String): ID do dispositivo terminal.
- `origin` (String): Canal originador (ex: 'Windows-POS', 'Mobile-KDS', 'Web-Admin').

### 3.4 TenantContext
O `TenantContext` é a classe singleton/service responsável por gerenciar a sessão ativa e a contextualização da operação, encarregada de:
1. Manter o `tenantId` ativo da empresa na memória da aplicação.
2. Disponibilizar o `Usuario` autenticado no ciclo de execução.
3. Fornecer informações dinâmicas do contexto ativo (timezone, locale, currency).
4. Impedir e bloquear quaisquer transações no banco ou na rede caso não haja um contexto de inquilino ativo e autenticado válido.

---

## 🧩 4. O Conceito de Agregado Modular de Configurações

Para garantir a escalabilidade da plataforma, o Centro de Configuração é estruturado em sub-entidades (agregados) especializadas vinculadas à Empresa:

```text
Empresa (Tenant Principal)
   │
   ├── ConfiguracaoIdentidade (Logo, CNPJ, Razão Social, Endereço, Redes)
   ├── ConfiguracaoOperacao (Horários de funcionamento, limites, tempos por categoria)
   ├── ConfiguracaoDelivery (Raios, taxas fixas/dinâmicas por bairro, pedido mínimo)
   ├── ConfiguracaoImpressao (ESC/POS, larguras 58/80mm, corte, rotas por impressora)
   ├── ConfiguracaoProducao (FIFO/LIFO cozinha, agrupamentos, auto-start de preparo)
   ├── ConfiguracaoFinanceira (Chaves Pix, dados de banco, fechamento de caixa, sangrias)
   ├── ConfiguracaoPDV (Parâmetros visuais, atalhos, obrigatoriedade de campos)
   ├── ConfiguracaoIA (Parâmetros do motor de Upsell e análises automáticas)
   ├── ConfiguracaoSeguranca (PIN para estornos, timeout de sessão, auditoria)
   ├── ConfiguracaoIntegracoes (iFood, Mercado Pago, Stone, NFC-e/SAT, Webhooks)
   └── ConfiguracaoNotificacoes (Canais ativos: WhatsApp, SMS, Email, Push)
```

> [!NOTE]
> **Princípio de Modelagem Física**: Os agregados de configuração representam limites de domínio, e não necessariamente uma correspondência de 1:1 com tabelas físicas. A modelagem física poderá ser ajustada conforme critérios de desempenho, simplicidade, normalização e evolução da plataforma.

---

## 🔄 5. Configurações Herdáveis e Hierarquia

Para otimizar o ecossistema SaaS e evitar a redundância de preenchimento, o Centro de Configuração suporta o modelo de **Configuração Herdável**:

```text
Configuração Global (FINCORE Defaults)
         │
         ▼ (Herança caso não definido)
Configuração Global da Empresa (Tenant)
         │
         ▼ (Sobrescrita opcional)
Configuração Individual do Usuário / Terminal (Caixa/Dispositivo específico)
```

### Regras de Herança:
1. Se uma configuração específica de impressão ou layout não for definida a nível de Usuário/Terminal, o app herdará os valores configurados na Empresa (Tenant).
2. Se a Empresa não definir um parâmetro básico (ex: tempo médio de preparo), a aplicação carregará os valores defaults globais da FINCORE Platform.

---

## 🧩 6. Estratégia de Desenvolvimento Incremental (Foco Presente)

Durante a **Milestone 3 (Platform Core)**, o banco de dados Drift SQLite e a API Serverpod serão desenhados estruturalmente para persistir esses agregados, contudo, **apenas as propriedades críticas imediatas para o funcionamento do PDV Express serão inicialmente implementadas**.

### Escopo Crítico da Milestone 3 (Platform Core):
1. **ConfiguracaoIdentidade**: CNPJ, Nome Fantasia, Contatos e Endereço Base.
2. **ConfiguracaoOperacao**: Horários de funcionamento e tempo médio de preparo geral.
3. **ConfiguracaoDelivery**: Taxa de entrega fixa básica e bairros ativos.
4. **ConfiguracaoFinanceira**: Chave Pix e Dados Bancários.
5. **ConfiguracaoImpressao**: Impressora do caixa e impressora da cozinha de testes.

As demais configurações serão adicionadas de forma granular à medida que os módulos de Produção, Financeiro e IA forem introduzidos no cronograma técnico.
