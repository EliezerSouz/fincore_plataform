# Escopo do Produto: Domínios, Workspaces e Control Center (Fase 1)

> **Document ID**: 105  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este documento descreve as capacidades de negócio, os bounded contexts e as interfaces adaptativas do FINCORE Food.

---

## 1. A Hierarquia de Pensamento do Produto

O produto é organizado assim:

```
EMPRESA (quem usa)
    ↓
OPERAÇÃO (o que faz no dia a dia)
    ↓
CAPACIDADES DE NEGÓCIO (o que o sistema sabe fazer)
    ↓
DOMÍNIOS (como o conhecimento é agrupado)
    ↓
WORKSPACES (o ambiente visual por perfil)
    ↓
FUNCIONALIDADES (ações concretas)
    ↓
TELAS (a interface final)
```

---

## 2. As 9 Capabilities do Produto

1. **RECEBER PEDIDOS**: O sistema sabe receber pedidos de qualquer origem (PDV Express, Web, WhatsApp IA, APIs).
2. **PLANEJAR PRODUÇÃO**: O sistema sabe o quanto produzir, quando e para quem (capacidades, agendas, bloqueios).
3. **PRODUZIR**: O sistema sabe registrar o que foi produzido, por quem e quando (lotes, validade FIFO).
4. **SEPARAR & EMBALAR**: O sistema sabe o que precisa sair, para quem e em que ordem (checklist digital).
5. **ENTREGAR**: O sistema sabe organizar, roteirizar e rastrear entregas.
6. **RECEBER PAGAMENTO**: O sistema sabe cobrar, confirmar e conciliar (caixa, PIX dinâmico automático).
7. **FIDELIZAR**: O sistema sabe reconhecer, reter e recompensar clientes.
8. **ANALISAR NEGÓCIO**: O sistema sabe transformar dados operacionais em decisões (DRE, custos).
9. **ADMINISTRAR**: O sistema sabe configurar, controlar e governar a plataforma (Control Center).

---

## 3. Domínios de Negócio (Bounded Contexts)

As 9 capacidades se organizam em **5 domínios** + **2 domínios de plataforma**:
* **COMERCIAL**: Receber Pedidos (①), Fidelizar (⑦)
* **OPERACIONAL**: Planejar (②), Produzir (③), Separar (④), Entregar (⑤)
* **FINANCEIRO**: Receber Pagamento (⑥), Analisar Negócio (⑧)
* **OMNICHANNEL**: Adaptadores de entrada (PDV, Web, WhatsApp IA, API)
* **EXPERIENCE**: Workspaces, Preferências, Notificações, Temas
* **PLATAFORMA**: Administrar (⑨), Identidade, Sync, Feature Flags, Licenciamento

---

## 4. Workspaces por Perfil

* **Conceito de Persona Temporária**: O dono pode trocar de workspace sem trocar de usuário. Isso permite simular a interface de atendimento ou da cozinha em tempo real para auditoria e treinamentos rápidos.
* **Workspaces Definidos**:
  * **DONO**: Dashboard Executivo e Control Center.
  * **ATENDENTE**: PDV (Express/Completo), Fila de Vendas do Dia e controle de Caixa.
  * **COZINHA**: Painel de Preparo, Agenda do Dia, Registro de Lotes e Insumos.
  * **EXPEDIÇÃO**: Pedidos Prontos, Checklist de Embalagem e Roteirização.
  * **FINANCEIRO**: Fluxo de Caixa, Contas a Receber e Fechamento.

---

## 5. Control Center (ex-Centro Administrativo)

O Control Center é um hub de governança com as seguintes divisões:
* 🏢 **Empresa**: Razão social, CNPJ, dados fiscais.
* 👥 **Operação**: Usuários, operadores, permissões granulares por perfil e simulações.
* 💳 **Cobrança**: Formas de pagamento, regras de PIX e taxas.
* 🔗 **Integrações**: WhatsApp API, iFood, gateways externos.
* 📡 **Canais**: Configurações de impressão térmica, URLs do Portal Web e IA.
* 🚚 **Logística**: Bairros, taxas por região e entregadores.
* 🔄 **Plataforma**: Sincronização, Backups e Feature Flags do SaaS.
* 🔍 **Diagnóstico**: Logs estruturados JSON e status de conectividade.
* 🎨 **Experiência**: Temas, cores do PDV e idiomas.

---

## 6. Feature Flags Tridimensionais

As feature flags controlam as capacidades do produto sob 3 dimensões cruzadas:
* **Plano da Empresa**: Starter, Pro ou Enterprise habilitam o recurso no banco cloud.
* **Perfil do Usuário**: Dono, Atendente, Cozinha definem nível de acesso (Ler, Escrever, Admin).
* **Capability de Negócio**: Conecta o recurso ao domínio transacional do monorepo.
