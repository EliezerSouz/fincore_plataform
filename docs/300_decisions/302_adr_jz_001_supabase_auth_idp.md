# ADR-JZ-001: Supabase Auth como Identity Provider (IdP) Principal

> **Document ID**: 302  
> **Version**: 1.0.0  
> **Status**: APPROVED  
> **Owner**: Comitê Executivo (Principal Architect + Product Owner)  
> **Contexto**: Decisão de autenticação, identidade e autorização para a Jornada Zero (LC-1) no ecossistema FINCORE.

---

## 1. Contexto

A plataforma FINCORE é um sistema ERP SaaS Multi-Tenant que exige controle estrito de autenticação (saber quem é o usuário) e autorização (saber a quais tenants e dados ele tem acesso). Com a reestruturação para o modelo Customer Lifecycle (LC) e a priorização da **Jornada Zero (LC-1)**, precisamos de um mecanismo robusto, seguro e de fácil manutenção para gerenciar identidades globais, sem acoplar a lógica de negócios diretamente ao provedor de identidade.

---

## 2. Decisão Tomada

Adotar o **Supabase Auth** como o **Provedor de Identidade (IdP) principal** do FINCORE, enquanto o **Serverpod** atuará como a camada de **autorização e gerenciamento de sessões** de negócio.

A separação de responsabilidades será implementada da seguinte forma:

```
+--------------------+           JWT (Supabase)           +-----------------------+
|   Client (Flutter) | ─────────────────────────────────> | Serverpod Backend     |
+--------------------+                                    +-----------------------+
          │                                                           │
          │ Autenticação (User/Pass)                                  │ Validação JWT
          ▼                                                           ▼
+--------------------+                                    +-----------------------+
| Supabase Auth      |                                    | AuthMiddleware        |
+--------------------+                                    +-----------------------+
                                                                      │
                                                                      ▼
                                                          +-----------------------+
                                                          | tenantId extraído     |
                                                          | & Sessão resolvida    |
                                                          +-----------------------+
```

### 2.1 Fluxo de Autenticação e Autorização:
1. **Identidade**: O usuário se cadastra/autentica diretamente no **Supabase Auth** (via e-mail/senha ou futuramente provedores OAuth). O cliente Flutter recebe um JSON Web Token (JWT) assinado.
2. **Autorização**: A cada requisição para o backend Serverpod, o cliente envia o JWT no cabeçalho Authorization.
3. **Validação**: Um `AuthMiddleware` intercepta a chamada no Serverpod, valida a assinatura do JWT (usando a chave pública/segredo do Supabase Auth) e extrai o UID e o e-mail do usuário.
4. **Resolução de Contexto**: O Serverpod consulta a tabela `membros_empresa` para identificar qual `tenantId` e papel (`RoleEmpresa`) o UID possui e injeta essa informação no contexto do request.

---

## 3. Alternativas Consideradas e Rejeitadas

| Alternativa | Prós | Contras | Por que rejeitada? |
|---|---|---|---|
| **Serverpod Auth Module** | Nativo no framework, controle total do código e banco local único. | Exige implementar fluxos complexos de segurança (renovação, verificação de e-mail, MFA, login social) manualmente no backend. | Foco do FINCORE é a lógica do ERP. Desenvolver segurança do zero atrasaria o time e aumentaria riscos. |
| **Firebase Auth** | Madura, escalável, excelente SDK. | Vendor lock-in forte com a Google, integrações complexas fora do ecossistema Google, e não compartilha o mesmo banco PostgreSQL. | Supabase compartilha o mesmo banco Postgres subjacente e facilita a governança de dados. |
| **Supabase Completo (Backend nativo)** | Autenticação e autorização unificadas via Postgres RLS. | Lock-in de backend, lógica de negócio dispersa em SQL triggers e RLS policies. | Viola o princípio **WHY-002** (Serverpod como backend único). Queremos isolar a lógica de negócios em Dart. |

---

## 4. Consequências da Decisão

### Positivas:
* **Time-to-market**: Delegamos a segurança de borda (registro, criptografia de senhas, validação de e-mail, refresh tokens) para um serviço maduro e auditado.
* **Flexibilidade**: Podemos plugar logins sociais (Google, Microsoft) no futuro sem alterar uma linha de lógica do Serverpod.
* **Segurança**: As sessões do backend Serverpod são verificadas de forma stateless através da validação criptográfica do JWT, escalando horizontalmente.

### Negativas:
* **Dependência Externa**: O backend do ERP depende da integridade do Supabase Auth para validar logins (atenuada pela validação de assinatura que pode ser feita offline via chaves criptográficas).
* **Duplo Cadastro**: Dados do usuário (como nome) precisam ser sincronizados com a tabela global `usuarios` do Serverpod para uso nos fluxos internos do ERP.

---

## 5. Aprovação e Assinatura

* **Data**: 2026-07-26  
* **Tech Lead / Principal Architect**: Antigravity AI  
* **CTO**: Aprovado via Execution Reset v2.0  
