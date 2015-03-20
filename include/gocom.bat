@echo off
c:\dos\bp\bin\tasm /zi /l /c /m2 %1.asm
if errorlevel 1 goto ert
c:\dos\bp\bin\tlink /t /m /i /l /s /n %1.obj
REM tlink /v всегда выдает warning про ком файлы, убрал
if errorlevel 1 goto erl

	echo *********** Bingo! *************
	echo Launching %1.com with parameters: %2 %3 %4 %5 %6 %7 %8 %9
	echo.
	%1.com %2 %3 %4 %5 %6 %7 %8 %9
	echo.
	echo.
	echo Repeat?
	goto end
:ert
	echo *********** Compilation error :( **************
	goto end
:erl
	echo *********** Linking error :( **************
:end