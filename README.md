# Salgaderia Desktop

MVP de gestão de pedidos para Windows feito em Flutter, Drift/SQLite, MVVM e Repository Pattern.

## Executar

```powershell
flutter config --enable-windows-desktop
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows
```

## Gerar o .exe

```powershell
flutter build windows --release
```

Saída: `build/windows/x64/runner/Release/` (distribua a pasta inteira).

## Impressão

A aplicação gera comandos ESC/POS e os envia como RAW à fila compartilhada configurada no Windows. Cadastre a impressora no Windows, compartilhe-a e informe em Configurações o caminho como `localhost/NOME_COMPARTILHAMENTO`. Em modo de desenvolvimento, se não houver impressora configurada, a comanda é salva em `%TEMP%/salgaderia_ultimo_pedido.bin`.

## Estrutura

- `database`: tabelas Drift e conexão SQLite
- `repositories`: contratos e persistência
- `services`: regras de pedidos e impressão
- `providers`: ViewModels (MVVM)
- `pages`: interface desktop responsiva
- `core`: tema e utilitários

## Decisões importantes

- Valores monetários são persistidos em centavos, evitando erros de ponto flutuante.
- Itens guardam nome e preço no momento da venda, preservando o histórico.
- Exclusão de produto/cliente é lógica (`ativo`), protegendo pedidos antigos.
- O número sequencial é reservado dentro de transação SQLite.
