# ADR-001: Stack Tecnológica Oficial da Plataforma

> **Document ID**: 301  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado) / APPROVED  
> **Owner**: Comitê de Engenharia & Arquitetura FINCORE  
> **Contexto**: Necessidade de padronização, escalabilidade, produtividade e reutilização de código entre múltiplos produtos da plataforma FINCORE.

---

## 1. Contexto Geral

Com o crescimento previsto para abrigar múltiplos verticais comerciais (Food, Finance, CRM, Analytics, AI, API), a **FINCORE Platform** necessita de uma Stack Tecnológica unificada. Esta definição serve como contrato arquitetural permanente para eliminar rediscutir a escolha de ferramentas a cada contratação ou novo sprint de engenharia, reduzindo o desgaste das equipes e garantindo a consistência do ecossistema.

---

## 2. A Stack Tecnológica Oficial

A stack tecnológica oficial da FINCORE é estruturada sob as seguintes definições de infraestrutura e engenharia:

### 2.1 Linguagens Oficiais

#### Frontend
* **Dart & Flutter**
  * *Justificativa*: Desenvolvimento multiplataforma unificado (Desktop, Mobile, Web) de alto desempenho, com código único e facilidade de manutenção no mesmo ecossistema do backend.

#### Backend
* **Dart & Serverpod**
  * *Justificativa*: Produtividade elevada através do compartilhamento de modelos entre App e Servidor, protocolo RPC nativo para conexões velozes e integração perfeita com o ecossistema do Flutter.

### 2.2 Banco de Dados

#### Produção (Nuvem)
* **PostgreSQL**
  * *Justificativa*: Banco relacional maduro, robusto, altamente performático sob Row-Level Security (RLS) para isolamento estrito de tenants.

#### Local (Offline First)
* **SQLite & Drift ORM**
  * *Justificativa*: Drift fornece uma interface de escrita de queries tipadas em Dart integradas com SQLite nativo de alta latência e baixo consumo de memória, essencial para garantir que faturamentos e impressões físicas rodem sem internet.

### 2.3 Comunicação e APIs
* **Serverpod RPC**: Barramento principal síncrono estruturado.
* **REST / JSON**: Para integrações e webhooks externos.
* **WebSockets**: Para propagação de eventos reativos em tempo real (ex: sinalização de painel de cozinha).

### 2.4 IDEs e Ferramentas Oficiais
* **Desenvolvimento**: Android Studio / VS Code.
* **Diagnóstico de Banco**: DBeaver.
* **Versionamento**: Git / GitHub.
* **Modelagem e Diagramas**: Draw.io / Mermaid.
* **Documentação**: Markdown (com referências `file:///`).

### 2.5 Plataformas Suportadas (Roadmap de Prioridade)
A arquitetura deve permanecer multiplataforma desde o primeiro dia, respeitando a prioridade de lançamento:
1. **Windows Desktop** (Foco principal de balcão e retaguarda local)
2. **Android** (Foco em celulares de entregadores e operadores móveis)
3. **Web** (Foco em portais de autoatendimento e painéis executivos)
4. **Linux**
5. **macOS**
6. **iOS**

### 2.6 Servidores e Containerização
* **Servidor de Aplicação**: Serverpod.
* **Servidor Web / Proxy**: Nginx.
* **Containerização**: Docker.
* **Orquestração**: Docker Compose (desenvolvimento/homologação) ➔ Kubernetes (futuro em escala cloud).

### 2.7 Armazenamento de Arquivos
* **Local**: Sistema de arquivos local do computador físico.
* **Nuvem**: Armazenamento compatível com Amazon S3 (futuro).

### 2.8 Qualidade e CI/CD
* **Formatação**: `dart format`.
* **Análise estática**: `dart analyze`.
* **Testes Automatizados**: `flutter test` (local) e `serverpod test` (backend).
* **Versionamento**: GitHub / GitHub Actions (CI/CD) para homologação contínua.

---

## 3. Tecnologias Planejadas (Preparação Arquitetural)

Embora não façam parte do marco inicial, a arquitetura deve ser desenhada de forma desacoplada para permitir a incorporação futura das seguintes tecnologias:

### 3.1 Módulos Fiscais (Legislação B2B)
* Preparado para: **NFC-e, NF-e, SAT, CF-e, MDF-e, NFS-e e geração de DANFE** locais ou via APIs.

### 3.2 Gateways de Pagamento
* Preparado para: **PIX Dinâmico Automático, Mercado Pago, Stone, Cielo, PagSeguro e integração de TEF** físico no desktop.

### 3.3 Canais de Comunicação
* Preparado para: **WhatsApp Business API, E-mail transactional e Push Notifications**.

### 3.4 Integrações Externas
* Preparado para: **iFood API, plataformas de delivery, ERPs de terceiros e barramento de contabilidade**.

---

## 4. Consequências da Escolha

* **Positivas**:
  * Unificação de linguagem (toda a equipe desenvolve em Dart).
  * Sem atrito de tradução de payloads (os models do Serverpod geram código Dart nativo para o Flutter).
  * Disponibilidade offline garantida no balcão e na cozinha.
* **Negativas**:
  * Menor comunidade comparada a stacks legadas (como Node ou Java), mitigada pelo uso de bibliotecas robustas do ecossistema Dart/Flutter.

---

## 5. Princípio da Evolução Tecnológica

A stack definida é a base de sustentação da FINCORE. A alteração ou inclusão de qualquer componente da stack oficial exige:
1. Um problema empírico real a ser resolvido.
2. Análise e aprovação de impacto no acoplamento pelo comitê.
3. Formalização de um novo registro de decisão (ADR).
