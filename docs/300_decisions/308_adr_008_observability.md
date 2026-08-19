# ADR-008: Observabilidade e Auditoria Forense

## Status
Aprovado (Freeze V1)

## Contexto
O ecossistema FINCORE exige rastreamento detalhado de transações comerciais, fiscais e auditoria de ações de usuários (especialmente em ambientes multi-tenant e offline-first). Precisamos saber exatamente quem executou determinada operação, qual dispositivo foi utilizado, a geolocalização aproximada (IP), e o histórico exato de alterações em cada registro de banco de dados (diffing forense).

## Decisão
Adotamos um sistema unificado de logs e auditoria baseado em três pilares:
1. **Trace ID**: Cada ciclo de sincronização ou operação sensível gera um identificador único de rastreamento (ex: `SYNC-1E5A7B`) propagado entre o app cliente (SQLite) e o servidor de nuvem.
2. **Registro de Auditoria Forense (`AuditLogsTable`)**: Registra inserções, atualizações e exclusões locais e remotas com metadados detalhados de sessão, dispositivo, IP, plataforma, versão do app e a diferença de dados (diff em formato JSON).
3. **LogService estruturado**: Registro de eventos divididos por módulos funcionais (`LogModule.sync`, `LogModule.auth`, `LogModule.db`, `LogModule.printer`) gravados localmente em arquivos físicos rotativos e sincronizados em background.

## Consequências
- **Positivas**:
  - Capacidade total de auditoria forense para ações administrativas.
  - Facilidade de diagnóstico de falhas em produção por meio do agrupamento por Trace ID.
  - Conformidade com regras rígidas de segurança corporativa e auditorias externas.
- **Negativas**:
  - Leve overhead de CPU/memória para serialização de diffs de dados durante atualizações.
  - Aumento do consumo de armazenamento local devido ao histórico persistido ( mitigado por políticas de rotação de logs).
