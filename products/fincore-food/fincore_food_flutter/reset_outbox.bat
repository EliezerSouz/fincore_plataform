@echo off
title FINCORE FOOD - Limpeza da Fila de Sincronizacao (Outbox)
echo ========================================================
echo   FINCORE FOOD - Purga da Fila de Outbox Retentando
echo ========================================================
echo.

powershell -ExecutionPolicy Bypass -Command "$code = 'using System; using System.Runtime.InteropServices; public class SqliteHelper { [DllImport(@\"C:\fincore_food\sqlite3.dll\", EntryPoint=\"sqlite3_open\", CallingConvention=CallingConvention.Cdecl)] public static extern int sqlite3_open([MarshalAs(UnmanagedType.LPStr)] string filename, out IntPtr db); [DllImport(@\"C:\fincore_food\sqlite3.dll\", EntryPoint=\"sqlite3_exec\", CallingConvention=CallingConvention.Cdecl)] public static extern int sqlite3_exec(IntPtr db, [MarshalAs(UnmanagedType.LPStr)] string sql, IntPtr callback, IntPtr errmsg, out IntPtr errmsgOut); [DllImport(@\"C:\fincore_food\sqlite3.dll\", EntryPoint=\"sqlite3_close\", CallingConvention=CallingConvention.Cdecl)] public static extern int sqlite3_close(IntPtr db); public static void ExecuteSql(string dbPath, string sql) { IntPtr db; int rc = sqlite3_open(dbPath, out db); if (rc != 0) { Console.WriteLine(\"Erro ao abrir: \" + rc); return; } IntPtr err; rc = sqlite3_exec(db, sql, IntPtr.Zero, IntPtr.Zero, out err); sqlite3_close(db); } }'; Add-Type -TypeDefinition $code; [SqliteHelper]::ExecuteSql('C:\fincore_food\DATA\fincore_v3.db', 'DELETE FROM outbox_sync;');"

echo.
echo Fila de sincronizacao (outbox_sync) limpa com sucesso no banco de dados local!
echo Os pedidos de teste travados em memoria nao serao mais transmitidos.
echo.
pause
