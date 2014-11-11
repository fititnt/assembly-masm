rem Script para MONTAR arquivos .ASM
rescan
masm /Zi programa.asm,programa.obj,programa.lst,programa.crf;

rem Script para LIGAR um arquivo .OBJ
link /CO programa.obj,,,,;

programa.exe