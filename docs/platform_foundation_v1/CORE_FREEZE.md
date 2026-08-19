# Protocolo de Congelamento do Core — FINCORE

Este documento formaliza as diretrizes de integridade e o protocolo de alteração dos pacotes congelados da plataforma.

---

## 🔒 Lista de Pacotes Bloqueados
Os pacotes abaixo estão sob regime de **Congelamento Estrito**:
- `fincore_core`
- `fincore_design_system` (camada de tokens e base bridge)
- `fincore_shared`
- `fincore_pricing`

---

## 🔄 Fluxo de Alteração de Arquitetura (RFC & ADR)

Qualquer alteração nos pacotes congelados deve seguir rigorosamente o seguinte fluxo de governança de engenharia:

```text
       Nova Necessidade ou Correção Estrutural
                          │
                          ▼
            Abertura de uma RFC (Markdown)
       (Descrever problema, soluções e impactos)
                          │
                          ▼
             Revisão pelo Comitê de Core
        (Aprovação técnica e alinhamento)
                          │
                          ▼
            Escrita e Aprovação da ADR
       (Registrar a decisão no docs/300_decisions/)
                          │
                          ▼
             Desenvolvimento da Branch
        (Merge com Tag e Checklist do Quality Gate)
```

---

## 📝 Regras de Branch e Versionamento

1. **Alterações de Correção (Patch)**: Podem ser feitas sem RFC se resolverem bugs diretos documentados, mas exigem passagem no Quality Gate e testes automatizados.
2. **Alterações de Funcionalidades (Minor/Major)**: Exigem aprovação de RFC e registro de nova ADR no catálogo.
3. **Tags de Liberação**: Todo merge nos pacotes congelados deve gerar uma tag de versão unificada seguindo versionamento semântico (SemVer).
