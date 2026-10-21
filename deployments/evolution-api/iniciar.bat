@echo off
echo Iniciando Evolution API (PostgreSQL + Redis + API)...
docker compose up -d
echo.
echo Status dos containers:
docker compose ps
echo.
echo Servico disponivel em: http://localhost:8080
pause
