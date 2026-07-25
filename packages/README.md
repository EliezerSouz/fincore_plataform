# Packages Compartilhados — FINCORE

> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este diretório abriga todos os módulos de código comuns, componentes visuais e bibliotecas utilitárias reutilizáveis que são importados por dois ou mais produtos da plataforma.

---

## 🎯 Objetivo Arquitetural

Garantir o reuso de código e manter a integridade conceitual do monorepo, evitando que equipes dupliquem lógicas comuns (ex: formatação de dados, autenticação, comunicação de sync) em produtos separados.

---

## 📦 Estrutura de Pacotes Previstos

1. **`design_system`**: Biblioteca visual compartilhada contendo os botões, modais, inputs de teclado, cores HSL e tipografia padronizados.
2. **`shared`**: Funções utilitárias globais (formatação de centavos, validação de dígitos de telefones).
3. **`authentication`**: Camada compartilhada de controle de usuários, sessões e tokens JWT.
4. **`logging`**: Mecanismo padronizado de logs estruturados em JSON contendo UUID de CorrelationId.
5. **`sync`**: Componentes comuns do protocolo de sincronismo offline-first Outbox e Inbound.
6. **`core`**: Abstrações bases de Clean Architecture (Use Cases, Entities, Commands, Events).

---

## ⚠️ Regras Rígidas de Dependência (Imports)

* **Direção Única**: Pacotes localizados em `/packages/` **nunca** podem importar códigos de `/products/`. Eles devem ser 100% autônomos.
* **Isolamento de Domínio**: Um pacote de infraestrutura (ex: `sync`) pode depender do pacote `core` (abstrações de domínio), mas nunca o contrário.
* **Sem Imports Cruzados Instáveis**: Evitar dependências circulares entre pacotes. Se o pacote A depende de B, o pacote B é proibido de importar arquivos de A.

---

*Packages compartilhados — FINCORE Platform*
