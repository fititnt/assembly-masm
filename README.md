# Programa funcional escrito em assembly (MASM 6.11) - Versão 0.8.1

![Demonstração](https://raw.githubusercontent.com/fititnt/assembly-masm/master/demonstracao.png)

Para descrição longa, leia doc/TrabalhoIntel.revD.pdf

## Obter repositório e compilar executável

### Obter e instalar dependências
1. `git clone https://github.com/fititnt/assembly-masm.git .`
2. `sudo apt-get install dosbox` (Ubuntu 12.04+)

Nota 1: o repositório já contém MASM611 instalado. Para ser executado no Windows
como host, leia doc/InstallDosBox.pdf

Nota 2: para instalar o MASM 6.11 deste o início em Ubuntu, leia
doc/install-doxbox-ubuntu.md

### Iniciar DosBox

1. `dosbox .` (Já monta C: na pasta atual)
2. INIT.BAT`

### Compilar e excecutar

1. `Makefile.bat`
1. `programa.exe`

