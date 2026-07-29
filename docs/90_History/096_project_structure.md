---
Title: 096 project structure
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# Estrutura do Diretório de Documentos (Project Documentation Structure)

> **Document ID**: 096  
> **Version**: 1.0.0  
> **Status**: ✍️ Ativo  
>
> Este documento mapeia a organização e indexação do diretório `/docs` da FINCORE Platform, garantindo localizabilidade e ordenação lógica.

---

## 📂 Layout de Diretórios da Documentação

A taxonomia de numeração e separação física do diretório `/docs` é estruturada da seguinte forma:

```text
docs/
├── 000_documentation_manifesto.md   # Manifesto e autoridade documental
├── 010_platform_vision.md            # Visão de longo prazo da FINCORE Platform
├── 020_platform_architecture.md      # Princípios e stack tecnológica de alto nível
├── 030_product_roadmap.md            # Calendário macro de marcos (Milestones)
├── 040_platform_principles.md        # Princípios gerais de UX, Offline e Tenancy
├── 050_design_system_spec.md         # Tokens de cor, tipografia e regras de motion
│
├── 060_domains/                      # Especificações funcionais por domínio
│     ├── 101_product_master_plan.md
│     ├── 100_platform_core_architecture.md
│     ├── 120_platform_configuration_domain.md
│     ├── 121_pricing_and_product_domain.md
│     ├── 122_pricing_engine_domain.md
│     ├── 123_pricing_resolution_domain.md
│     ├── 124_seed_data.md
│     └── ...
│
├── 090_engineering/                  # Processos e padrões de desenvolvimento
│     ├── 090_engineering_process.md
│     ├── 091_definition_of_done.md
│     ├── 095_documentation_standards.md
│     └── 096_project_structure.md
│
├── 110_adr/                          # Arquivos de Decisão Arquitetural (ADRs)
│     ├── 301_adr_001_official_technology_stack.md
│     └── ...
│
├── 120_reports/                      # Histórico de Relatórios de Implementação
│     ├── YYYY-MM-DD_platform_core.md
│     └── ...
│
└── 140_templates/                    # Modelos de cabeçalho e estrutura markdown
      ├── prd_template.md
      ├── adr_template.md
      └── implementation_report_template.md
```

### Regras de Organização:
1. Novos documentos gerais devem seguir a numeração sequencial conforme a sua respectiva seção.
2. A alteração da estrutura física de pastas deve ser aprovada e registrada neste documento.
