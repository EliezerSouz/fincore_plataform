import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:yaml/yaml.dart';

class CustomMigrationRunner {
  static Future<void> run() async {
    print('🚀 [CustomMigrationRunner] Iniciando verificação de migrações customizadas...');
    try {
      // 1. Carregar configurações de ambiente e senhas
      final devConfigContent = await File('config/development.yaml').readAsString();
      final passwordsContent = await File('config/passwords.yaml').readAsString();
      
      final devConfig = loadYaml(devConfigContent) as YamlMap;
      final passwords = loadYaml(passwordsContent) as YamlMap;
      
      final dbConfig = devConfig['database'] as YamlMap?;
      if (dbConfig == null) {
        print('⚠️ [CustomMigrationRunner] Configuração de banco de dados não encontrada em development.yaml.');
        return;
      }
      
      final host = dbConfig['host'] as String;
      final port = dbConfig['port'] as int? ?? 5432;
      final database = dbConfig['name'] as String? ?? 'postgres';
      final username = dbConfig['user'] as String? ?? 'postgres';
      
      final devPasswords = passwords['development'] as YamlMap?;
      final password = devPasswords?['database'] as String?;
      
      if (password == null) {
        print('⚠️ [CustomMigrationRunner] Senha do banco de dados não encontrada em passwords.yaml.');
        return;
      }
      
      print('🚀 [CustomMigrationRunner] Conectando ao banco $host:$port...');
      final conn = await Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.require,
        ),
      );
      
      print('🚀 [CustomMigrationRunner] Banco conectado! Verificando tabela de controle...');
      
      // Criar tabela de controle se não existir
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS public._custom_applied_migrations (
          "id" SERIAL PRIMARY KEY,
          "name" TEXT UNIQUE NOT NULL,
          "appliedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
      ''');

      // Limpeza auto-regenerativa: remove o registro das migrações de estoque que falharam no meio
      await conn.execute("DELETE FROM public._custom_applied_migrations WHERE name = '20260816_estoque_financeiro.sql';");
      await conn.execute("DELETE FROM public._custom_applied_migrations WHERE name = '20260816_fix_estoque_rls.sql';");
      
      // Procurar arquivos .sql na pasta migrations
      final migrationDir = Directory('migrations');
      if (await migrationDir.exists()) {
        final List<FileSystemEntity> files = await migrationDir.list().toList();
        
        final sqlFiles = files
            .whereType<File>()
            .where((f) => f.path.endsWith('.sql'))
            .toList();
            
        sqlFiles.sort((a, b) => a.path.compareTo(b.path));
        
        for (final file in sqlFiles) {
          final fileName = file.path.split(Platform.pathSeparator).last;
          
          // Verificar se já foi aplicada
          final result = await conn.execute(
            'SELECT 1 FROM public._custom_applied_migrations WHERE "name" = \$1',
            parameters: [fileName],
          );
          
          if (result.isEmpty) {
            print('🚀 [CustomMigrationRunner] Aplicando migração: $fileName...');
             final sqlContent = await file.readAsString();
             final trimmedUpper = sqlContent.trim().toUpperCase();
             
             if (trimmedUpper.startsWith('DO \$\$') || trimmedUpper.startsWith('DO\$\$')) {
               await conn.execute(sqlContent);
             } else {
               final statements = sqlContent.split(';');
               for (var stmt in statements) {
                 final clean = stmt
                     .split('\n')
                     .where((l) => !l.trim().startsWith('--'))
                     .join('\n')
                     .trim();
                 if (clean.isNotEmpty) {
                   await conn.execute(clean);
                 }
               }
             }
            
            // Registrar como aplicada
            await conn.execute(
              'INSERT INTO public._custom_applied_migrations ("name") VALUES (\$1)',
              parameters: [fileName],
            );
            print('🚀 [CustomMigrationRunner] Migração $fileName aplicada com sucesso!');
          } else {
            print('🚀 [CustomMigrationRunner] Migração $fileName já aplicada anteriormente.');
          }
        }
      }
      
      await conn.close();
      print('🚀 [CustomMigrationRunner] Processo de migração concluído.');
    } catch (e, stack) {
      print('❌ [CustomMigrationRunner] Erro durante a execução das migrações: $e\n$stack');
    }
  }
}
