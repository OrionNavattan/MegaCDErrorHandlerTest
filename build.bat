@echo off

"asm68k.exe" /m /k /p "Sub CPU Program.asm", "Sub CPU Program.bin" >errors1.txt, "Sub CPU Program.sym", "Sub CPU Program.lst"
type errors1.txt

IF NOT EXIST "Sub CPU Program.bin" PAUSE & EXIT 2

"convsym.exe" "Sub CPU Program.sym" "Sub CPU Symbols.bin" -tolower

echo Compressing Sub CPU symbols.
"mdcomp/koscmp.exe"	"Sub CPU Symbols.bin" "Sub CPU Symbols.kos"

echo Compressing Sub CPU program.
"clownlzss.exe" -k -m=0x2000 "Sub CPU Program.bin" "Sub CPU Program.kosm"

IF NOT EXIST "Sub CPU Program.kosm" PAUSE & EXIT 2

"asm68k.exe" /m /k /p "MCD Error Handler Test.asm", "MCD Error Handler Test.bin" >errors2.txt, "MCD Error Handler Test.sym", "MCD Error Handler Test.lst"
type errors2.txt

"convsym.exe" "MCD Error Handler Test.sym" "Main CPU Symbols.bin" -tolower

echo Compressing and appending Main CPU symbols.
"mdcomp/koscmp.exe"	"Main CPU Symbols.bin" "Main CPU Symbols.kos"

rem Append compressed main CPU symbols to end of ROM.
copy /b "MCD Error Handler Test.bin"+ "Main CPU Symbols.kos" "MCD Error Handler Test.bin" /y

pause