# Status de Conformidade do Design System — FINCORE

Este documento registra o estado atual do **Fincore Design System** após a consolidação da Fase A e define a rota de eliminação das dependências legadas.

---

## 📊 Tabela de Conformidade Atual

| Item | Status | Uso Atual | Meta V2 |
| :--- | :---: | :--- | :--- |
| **Cores Primárias** | 🟢 **Em Conformidade** | Dinâmicas via `ThemeController.instance.tokens` | Concluído |
| **Cores Secundárias** | 🟡 **Bridge Ativa** | Estáticas no `FincoreColors` | Substituir por `context.tokens` |
| **Espaçamentos** | 🔴 **Não Conforme** | `EdgeInsets.all` e `SizedBox` com valores fixos | Substituir por `context.spacing` |
| **Bordas/Cantos** | 🔴 **Não Conforme** | `BorderRadius.circular` hardcoded nas telas | Substituir por `context.radius` |
| **Animações** | 🔴 **Não Conforme** | `Duration(milliseconds: X)` espalhados | Substituir por `context.motion` |
| **Sombras** | 🟡 **Parcial** | Uso de `FincoreShadows.md` | Migrar para `context.shadows` |

---

## 🔍 Detecção de Violações Atuais (Dívidas de UX)

Nas telas atuais (`categorias_page.dart`, `usuarios_page.dart`, `clientes_page.dart`, etc.), identificamos:
1. **Margens e Paddings**: O uso de `const EdgeInsets.symmetric(horizontal: 16, vertical: 12)` é a maior violação. Estes valores devem migrar para `EdgeInsets.symmetric(horizontal: context.spacing.lg, vertical: context.spacing.md)`.
2. **Cantos Arredondados**: O uso de `BorderRadius.circular(8)` ou `BorderRadius.circular(12)` está hardcoded nos cards. Devem consumir `context.radius.borderMedium` ou `context.radius.borderLarge`.
3. **Animações**: Transições de expansão e abertura usam valores avulsos como `const Duration(milliseconds: 200)`. Devem ser substituídas por `context.motion.fast`.

---

## 🛣️ Rota de Transição para Fase B
Telas novas e telas refatoradas deverão adotar obrigatoriamente a sintaxe baseada em contexto e as especificações de componentes:

```dart
// [ANTES - Proibido]
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: FincoreColors.surface,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text('Olá', style: TextStyle(color: FincoreColors.textPrimary)),
)

// [DEPOIS - Permitido]
Container(
  padding: EdgeInsets.all(context.spacing.lg),
  decoration: BoxDecoration(
    color: context.tokens.surface,
    borderRadius: context.radius.borderMedium,
    boxShadow: context.shadows.shadowXS,
  ),
  child: Text('Olá', style: TextStyle(color: context.tokens.textPrimary)),
)
```
