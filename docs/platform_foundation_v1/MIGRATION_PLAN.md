# Plano de Migração Gradual — FINCORE Design System

Este documento instrui os engenheiros de software sobre como migrar com segurança as telas existentes de `FincoreColors` para os novos tokens baseados no escopo de tema.

---

## 🚦 Guia Passo a Passo de Migração

### Passo 1: Remover modificadores `const` impeditivos
Como a nova arquitetura consome tokens dinâmicos via contexto, você precisará remover a palavra-chave `const` de declarações de widgets pais que envelopam a cor modificada.

```dart
// [Antes]
const TextStyle(color: FincoreColors.textPrimary)

// [Depois]
TextStyle(color: context.tokens.textPrimary)
```

### Passo 2: Substituir referências estáticas de cores
Mapeie as antigas chamadas de `FincoreColors` para a nova propriedade semântica no `context.tokens`:

| Antigo | Novo (Recomendado) |
| :--- | :--- |
| `FincoreColors.primary` | `context.tokens.actionPrimary` |
| `FincoreColors.background` | `context.tokens.background` |
| `FincoreColors.surface` | `context.tokens.surface` |
| `FincoreColors.border` | `context.tokens.border` |
| `FincoreColors.textPrimary` | `context.tokens.textPrimary` |
| `FincoreColors.textMuted` | `context.tokens.textMuted` |

### Passo 3: Substituir Margens e Paddings
Remova o uso de números mágicos e declare paddings usando `context.spacing`:

```dart
// [Antes]
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)

// [Depois]
padding: EdgeInsets.symmetric(
  horizontal: context.spacing.lg,
  vertical: context.spacing.sm,
)
```

### Passo 4: Atualizar Arredondamento de Cantos
Use os tokens de raio dinâmicos que herdam as configurações do Tenant:

```dart
// [Antes]
borderRadius: BorderRadius.circular(8)

// [Depois]
borderRadius: context.radius.borderMedium
```
---

## 🧪 Estratégia de Homologação da Tela Migrada
Após migrar uma tela, você deve:
1. Compilar e rodar a tela localmente no simulador.
2. Alternar entre o **Modo Claro** e o **Modo Escuro** no `ThemeController` (Configurações) para validar que todos os elementos visuais mudaram de cor instantaneamente.
3. Testar em resoluções de tablet e desktop para garantir consistência de responsividade.
