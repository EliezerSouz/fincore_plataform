# MONOREPO STRUCTURE & DEPENDENCY CONTRACT

> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este documento rege a arquitetura de pacotes e a governança de acoplamento entre os diferentes diretórios do monorepo `fincore_platform`. 

---

## 1. Diretórios e Responsabilidades

O monorepo é dividido em 4 camadas físicas na raiz:

1. **`docs/`**: Contém exclusivamente especificações estruturais de produtos, diretrizes estratégicas e registros de decisão (ADRs).
2. **`products/`**: Contém os verticais de produtos de mercado independentes (ex: `fincore-food`).
3. **`packages/`**: Contém pacotes utilitários de código reutilizável importado por múltiplos produtos (ex: `design_system`, `shared`, `logging`).
4. **`tools/`**: Contém scripts de automação, CLI e templates de build da plataforma.

---

## 2. Matriz de Dependências Permitidas

Para evitar acoplamento cruzado indesejado e lentidão em builds, a hierarquia de importação de código deve respeitar a ordem decrescente (da esquerda para a direita):

```
PLATAFORMA ➔ PACKAGES ➔ PRODUCTS ➔ APPS/EXECUTÁVEIS
```

* **Plataforma (Core)**: Classes base abstratas em `/packages/core/` não dependem de nada.
* **Packages**: Pacotes específicos (ex: `sync`, `logging`) podem importar utilitários de `core` ou `shared`.
* **Products**: Um produto de mercado (ex: `fincore-food`) pode importar qualquer pacote localizado em `/packages/` (ex: `sync`, `design_system`).
* **Apps/Executáveis**: Os executáveis locais do Flutter (PDVs) ou servidores Serverpod importam o código do seu respectivo domínio de produto em `products/`.

---

## 3. Matriz de Dependências Proibidas

Qualquer violação das regras abaixo reprova automaticamente o código na pipeline de Pull Request (Design/Code Review Gate):

### 3.1 Proibição de Dependência Cruzada entre Verticais (Horizontal Block)
É estritamente proibido que um produto comercial importe código ou referencie caminhos de outro produto comercial.
* **❌ PROIBIDO**: `import 'package:fincore-food/...';` dentro do produto `fincore-finance`.

### 3.2 Proibição de Dependência Reversa (Bottom-Up Block)
É proibido que pacotes compartilhados dependam ou importem arquivos de produtos de mercado.
* **❌ PROIBIDO**: `/packages/design_system/` importando arquivos de `/products/fincore-food/`. Os pacotes devem ser genéricos e agnósticos aos verticals.

### 3.3 Proibição de Dependência Circular (Cycle Block)
Se o pacote A importa o pacote B, o pacote B nunca pode importar arquivos do pacote A. Caso precise de lógica comum, ela deve ser extraída para um terceiro pacote (ex: `shared`).

---

*Monorepo Structure Guidelines — FINCORE Platform*
