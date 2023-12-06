@echo off

"asm68k.exe" /m /k /p "Sub CPU Program.asm", "Sub CPU Program.bin" >errors1.txt, "Sub CPU Program.sym", "Sub CPU Program.lst"
type errors1.txt

IF NOT EXIST "Sub CPU Program.bin" PAUSE & EXIT 2

echo Compressing Sub CPU program.
"clownlzss.exe" -k -m=0x2000 "Sub CPU Program.bin" "Sub CPU Program.kosm"

IF NOT EXIST "Sub CPU Program.kosm" PAUSE & EXIT 2

"asm68k.exe" /m /k /p "MCD Error Handler Test.asm", "MCD Error Handler Test.bin" >errors2.txt, "MCD Error Handler Test.sym", "MCD Error Handler Test.lst"
type errors2.txt

pause