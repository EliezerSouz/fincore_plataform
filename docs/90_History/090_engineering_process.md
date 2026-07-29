---
Title: 090 engineering process
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# Processo de Engenharia e Governança (Engineering Process)

> **Document ID**: 090  
> **Version**: 1.0.0  
> **Status**: ✍️ Ativo  
>
> Este documento oficializa o processo de governança de engenharia para o desenvolvimento da FINCORE Platform, garantindo a rastreabilidade completa das implementações e a sincronização contínua entre código e especificações.

---

## 🔄 1. Ciclo de Vida do Desenvolvimento

Toda implementação (seja de infraestrutura core ou de módulos de negócio) deve seguir obrigatoriamente o seguinte fluxo sequencial:

```text
Planejamento ➔ Implementação ➔ Testes ➔ Relatório de Implementação ➔ Atualização Documental ➔ CHANGELOG ➔ Homologação
```

1. **Planejamento**: Elaboração do PRD ou Plano de Implementação descrevendo o desenho técnico e de domínio.
2. **Implementação**: Escrita do código limpo alinhado às diretrizes arquiteturais.
3. **Testes**: Execução e aprovação da suíte de testes unitários e de integração locais.
4. **Relatório de Implementação**: Criação de um relatório consolidando o que foi feito na milestone.
5. **Atualização Documental**: Revisão e atualização de roadmaps, PRDs, ADRs e diagramas afetados.
6. **CHANGELOG**: Registro detalhado dos acréscimos, alterações e correções no CHANGELOG do monorepo.
7. **Homologação**: PR review, testes no CI/CD e merge.

---

## 📂 2. Estrutura de Pastas de Governança

Para manter a rastreabilidade histórica e documentação viva, o diretório `/docs` do monorepo é estruturado da seguinte forma:

```text
docs/
├── 000_index.md                     # Índice geral de documentação
├── 090_engineering_process.md       # Este documento de processo
├── 091_definition_of_done.md         # Definição de Done (DoD) oficial
├── 101_product_master_plan.md       # Mapa geral e governança do produto
├── 120_platform_configuration_domain.md # Centro de Configuração da Plataforma
├── adr/                             # Architectural Decision Records (ADRs)
│     ├── 001_official_tech_stack.md
│     └── ...
├── implementation/                  # Registro de execuções
│     ├── README.md                  # Introdução e mapa de relatórios
│     ├── reports/                   # Relatórios das Milestones (.md)
│     └── migrations/                # Histórico de alterações e migrações
└── templates/                       # Modelos para novos documentos
      ├── prd_template.md
      ├── adr_template.md
      └── implementation_report_template.md
```

---

## 📝 3. Relatórios de Implementação

Ao concluir qualquer Milestone, o desenvolvedor é obrigado a criar um relatório em `docs/implementation/reports/` seguindo a nomeclatura `YYYY-MM-DD_[milestone_name].md` para detalhar o escopo entregue, migrações efetuadas, testes executados e pendências de débito técnico.

O modelo padrão encontra-se em `docs/templates/implementation_report_template.md`.

---

## 📋 4. Atualização Documental Obrigatória

> **Documentação como Fonte da Verdade**: Toda alteração estrutural, arquitetural ou funcional deverá ser refletida na documentação correspondente antes da conclusão da implementação.

Nenhum Pull Request será aprovado se houver alteração de comportamento técnico ou de negócio sem a devida atualização dos documentos lógicos. O desenvolvedor deve obrigatoriamente preencher a seguinte checklist na descrição do PR:

- [ ] Atualização do Roadmap/Master Plan (caso altere escopo de entrega).
- [ ] PRD de domínio relacionado revisado e atualizado.
- [ ] Nova ADR registrada (se houver decisões arquiteturais importantes).
- [ ] Diagramas técnicos e fluxogramas atualizados.
- [ ] CHANGELOG atualizado com a nova versão de entrega.
- [ ] Relatório de Implementação da Milestone criado.
