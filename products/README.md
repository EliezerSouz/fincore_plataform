# Catálogo de Produtos — FINCORE

> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este diretório abriga todos os verticais de produtos comerciais desenvolvidos sobre a infraestrutura compartilhada da FINCORE Platform.

---

## 🚀 Portfólio de Verticais

| Produto | Segmento de Mercado | Status Operacional | Documentação do Produto |
|---|---|---|---|
| **FINCORE Food** | Automação operacional para food service e encomendas de produção | 🛠️ Bootstrap (v1.0) | [fincore-food/README.md](file:///f:/Eigent/fincore_platform/products/fincore-food/README.md) |
| **FINCORE Finance**| Gestão de fluxo de caixa, conciliação e demonstrativos contábeis | 📅 Planned (v1.5) | — |
| **FINCORE CRM** | Hub de fidelização, promoções e automação de contatos | 📅 Planned (v1.5) | — |
| **FINCORE Analytics**| Inteligência e dashboards preditivos de faturamento | 📅 Planned (v2.0) | — |
| **FINCORE AI** | Agente conversacional e assistente preditivo de lotes | 📅 Planned (v2.0) | — |

---

## 🛠️ Regra de Governança para Novos Produtos

1. **Aprovação do Comitê**: Nenhum produto novo entra na árvore `products/` sem passar por um processo formal de aprovação estratégico do comitê.
2. **Desacoplamento Absoluto**: Produtos são estritamente isolados em suas respectivas pastas. É proibido qualquer acoplamento direto ou importação de arquivos entre dois produtos (ex: importar algo de `fincore-food` em `fincore-finance`).
3. **Compartilhamento via Packages**: Qualquer componente, utilitário ou lógica de negócio comum entre dois ou mais produtos deve ser extraído e hospedado sob a pasta `/packages/`.

---

*Catálogo de Produtos — FINCORE Platform*
