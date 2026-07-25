# QUALITY ATTRIBUTES

> [!NOTE]
> Os atributos de qualidade definem as restrições técnicas não-funcionais que cada capacidade de negócio precisa respeitar. Eles servem como critério de aceitação de arquitetura e código antes de qualquer funcionalidade entrar em homologação.

---

## Atributos de Qualidade por Capacidade

### ① Comercial — Receber Pedidos

| Atributo | Requisito Técnico | Critério de Aceitação |
|---|---|---|
| **Disponibilidade** | 100% Local (Offline) | O fluxo de emissão não pode depender de rede |
| **Latência** | Resposta instantânea de digitação | < 50ms para renderizar busca local de itens/clientes |
| **Auditável** | Event Sourcing de alterações | Cada pedido alterado cria uma linha imutável no log local |
| **Perda de Dados** | Zero local | Transação em SQLite ACID antes de disparar interface |

### ② Produção — Planejar Produção

| Atributo | Requisito Técnico | Critério de Aceitação |
|---|---|---|
| **Sincronismo** | Sincronia de lotes sob demanda | Se offline, planeja local; ao reestabelecer, calcula MRP em nuvem |
| **Resiliência** | Cache de capacidade local | Dados de capacidade diária pré-carregados para operação offline |
| **Segurança** | Restrição de leitura/gravação | Apenas perfis autorizados (Dono/Supervisor) editam metas |

### ③ Produção — Produzir

| Atributo | Requisito Técnico | Critério de Aceitação |
|---|---|---|
| **Disponibilidade** | 100% Local (Offline) | O operador de cozinha pode registrar produções sem conexão |
| **Tempo de Execução**| Registro de lote imediato | Processamento da transação Drift/SQLite < 150ms |
| **Resolução Conflitos**| Sobrescrita pela data mais recente| Regra baseada em timestamp (`atualizadoEm`) no sync do lote |

### ④ Comercial — Separar & Embalar

| Atributo | Requisito Técnico | Critério de Aceitação |
|---|---|---|
| **Confiabilidade** | Integridade transacional de estoque | FIFO bloqueado contra concorrência de leitura |
| **Feedback UI** | Feedback auditivo/visual claro | Som de sucesso/erro na leitura de códigos ou checklists |
| **Disponibilidade** | Offline obrigatório | Visualização da fila de expedição do dia mantida localmente |

### ⑤ Logística — Entregar

| Atributo | Requisito Técnico | Critério de Aceitação |
|---|---|---|
| **Desempenho** | Agrupamento geográfico veloz | Processamento local de roteirização por proximidade < 2s |
| **Precisão** | Geolocalização persistida | Coordenadas de bairros cacheadas localmente |
| **Offline** | Modo avião no celular entregador | O app de entrega sincroniza logs ao retornar da rota |

### ⑥ Financeiro — Receber Pagamento

| Atributo | Requisito Técnico | Critério de Aceitação |
|---|---|---|
| **Segurança** | Criptografia local | Token de conciliação PIX armazenado com segurança (Keystore/Keychain) |
| **Confiabilidade** | Log de auditoria de fechamento | Nenhuma divergência pode ser deletada ou editada após fechamento |
| **Resiliência** | Contingência PIX | Se fora do ar, geração de PIX dinâmico local via chave estática embutida |

### ⑦ Comercial — Fidelizar

| Atributo | Requisito Técnico | Critério de Aceitação |
|---|---|---|
| **Acurácia** | Unicidade por dígitos | Normalização rígida de telefones para evitar duplicidade de clientes |
| **Desempenho** | Busca rápida por telefone | Indexação de coluna de dígitos no Drift SQLite para busca instantânea |

### ⑧ Financeiro — Analisar Negócio

| Atributo | Requisito Técnico | Critério de Aceitação |
|---|---|---|
| **Desempenho** | Agregações assíncronas | Queries pesadas de DRE rodam em isolates separados ou nuvem |
| **Privacidade** | Restrição total de dados | Criptografia na transmissão de demonstrativos financeiros |

### ⑨ Plataforma — Administrar

| Atributo | Requisito Técnico | Critério de Aceitação |
|---|---|---|
| **Multi-Tenancy** | Isolamento rígido | Row-level Security no Postgres; tenant isolation na base local |
| **Recuperabilidade**| RTO < 4h (SaaS) / RPO < 24h | Estratégia de backup automático da base Postgres em nuvem |
| **Sincronismo** | Sync resiliente a perdas de pacote| Protocolo de retry exponencial para reenvio de payloads |

---

*Atributos de Qualidade Técnica — Eigent Food Service Platform*
