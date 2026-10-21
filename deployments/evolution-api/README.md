# Evolution API v2 — Guia Operacional FINCORE

Este diretório contém a infraestrutura e configuração completa da **Evolution API v2** para integração com WhatsApp.

---

## 1. Arquitetura dos Serviços

O ambiente roda isolado via Docker com 3 contêineres:
- **`evolution_postgres`**: Banco de dados relacional PostgreSQL 16 para persistência de instâncias, contatos e mensagens.
- **`evolution_redis`**: Cache em memória e controle de sessões para alto desempenho.
- **`evolution_api`**: Servidor oficial da Evolution API v2 (`evoapicloud/evolution-api:latest`).

---

## 2. Painel Gerencial e Endpoints

- **Evolution Manager (Painel Web):** `http://localhost:8080/manager`
- **URL Base da API:** `http://localhost:8080`
- **Header Obrigatório:** `apikey: <AUTHENTICATION_API_KEY>` (definida no arquivo `.env`)
- **Instância Padrão Conectada:** `fincore_atendimento`

---

## 3. Comandos Operacionais

### Iniciar o ambiente
```bash
docker compose up -d
```
Ou dê dois cliques no arquivo `iniciar.bat`.

### Verificar status e logs
```bash
# Status dos contêineres
docker compose ps

# Logs em tempo real
docker compose logs -f evolution-api
```

### Parar o ambiente
```bash
docker compose down
```
Ou dê dois cliques no arquivo `parar.bat`.

---

## 4. Endpoints Principais

### Status da Conexão da Instância
```bash
curl -X GET http://localhost:8080/instance/connectionState/fincore_atendimento \
  -H "apikey: fincore_sec_9f8e7d6c5b4a3a2b1c0d_api"
```

### Enviar Mensagem de Texto (UTF-8)
```bash
curl -X POST http://localhost:8080/message/sendText/fincore_atendimento \
  -H "Content-Type: application/json; charset=utf-8" \
  -H "apikey: fincore_sec_9f8e7d6c5b4a3a2b1c0d_api" \
  -d '{
    "number": "553592503114",
    "text": "*Olá!* Pedido confirmado com sucesso! 🚀"
  }'
```
