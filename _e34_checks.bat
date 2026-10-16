@echo off
REM E34 - testes de marca GiG (app)
cd /d %~dp0
call flutter analyze > _e34_analyze.txt 2>&1
call flutter test > _e34_test.txt 2>&1
echo Fim. Veja _e34_analyze.txt e _e34_test.txt
