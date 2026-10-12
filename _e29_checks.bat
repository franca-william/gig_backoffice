@echo off
REM E29 - analyze + testes do backoffice (Flutter Web)
cd /d %~dp0
call flutter pub get > _e29_pubget.txt 2>&1
call flutter analyze > _e29_analyze.txt 2>&1
call flutter test > _e29_test.txt 2>&1
echo Fim. Veja _e29_analyze.txt e _e29_test.txt
