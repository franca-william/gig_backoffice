@echo off
REM E1 (backoffice) - pub get + analyze + testes do backoffice (Flutter Web)
cd /d %~dp0
call flutter pub get > _e1_pubget.txt 2>&1
call flutter analyze > _e1_analyze.txt 2>&1
call flutter test > _e1_test.txt 2>&1
echo FIM > _e1_fim.txt
echo Fim. Veja _e1_analyze.txt e _e1_test.txt
