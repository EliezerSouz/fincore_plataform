# ADR-JZ-002: Modelo `usuarios` Global sem `tenantId`

> **Document ID**: 303  
> **Version**: 1.0.0  
> **Status**: APPROVED  
> **Owner**: Comitê Executivo (Principal Architect + Product Owner)  
> **Contexto**: Decisão de modelagem e arquitetura multi-tenant para usuários e empresas na Jornada Zero (LC-1).

---

## 1. Contexto

O FINCORE é desenhado para ser multi-tenant nativo. O **Princípio 2 da Constitution** afirma que `tenantId` é obrigatório em todas as tabelas. No entanto, para permitir um modelo de negócios SaaS B2B robusto e moderno (semelhante ao Notion, Slack, GitHub e Linear), um único usuário real (com e-mail único) deve ser capaz de participar, criar e gerenciar múltiplos tenants (ex: Empresa A e Empresa B) com a mesma credencial, ou participar de cenários de matriz e filiais, sem precisar criar contas diferentes.

Se colocarmos `tenantId` diretamente na tabela de usuários, limitamos o usuário a pertencer a apenas um tenant para sempre.

---

## 2. Decisão Tomada

Desacoplar a identidade do usuário da relação de tenant no banco de dados. A tabela `usuarios` será **global** (sem a coluna `tenantId`), e o vínculo de um usuário com uma ou mais empresas será gerenciado pela tabela de junção `membros_empresa` (esta sim contendo `tenantId`).

### 2.1 Modelo de Relações:

```
+------------------------------------------+
|                 usuarios                 |
| (Global - Sem tenantId)                  |
| - id: String (PK, Supabase UID)          |
| - email: String (Unique)                 |
| - nome: String                           |
+------------------------------------------+
                     │ 1
                     │
                     │ N
+------------------------------------------+
|             membros_empresa              |
| (Multi-Tenant - Contém tenantId)         |
| - id: String (PK)                        |
| - tenant_id: String (FK empresas)        |
| - usuario_id: String (FK usuarios)       |
| - role: RoleEmpresa (Enum)               |
| - ativo: Boolean                         |
+------------------------------------------+
                     │ N
                     │
                     │ 1
+------------------------------------------+
|                 empresas                 |
| (Cada registro é um Tenant)             |
| - id: String (PK, tenantId)              |
| - status: StatusEmpresa (Enum)           |
| - plano: PlanoEmpresa (Enum)             |
+------------------------------------------+
```

### 2.2 Regra de Exceção da Constitution:
A tabela global `usuarios` constitui uma **exceção válida e justificada ao Princípio 2 da Constitution**. Esta exceção é estritamente restrita a identidades globais gerenciadas por IdP externo. Qualquer outra tabela de negócio (produtos, categorias, clientes, vendas, etc.) permanece sob a obrigatoriedade incondicional da coluna `tenantId` na primeira posição.

---

## 3. Alternativas Consideradas e Rejeitadas

| Alternativa | Prós | Contras | Por que rejeitada? |
|---|---|---|---|
| **`tenantId` direto na tabela `usuarios`** | Segue estritamente o Princípio 2. Simplifica queries. | Limita um usuário a gerenciar uma única empresa. Inviabiliza cenários de matriz/filiais e contadores parceiros. | Restringe severamente o crescimento do modelo SaaS e força retrabalho arquitetural massivo no futuro. |
| **Banco de dados separado por Tenant** | Isolamento total de segurança física por tenant. | Custo de infraestrutura proibitivo para pequenos clientes (viola **WHY-004**), deploy e migrações complexas. | Rejeitado por custo de infraestrutura (Margem B2B desfavorável para microempresas brasileiras). |
| **Duplicação de usuários por tenant** | Mantém `tenantId` na tabela de usuários. | Se o mesmo usuário mudar de senha na Empresa A, a senha continuaria antiga na Empresa B. Inconsistência de perfis. | Péssima experiência do usuário e alta complexidade de sincronização de credenciais. |

---

## 4. Consequências da Decisão

### Positivas:
* **Multi-empresa Nativo**: Um usuário acessa múltiplos tenants com a mesma conta e pode trocar de espaço de trabalho (workspace) na interface.
* **Segurança e Auditoria**: O vínculo de membros pode ser ativado/desativado em um tenant específico sem excluir a conta global do usuário.
* **Gestão de Equipes**: Facilita o envio de convites de colaboração e fluxo de aceite por e-mail.

### Negativas:
* **Filtro RLS**: A tabela `usuarios` não pode ser filtrada por RLS direto com base em `tenantId`, exigindo validação via query adaptada ou policies baseadas no vínculo `membros_empresa`.

---

## 5. Aprovação e Assinatura

* **Data**: 2026-07-26  
* **Tech Lead / Principal Architect**: Antigravity AI  
* **CTO**: Aprovado via Execution Reset v2.0  
