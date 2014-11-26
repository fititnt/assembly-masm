rem Script para MONTAR arquivos .ASM
rescan
masm /Zi programa.asm,programa.obj,programa.lst,programa.crf;
rem masm /Zi poc.asm,poc.obj,poc.lst,poc.crf;

rem Script para LIGAR um arquivo .OBJ
link /CO programa.obj,,,,;

