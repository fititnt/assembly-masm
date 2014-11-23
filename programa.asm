; @autor Emerson Rocha Luiz <emerson at alligo.com.br>
; @desc  Programa funcional escrito em assembly, compatível com MASM 6.11+
;------------------------------------------------------------------------------



	; Declaração do modelo de segmentos
	.model		small
INCLUDE /MASM611/INCLUDE/BIOS.INC
	; Declaração do segmento de pilha
	.stack

	; Declaração do segmento de dados
	.data

	; Variávies usadas internamentes nas funções
FileBuffer	db		10 dup (?)       ; Buffer de leitura do arquivo
MAXSTRING	equ		200
String		db		MAXSTRING dup (?)
sw_n		dw		0
sw_f		db		0
sw_m		dw		0
FileName	db		256 dup (?)		; Nome do arquivo a ser lido
;FileBuffer	db		10 dup (?)		; Buffer de leitura do arquivo
FileHandle	dw		0				; Handler do arquivo
FileNameBuffer	db		150 dup (?)

MsgPedeArquivo	db		"Nome do arquivo: ", 0
MsgErroOpenFile	db		"Erro na abertura do arquivo.",CR,LF,0
MsgErroReadFile	db		"Erro na leitura do arquivo.",CR,LF,0

DDebugStartEnd	db		CR,LF,"-- Debug --",CR,LF,0
DDebugReg1	db		"Registrador: ",0
DDebugString	db		CR,LF,"String: ",0
DDebugVal	db		MAXSTRING dup (?)

	; Variáveis/constantes específicas deste programas
CR		equ		13
LF		equ		10

Autor		db		"Emerson Rocha Luiz - 143503",CR,LF,0
Cursor		db		CR,LF,"Comando>",0
DadosArquivo	db		CR,LF,"Arquivo de dados:",0
;DadosResumo	db		"@todo resumo de dados",CR,LF,0
DadosResumo1	db		CR,LF,"  Arquivo de dados:",CR,LF
		db		"      Numero de cidades...... ",0
DadosResumo2	db		CR,LF,"      Numero de engenheiros.. ",0
Ajuda		db		CR,LF,"Caracteres de comandos:",CR,LF
		db		" [a] Solicita novo arquivo de dados",CR,LF
		db		" [g] Apresenta o relatorio geral",CR,LF
		db		" [e] Apresenta o relatório do engenheiro",CR,LF
		db		" [f] Encerra programa",CR,LF
		db		" [?] lista comandos validos",CR,LF,0
;RelatorioGeral	db		"@todo relatorio geral",CR,LF,0
RelatorioGeral	db		256 dup (?)
RelatorioEngN	db		CR,LF,"Engenheiro:",0
RelatorioEng	db		CR,LF,"@todo relatorio engenheiro",0
RelatorioErro	db		CR,LF,"Numero de engenheiro invalido",0
EncerramentoMsg	db		CR,LF,"Programa encerrado",0

DtAtualInt	dw		7      ; Valor como inteiro do ultimo numero lido
DtAtualEhNeg	dw		0      ; Se o ultimo valor é negativo
DtAtualString	db		"    ",0 ; Valor como string do ultimo numero lido
DtAtualChar	db		" ",0
DtAtualLinha	dw		0      ; Numero da linha no banco de dados
DtAtualLinhaVal	dw		0      ; Numero do dado da linha atual
DtAtualFim	dw		0      ; Flag 0 ou 1 para saber se ultima string terminou
DtNCidades	dw		77      ; Numero de cidades atendidas
DtNEng		dw		77      ; Numero de engenheiros

	; Declaração do segmento de código
	.code

;--------------------------------------------------------------------
; Macros, usadas somente para debug
;--------------------------------------------------------------------
beep MACRO
	mov ah, 2 ;; Select DOS Print Char function
	mov dl, 7 ;; Select ASCII 7 (bell)
	int 21h ;; Call DOS
ENDM

writechar MACRO char
	mov ah, 2    ;; Select DOS Print Char function
	mov dl, char ;; Select ASCII char
	int 21h      ;; Call DOS
ENDM
;
;--------------------------------------------------------------------
;Função:Converte um ASCII-DECIMAL para HEXA
;Entra: (S) -> DS:BX -> Ponteiro para o string de origem
;Sai:	(A) -> AX -> Valor "Hex" resultante
;Algoritmo:
;	A = 0;
;	while (*S!='\0') {
;		A = 10 * A + (*S - '0')
;		++S;
;	}
;	return
;--------------------------------------------------------------------
atoi	proc near

		; A = 0;
		mov		ax,0
		
atoi_2:
		; while (*S!='\0') {
		cmp		byte ptr[bx], 0
		jz		atoi_1

		; 	A = 10 * A
		mov		cx,10
		mul		cx

		; 	A = A + *S
		mov		ch,0
		mov		cl,[bx]
		add		ax,cx

		; 	A = A - '0'
		sub		ax,'0'

		; 	++S
		inc		bx
		
		;}
		jmp		atoi_2

atoi_1:
		; return
		ret

atoi	endp
;--------------------------------------------------------------------
;Função	Abre o arquivo cujo nome está no string apontado por DX
;		boolean fopen(char *FileName -> DX)
;Entra: DX -> ponteiro para o string com o nome do arquivo
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fopen	proc	near
	mov		al,0
	mov		ah,3dh
	int		21h
	mov		bx,ax
	ret
fopen	endp

;--------------------------------------------------------------------
;Função Cria o arquivo cujo nome está no string apontado por DX
;		boolean fcreate(char *FileName -> DX)
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fcreate	proc	near
	mov		cx,0
	mov		ah,3ch
	int		21h
	mov		bx,ax
	ret
fcreate	endp

;--------------------------------------------------------------------
;Entra:	BX -> file handle
;Sai:	CF -> "0" se OK
;--------------------------------------------------------------------
fclose	proc	near
	mov		ah,3eh
	int		21h
	ret
fclose	endp

;--------------------------------------------------------------------
;Função	Le um caractere do arquivo identificado pelo HANLDE BX
;		getChar(handle->BX)
;Entra: BX -> file handle
;Sai:   dl -> caractere
;		AX -> numero de caracteres lidos
;		CF -> "0" se leitura ok
;--------------------------------------------------------------------
;FileBuffer	db		10 dup (?)		; Declarar no segmento de dados
getChar	proc	near
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
	mov		dl,FileBuffer
	ret
getChar	endp
	
;--------------------------------------------------------------------
;Entra: BX -> file handle
;       dl -> caractere
;Sai:   AX -> numero de caracteres escritos
;		CF -> "0" se escrita ok
;--------------------------------------------------------------------
;FileBuffer	db		10 dup (?)		; Declarar no segmento de dados
setChar	proc	near
	mov		ah,40h
	mov		cx,1
	mov		FileBuffer,dl
	lea		dx,FileBuffer
	int		21h
	ret
setChar	endp

;
;--------------------------------------------------------------------
;Funcao Le um string do teclado e coloca no buffer apontado por BX
;		gets(char *s -> bx)
;--------------------------------------------------------------------
;MAXSTRING	equ		200
;String		db		MAXSTRING dup (?)	; Declarar no segmento de dados
gets	proc	near
	push	bx

	mov		ah,0ah						; Lê uma linha do teclado
	lea		dx,String
	mov		byte ptr String, MAXSTRING-4	; 2 caracteres no inicio e um eventual CR LF no final
	int		21h

	lea		si,String+2					; Copia do buffer de teclado para o FileName
	pop		di
	mov		cl,String+1
	mov		ch,0
	mov		ax,ds						; Ajusta ES=DS para poder usar o MOVSB
	mov		es,ax
	rep 	movsb

	mov		byte ptr es:[di],0			; Coloca marca de fim de string
	ret
gets	endp

;--------------------------------------------------------------------
;Função Escrever um string na tela
;		printf_s(char *s -> BX)
;--------------------------------------------------------------------
printf_s	proc	near
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

	push	bx
	mov		ah,2
	int		21H
	pop		bx

	inc		bx
	jmp		printf_s

ps_1:
	ret
printf_s	endp

;--------------------------------------------------------------------
;Função: Converte um inteiro (n) para (string)
;		 sprintf(string, "%d", n)
;
;void sprintf_w(char *string->BX, WORD n->AX) {
;	k=5;
;	m=10000;
;	f=0;
;	do {
;		quociente = n / m : resto = n % m;	// Usar instrução DIV
;		if (quociente || f) {
;			*string++ = quociente+'0'
;			f = 1;
;		}
;		n = resto;
;		m = m/10;
;		--k;
;	} while(k);
;
;	if (!f)
;		*string++ = '0';
;	*string = '\0';
;}
;
;Associação de variaveis com registradores e memória
;	string	-> bx
;	k		-> cx
;	m		-> sw_m dw
;	f		-> sw_f db
;	n		-> sw_n	dw
;--------------------------------------------------------------------

sprintf_w	proc	near

;void sprintf_w(char *string, WORD n) {
	mov		sw_n,ax

;	k=5;
	mov		cx,5

;	m=10000;
	mov		sw_m,10000

;	f=0;
	mov		sw_f,0

;	do {
sw_do:

;		quociente = n / m : resto = n % m;	// Usar instrução DIV
	mov		dx,0
	mov		ax,sw_n
	div		sw_m

;		if (quociente || f) {
;			*string++ = quociente+'0'
;			f = 1;
;		}
	cmp		al,0
	jne		sw_store
	cmp		sw_f,0
	je		sw_continue
sw_store:
	add		al,'0'
	mov		[bx],al
	inc		bx

	mov		sw_f,1
sw_continue:

;		n = resto;
	mov		sw_n,dx

;		m = m/10;
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax

;		--k;
	dec		cx

;	} while(k);
	cmp		cx,0
	jnz		sw_do

;	if (!f)
;		*string++ = '0';
	cmp		sw_f,0
	jnz		sw_continua2
	mov		[bx],'0'
	inc		bx
sw_continua2:


;	*string = '\0';
	mov		byte ptr[bx],0

;}
	ret

sprintf_w	endp

;
;--------------------------------------------------------------------
;Funcao: Le o nome do arquivo do teclado
;void GetFileName(void)
;{
;	printf_s("Nome do arquivo: ");
;
;	// Lê uma linha do teclado
;	FileNameBuffer[0]=100;
;	gets(ah=0x0A, dx=&FileNameBuffer)
;
;	// Copia do buffer de teclado para o FileName
;	for (char *s=FileNameBuffer+2, char *d=FileName, cx=FileNameBuffer[1]; cx!=0; s++,d++,cx--)
;		*d = *s;
;
;	// Coloca o '\0' no final do string
;	*d = '\0';
;}
;--------------------------------------------------------------------
GetFileName	proc	near

	;	printf_s("Nome do arquivo: ");
	lea		bx,MsgPedeArquivo
	call	printf_s

	;	// Lê uma linha do teclado
	;	FileNameBuffer[0]=100;
	;	gets(ah=0x0A, dx=&FileNameBuffer)
	mov		ah,0ah
	lea		dx,FileNameBuffer
	mov		byte ptr FileNameBuffer,100
	int		21h

	;	// Copia do buffer de teclado para o FileName
	;	for (char *s=FileNameBuffer+2, char *d=FileName, cx=FileNameBuffer[1]; cx!=0; s++,d++,cx--)
	;		*d = *s;
	lea		si,FileNameBuffer+2
	lea		di,FileName
	mov		cl,FileNameBuffer+1
	mov		ch,0
	mov		ax,ds ; Ajusta ES=DS para poder usar o MOVSB
	mov		es,ax
	rep 	movsb

	;	// Coloca o '\0' no final do string
	;	*d = '\0';
	mov		byte ptr es:[di],0
	ret
GetFileName	endp

;--------------------------------------------------------------------
;Função usada somente para debug
;--------------------------------------------------------------------
DDebug		proc	near
	lea		bx,DDebugStartEnd
	call	printf_s
	lea		bx,DDebugReg1
	call	printf_s
;;;;; Registrador
	; sprintf (String, "%d", 2943);
	;mov		ax,RegistradorAqui
	mov		ax,dx
	lea		bx,DDebugVal
	call	sprintf_w

	; printf("%s", String);
	lea		bx,DDebugVal
	call	printf_s

	lea		bx,DDebugStartEnd
	call	printf_s

	ret
DDebug	endp

;--------------------------------------------------------------------
;Função usada somente para debug
; @see http://support.microsoft.com/kb/85068/en-us
;--------------------------------------------------------------------
DDebubPilha		proc	near
          ;mov ax, 0FFFFh     ; Load AX with something distinctive.

          push dx            ; Save all registers that are used.
          push cx
          push bx
          push ax

          mov dx, 4          ; Loop will print out 4 hex characters.
nexthex:
          mov cl, 4          ; Rotate register 4 bits.
          rol ax, cl
          push ax            ; Save current value in AX.
          rol ax, cl
          push ax            ; Save current value in AX.

          and al, 0Fh        ; Mask off all but 4 lowest bits.
          cmp al, 10         ; Check to see if digit is 0-9.
          jl decimal         ; Digit is 0-9.
          add al, 7          ; Add 7 for Digits A-F.
decimal:
          add al, 30h        ; Add 30h to get ASCII character.

          mov bx, 0003h      ; BH= Page 0, BL= Foreground Color.
          mov ah, 0Eh        ; Prepare for interrupt.
          int 10h            ; Do BIOS call to print out value.
	  ;int 21h            ; Do MS-DOS call to print out value.

          pop ax             ; Restore value to AX.
          dec dx             ; Decrement loop counter.
          jnz nexthex        ; Loop back if there is another character
                             ; to print.

          pop ax             ; Restore all registers that were used.
          pop bx
          pop cx
          pop dx
          ret
DDebubPilha ENDP

;--------------------------------------------------------------------
;Função	Analisa um caracter por vez do banco de dados fornecido
;	e gerencia a definição da base de dados em memória
;
;Entra: DL -> caracter atual, em HEX
;Sai:   DtAtualString -> String concatenada
;--------------------------------------------------------------------
DbAnalisa	proc	near

	;call 	DDebug

	cmp		dl,2ch        ; if (dl = ,)
	je		DbAnalisaFimString
	cmp		dl,LF        ; if (dl = LF)
	je		DbAnalisaFimLinha
	cmp		dl,2dh        ; if (dl = -)
	je		DbAnalisaEhNegativo
	cmp		dl,CR        ; if (dl = CR || dl = " ")
	je		DbAnalisaIgnora
	cmp		dl,20h
	je		DbAnalisaIgnora

	jmp		DbAnalisaConcatena ; Se chegou ate aqui, é numero

DbAnalisaFimLinha:
	;mov		DtAtualLinhaVal,-1 ;

	inc		DtAtualLinha
DbAnalisaFimString:
	inc		DtAtualLinhaVal
	mov		DtAtualFim,1
	mov		bh,0
	;call		DbStrToVal

	;mov		bx, offset DtAtualString   ; @debug, apagar
	;call 		printf_s                   ; @debug, apagar

	call	DbAnalisaSalva

	jmp		DbAnalisaIgnora

DbAnalisaEhNegativo:
	mov		DtAtualEhNeg,1

	jmp		DbAnalisaIgnora

DbAnalisaConcatena:
; @todo concatenar numero atual ao ultimo valor lido
	mov		di, offset DtAtualString
	mov 		di, dx
	;mov 		DtAtualString+bh, dx
	inc		bh ; Contador do caracter atual na string

DbAnalisaIgnora:
	ret
DbAnalisa	endp

;--------------------------------------------------------------------
; Função que, tão logo um numeral tenha sido lido do banco de dados
; o salva na estrutura de dados correspondente
;--------------------------------------------------------------------
DbAnalisaSalva	proc	near

	cmp	DtAtualLinha,0
	je	DbAnalisaSalvaLinha0
	cmp	DtAtualLinha,1
	je	DbAnalisaSalvaLinha1
	jmp	DbAnalisaSalvaLinha2p

DbAnalisaSalvaLinha0:

	cmp	DtAtualLinhaVal,1
	je	DbAnalisaSalvaLinha01
	mov	ax,DtAtualInt
	mov	DtNEng,ax          ; Copia ultimo numero calculado
	jmp	DbAnalisaSalvaFim

DbAnalisaSalvaLinha01:

	mov	byte ptr DtAtualChar,dl
	lea	bx, DtAtualChar
	call	DbStrToVal

	mov	ax,DtAtualInt
	mov	DtNCidades,ax      ; Copia ultimo numero calculado
	jmp	DbAnalisaSalvaFim
DbAnalisaSalvaLinha1:

	jmp	DbAnalisaSalvaFim
DbAnalisaSalvaLinha2p:

DbAnalisaSalvaFim:

	;call DDebug
	ret
DbAnalisaSalva	endp

;--------------------------------------------------------------------
;Função	Para uma string fornecida em DtAtualString, a converte para
;       valor numérico em DtAtualInt
;
;Entra: (S) -> DS:BX -> Ponteiro para o string de origem
;Sai:	(A) -> AX -> Valor "Hex" resultante
;
;Entra: DtAtualString -> caracter atual
;Sai:   DtAtualInt -> String concatenada
;--------------------------------------------------------------------
DbStrToVal	proc	near

	call	atoi

	cmp	DtAtualEhNeg,1 ; Se flag negativo esta ligada, negativar
	jne	DbStrToValFim
	neg	ax

DbStrToValFim:
	mov	DtAtualFim,0             ; Reseta flag
	mov	DtAtualEhNeg,0           ; Reseta flag
	mov	DtAtualInt,ax
	ret
DbStrToVal	endp

	.startup

TelaAutoria:
	; TELA: Autoria
	;writechar 'e'
	;writechar dl
	lea		bx,Autor
	call	printf_s
	call	gets

TelaArquivoDados:
        
	; TELA: Solicitação de arquivo de dados
	;lea		bx,DadosArquivo
	;call	printf_s
	jmp		SubrotinaLeArquivo
	call	gets

TelaResumoGeral:
	; TELA: Resumo geral dos arquivo de dados (visualização prévia)
	lea		bx,DadosResumo1
	call	printf_s

	mov		ax,DtNEng
	lea		bx,String
	call	sprintf_w
	lea		bx,String
	call	printf_s

	lea		bx,DadosResumo2
	call	printf_s

	mov		ax,DtNCidades
	lea		bx,String
	call	sprintf_w
	lea		bx,String
	call	printf_s

	;call	DDebubPilha

	call	gets

TelaAjuda:
	; TELA: Tela de ajuda
	lea		bx,Ajuda
	call	printf_s
	call	gets

TelaResumoGeralSobDemanda:
	; TELA: Resumo geral dos arquivo de dados (visualização sob demanda)
	lea		bx,RelatorioGeral
	call	printf_s
	call	gets

TelaEngEscolha:
	; TELA: Engenheiro, solicitação da escolha
	lea		bx,RelatorioEngN
	call	printf_s
	call	gets

TelaEngRelatorio:
	; TELA: Engenheiro, exibição do relatório específico
	lea		bx,RelatorioEng
	call	printf_s
	call	gets

TelaEngErro:
	; TELA: Engenheiro, erro de escolha de engenheiro inválido
	lea		bx,RelatorioErro
	call	printf_s
	call	gets

TelaEncerramento:
	; TELA: Encerramento do programa
	lea		bx,EncerramentoMsg
	call	printf_s
	call	gets
	jmp		Encerramento

SubrotinaLeArquivo:
;====================================================================
;void main(void)
;{
;	GetFileName();
;
;	if ( (ax=fopen(ah=0x3d, dx->FileName) ) ) {
;		printf("Erro na abertura do arquivo.\r\n");
;		exit(1);
;	}
;	FileHandle = ax
;
;	while(1) {
;		if ( (ax=fread(ah=0x3f, bx=FileHandle, cx=1, dx=FileBuffer)) ) {
;			printf ("Erro na leitura do arquivo.\r\n");
;			fclose(bx=FileHandle)
;			exit(1);
;		}
;		if (ax==0) {
;			fclose(bx=FileHandle);
;			exit(0);
;		}
;
;		printf("%c", FileBuffer[0]);	// Coloca um caractere na tela
;	}
;}
;
;====================================================================
		
	;	GetFileName();
	call	GetFileName

	;	if ( (ax=fopen(ah=0x3d, dx->FileName) ) ) {
	;		printf("Erro na abertura do arquivo.\r\n");
	;		exit(1);
	;	}
	mov		al,0
	lea		dx,FileName
	mov		ah,3dh
	int		21h
	jnc		Continua1
	
	lea		bx,MsgErroOpenFile
	call	printf_s
	
	.exit	1
	
Continua1:

	;	FileHandle = ax
	mov		FileHandle,ax		; Salva handle do arquivo

	;	while(1) {
Again:
	;		if ( (ax=fread(ah=0x3f, bx=FileHandle, cx=1, dx=FileBuffer)) ) {
	;			printf ("Erro na leitura do arquivo.\r\n");
	;			fclose(bx=FileHandle)
	;			exit(1);
	;		}
	mov		bx,FileHandle
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
	jnc		Continua2
	
	lea		bx,MsgErroReadFile
	call	printf_s
	
	mov		al,1
	jmp		CloseAndFinal

Continua2:
	;		if (ax==0) {
	;			fclose(bx=FileHandle);
	;			exit(0);
	;		}
	cmp		ax,0
	jne		Continua3

	mov		al,0
	jmp		CloseAndFinal

Continua3:
	;		printf("%c", FileBuffer[0]);	// Coloca um caractere na tela
	mov		ah,2
	mov		dl,FileBuffer
	int		21h

	;call		DDebug
	call		DbAnalisa ; Chama analize

	;	}
	jmp		Again

CloseAndFinal:
	mov		bx,FileHandle		; Fecha o arquivo
	mov		ah,3eh
	int		21h

Final:
	jmp		TelaResumoGeral

Encerramento:
	.exit


;------------------------------------------------------------------------------
	end
;------------------------------------------------------------------------------
