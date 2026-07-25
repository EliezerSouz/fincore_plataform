# Princípios do Produto (Product Principles)

> **Document ID**: PRD-002  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Nenhum código deve ser escrito antes da leitura deste documento. Nenhuma funcionalidade deve ser implementada sem que atenda a pelo menos um princípio.

---

## Operação

| # | Princípio | Teste de Validação |
|---|---|---|
| 1 | **Toda tela responde apenas uma pergunta.** | Se a tela exige que o usuário decida entre duas ações diferentes, ela está errada. |
| 2 | **Toda funcionalidade deve economizar tempo.** | Se o operador demora mais com o sistema do que sem ele, ela não deve existir. |
| 3 | **Toda automação deve reduzir erros.** | Se a automação introduz complexidade que gera novos erros, ela é pior que o manual. |
| 4 | **Nenhuma configuração pode impedir a operação.** | O sistema deve funcionar com 100% das configurações em estado padrão. Configurar é opcional. |
| 5 | **O operador nunca deve precisar decorar processos.** | Se precisa de treinamento para saber o próximo passo, o fluxo está errado. |
| 6 | **Nenhum fluxo deve exigir treinamento superior a 30 minutos.** | Se um perfil precisa de mais de 30 minutos para operar sua função, o UX falhou. |

## Arquitetura

| # | Princípio | Teste de Validação |
|---|---|---|
| 7 | **Offline sempre vence Cloud.** | Se o operador não consegue vender, produzir ou separar porque caiu a internet, o sistema falhou. |
| 8 | **Toda informação importante deve existir em no máximo 3 interações.** | Se são necessários mais de 3 cliques/toques para acessar uma informação crítica, o caminho está longo demais. |
| 9 | **O ERP cresce conforme a empresa cresce.** | Funcionalidades que a empresa não usa não devem existir na interface. Feature flags, não menus vazios. |

## Inteligência

| # | Princípio | Teste de Validação |
|---|---|---|
| 10 | **Toda IA deve sugerir, nunca decidir.** | Nenhuma ação automatizada pode alterar dados sem confirmação humana. IA propõe, operador dispõe. |
| 11 | **Toda decisão deve responder: "Isso melhora a operação?"** | Se não melhora a operação do dia a dia, é feature de vanidade. Não entra. |

## Produto

| # | Princípio | Teste de Validação |
|---|---|---|
| 12 | **Nenhuma decisão técnica deve ser visível para o operador.** | O operador não precisa saber o que é SQLite, Serverpod, sync ou tenant. Ele precisa vender. |

---

## Regra de Sobrevivência

> Toda decisão de produto, arquitetura, design ou código deve responder positivamente:
>
> ***"Isso sobrevive em um produto vendido para 500 empresas?"***
>
> Se a resposta for não, a decisão está errada.

---

*Este documento é a lei do produto. Tudo o mais — arquitetura, roadmap, backlog, código — existe para servir estes princípios.*
