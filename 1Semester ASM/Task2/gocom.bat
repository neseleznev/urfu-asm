@echo off
c:\dos\bp\bin\tasm /zi /l /c /m2 %1.asm
if errorlevel 1 goto ert
c:\dos\bp\bin\tlink /t /v /m /i /l /s /n %1.obj 
if errorlevel 1 goto erl
	echo *********** Bingo! *************
	echo Launching %1.exe with parameters '%2'
	echo.
	%1.com %2
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