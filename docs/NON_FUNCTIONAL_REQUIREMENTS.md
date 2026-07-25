# NON-FUNCTIONAL REQUIREMENTS (NFR)

> Este documento define os requisitos de engenharia não-funcionais que governam o comportamento e a infraestrutura da plataforma, garantindo a viabilidade do produto para comercialização SaaS.

---

## 1. Desempenho e Latência (Performance)

| Métrica | Requisito Técnico | Critério de Aceitação |
|---|---|---|
| **Tempo de Inicialização** | Boot do app local | < 1.5s até renderizar a tela de Login/Shell (se logado) |
| **Latência de Renderização**| Mudança de estado da UI | < 50ms (sem travamento no main isolate do Flutter) |
| **Tempo de Impressão** | Envio de comando térmica | < 200ms entre clicar e iniciar o spooler físico |
| **Latência de API Cloud** | Tempo de resposta Serverpod | < 300ms em requisições de leitura de catálogo/preços |

---

## 2. Disponibilidade e Resiliência (Availability)

* **Disponibilidade Local**: O aplicativo desktop deve operar com **100% de disponibilidade local**. Nenhuma falha na rede de internet pode impedir Maria de vender ou Thiago de produzir.
* **Resiliência Transacional**: Mutações locais são gravadas de forma ACID no Drift SQLite. Em caso de queda de energia durante uma gravação de pedido, o Drift reverte a transação ao estado íntegro anterior.
* **Conectividade**: Quedas na API Cloud não disparam diálogos de erro bloqueantes na UI; apenas atualizam silenciosamente o status do badge de conectividade.

---

## 3. Escalabilidade Cloud (Scalability)

* **Multi-Tenant RLS Overhead**: O uso de Row-Level Security no Postgres não pode degradar a latência de busca em mais de 5%. Todas as políticas de isolamento transacional devem utilizar índices compostos baseados na coluna `tenant_id`.
* **Throughput do Servidor**: O backend Serverpod deve suportar até 500 conexões ativas simultâneas na v1.0, escalando horizontalmente via clusters Docker com balanceamento de carga.

---

## 4. Backup e Recuperabilidade (RPO e RTO)

* **RPO (Recovery Point Objective)**:
  * Banco de Dados Cloud (Postgres): Máximo de 24 horas (backups diários automáticos retidos por 30 dias).
  * Banco de Dados Local (SQLite): Zero perda de transações persistidas. O backup local é exportado em segundo plano para o diretório de auditoria local a cada fechamento de caixa.
* **RTO (Recovery Time Objective)**:
  * Recuperação de queda do servidor na nuvem: < 4 horas.

---

## 5. Limites e Timeouts de Infraestrutura

* **Timeout de Requisições HTTP/API**: Máximo de 15 segundos para requisições de API normais. Se expirar, entra no fluxo de retry com backoff exponencial.
* **Timeout de Geração PIX**: Limite de 8 segundos para a API do Serverpod retornar o QR Code dinâmico do gateway de pagamentos. Se exceder, entra no fluxo de contingência do PIX estático manual.
* **Tamanho de Payload de Sincronização**: Lotes de envio limitados a 50 registros por requisição para evitar estouro de memória e timeout de rede em computadores fracos.

---

## 6. Acordo de Nível de Serviço (SLA) Operacional

* **SLA de Alerta de Cozinha**: Pedidos agendados com menos de 30 minutos para entrega e ainda não marcados como `Prontos` acionam o estado de alerta crítico (Pulse + Alerta Sonoro grave).
* **SLA de Resposta Logística**: Pedidos prontos na Expedição devem ser atribuídos a uma rota física de motoboy em no máximo 10 minutos após a finalização da embalagem.

---

*Requisitos Não-Funcionais Técnicos — Eigent Food Service Platform*
