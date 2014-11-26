; @autor    Emerson Rocha Luiz <emerson at alligo.com.br>
; @desc     Programa funcional escrito em assembly, compatível com MASM 6.11+
;           Versão 0.8.1
; @license  MIT
;------------------------------------------------------------------------------



	; Declaração do modelo de segmentos
	.model		small

	; Declaração do segmento de pilha
	.stack

	; Declaração do segmento de dados
	.data

	; Variávies usadas internamentes nas funções
FileBuffer	db	10 dup (?)       ; Buffer de leitura do arquivo
MAXSTRING	equ	200
String		db	MAXSTRING dup (?)
sw_n		dw	0
sw_f		db	0
sw_m		dw	0
FileName	db	256 dup (?)		; Nome do arquivo a ser lido
FileHandle	dw	0				; Handler do arquivo
FileNameBuffer	db	150 dup (?)

MsgPedeArquivo	db	CR,LF,">> Forneca o nome do arquivo de dados: ", 0
MsgErroOpenFile	db	"Erro na abertura do arquivo.",CR,LF,0
MsgErroReadFile	db	"Erro na leitura do arquivo.",CR,LF,0

DDebugStartEnd	db	CR,LF,"-- Debug --",CR,LF,0
DDebugReg1	db	"Registrador: ",0
DDebugString	db	CR,LF,"String: ",0
DDebugVal	db	MAXSTRING dup (?)
DDebugValMacro	db	MAXSTRING dup (?)

	; Variáveis/constantes específicas deste programas
CR		equ	13
LF		equ	10

Autor		db	"Emerson Rocha Luiz - 143503",0
Cursor		db	CR,LF,"Comando>",0
Crlf		db	CR,LF,0
Space1		db	" ",0
Space2		db	"  ",0
Space3		db	"  ",0
Space12		db	"            ",0
Virgulas	db	",00",0
DadosResumo1	db	CR,LF,"   Arquivo de dados:",CR,LF
		db	"      Numero de cidades...... ",0
DadosResumo2	db	CR,LF,"      Numero de engenheiros.. ",0
Ajuda		db	CR,LF,">> Caracteres de comandos:",CR,LF
		db	"   [a] Solicita novo arquivo de dados",CR,LF
		db	"   [g] Apresenta o relatorio geral",CR,LF
		db	"   [e] Apresenta o relatorio do engenheiro",CR,LF
		db	"   [f] Encerra programa",CR,LF
		db	"   [?] lista comandos validos",0
RelatorioGeral	db	CR,LF,">> Relatorio Geral"
		db	CR,LF,"    Engenheiro Visitas       Lucro       Prejuizo",CR,LF,0
RelatorioGeral2 db	"         ",0
RelatorioGeral3 db	CR,LF,0
RelatorioGeral4	db	"      TOTAL       ",0
RelatorioEngN	db	CR,LF,"Engenheiro:",0
RelatorioEng1	db	CR,LF,"    Relatorio do Engenheiro ",0
RelatorioEng2	db	CR,LF,"    Numero de visitas: ",0
RelatorioEng3	db	CR,LF,"    Cidade       Lucro     Prejuizo",CR,LF,0
RelatorioEng4	db	"      TOTAL     ",0
RelatorioEng5	db	"        ",0
RelatorioErro	db	CR,LF,"Numero de engenheiro invalido",0
EncerramentoMsg	db	CR,LF,"Programa encerrado",0

DtAtualInt	dw	0      ; Valor como inteiro do ultimo numero lido
DtAtualEngSel	dw	0      ; Engenheiro atualmente selecionado
DtAtualEhNeg	dw	0      ; Se o ultimo valor é negativo
DtAtualLucro	dw	0      ; Variavel temporaria para conter lucro de uma viagem
DtAtualString	db	7 dup (?) ; Valor concatenado da string atual
DtAtualStringC	dw	0         ; Numero de caracteres na string atual
;DtAtualChar	db	" ",0
DtAtualLinha	dw	0      ; Numero da linha no banco de dados
DtAtualColuna	dw	0      ; Numero do dado da linha atual
;DtAtualFim	dw	0      ; Flag 0 ou 1 para saber se ultima string terminou
DtNCidades	dw	0      ; Numero de cidades atendidas
DtNEng		dw	0      ; Numero de engenheiros
DtNVisitas	dw	0      ; Numero total de visitas
DtNLucro	dw	0      ; Lucro total de todos os engenheiros e Lucros
DtCidades	dw	999 dup (0)  ; Lucros de cada cidade
DtEngLucros	dw	999 dup (0)  ; Lista de lucros/prejuizos totais por engenheiro
DtEngVisitasPtr	dw	999 dup (0)  ; Lista de ponteiros para visitas de engs
DtEngVisitasT	dw	999 dup (0)  ; Apenas o total de visitas de cada engenheiro
DtEngVisitasNxt	dw	0      ; Ponteiro para o proximo end de DtEngVisitas
DtLoop		dw	0      ; Contador de loop generico
Xpto		dw	0
Temp		dw	0      ; Variavel temporaria generica
DtEngVisitas	dw	8096 dup (0) ; Local para conter todas as visitas de engs

	; Declaração do segmento de código
	.code

;--------------------------------------------------------------------
; Macros, usadas somente para debug
;--------------------------------------------------------------------

writechar MACRO char
	mov	ah, 2    ;; Select DOS Print Char function
	mov	dl, char ;; Select ASCII char
	int	21h      ;; Call DOS
ENDM

writenumber MACRO number
	mov	ax,number
	lea	bx,DDebugValMacro
	call	sprintf_w
	lea	bx,DDebugValMacro
	call	printf_s
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
	cmp	byte ptr[bx], 0
	jz	atoi_1

	; 	A = 10 * A
	mov	cx,10
	mul	cx

	; 	A = A + *S
	mov	ch,0
	mov	cl,[bx]
	add	ax,cx

	; 	A = A - '0'
	sub	ax,'0'

	; 	++S
	inc	bx
		
	;}
	jmp	atoi_2

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
	mov	al,0
	mov	ah,3dh
	int	21h
	mov	bx,ax
	ret
fopen	endp

;--------------------------------------------------------------------
;Função Cria o arquivo cujo nome está no string apontado por DX
;		boolean fcreate(char *FileName -> DX)
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fcreate	proc	near
	mov	cx,0
	mov	ah,3ch
	int	21h
	mov	bx,ax
	ret
fcreate	endp

;--------------------------------------------------------------------
;Entra:	BX -> file handle
;Sai:	CF -> "0" se OK
;--------------------------------------------------------------------
fclose	proc	near
	mov	ah,3eh
	int	21h
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
	mov	ah,3fh
	mov	cx,1
	lea	dx,FileBuffer
	int	21h
	mov	dl,FileBuffer
	ret
getChar	endp
	
;--------------------------------------------------------------------
;Entra: BX -> file handle
;       dl -> caractere
;Sai:   AX -> numero de caracteres escritos
;		CF -> "0" se escrita ok
;--------------------------------------------------------------------
setChar	proc	near
	mov	ah,40h
	mov	cx,1
	mov	FileBuffer,dl
	lea	dx,FileBuffer
	int	21h
	ret
setChar	endp

;
;--------------------------------------------------------------------
;Funcao Le um string do teclado e coloca no buffer apontado por BX
;		gets(char *s -> bx)
;--------------------------------------------------------------------
gets	proc	near
	push	bx

	mov	ah,0ah						; Lê uma linha do teclado
	lea	dx,String
	mov	byte ptr String, MAXSTRING-4	; 2 caracteres no inicio e um eventual CR LF no final
	int	21h

	lea	si,String+2					; Copia do buffer de teclado para o FileName
	pop	di
	mov	cl,String+1
	mov	ch,0
	mov	ax,ds						; Ajusta ES=DS para poder usar o MOVSB
	mov	es,ax
	rep 	movsb

	mov	byte ptr es:[di],0			; Coloca marca de fim de string
	ret
gets	endp

;--------------------------------------------------------------------
;Função Escrever um string na tela
;		printf_s(char *s -> BX)
;--------------------------------------------------------------------
printf_s	proc	near
	mov	dl,[bx]
	cmp	dl,0
	je	ps_1

	push	bx
	mov	ah,2
	int	21H
	pop	bx

	inc	bx
	jmp	printf_s

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

	push	dx
	push	cx
	push	bx
	push	ax

;	void sprintf_w(char *string, WORD n) {
	mov	sw_n,ax

;	k=5;
	mov	cx,5

;	m=10000;
	mov	sw_m,10000

;	f=0;
	mov	sw_f,0

;	do {
sw_do:

;	quociente = n / m : resto = n % m;	// Usar instrução DIV
	mov	dx,0
	mov	ax,sw_n
	div	sw_m

;	if (quociente || f) {
;		*string++ = quociente+'0'
;		f = 1;
;	}
	cmp	al,0
	jne	sw_store
	cmp	sw_f,0
	je	sw_continue
sw_store:
	add	al,'0'
	mov	[bx],al
	inc	bx

	mov	sw_f,1
sw_continue:

;		n = resto;
	mov	sw_n,dx

;		m = m/10;
	mov	dx,0
	mov	ax,sw_m
	mov	bp,10
	div	bp
	mov	sw_m,ax

;		--k;
	dec	cx

;	} while(k);
	cmp	cx,0
	jnz	sw_do

;	if (!f)
;		*string++ = '0';
	cmp	sw_f,0
	jnz	sw_continua2
	mov	[bx],'0'
	inc	bx
sw_continua2:


;	*string = '\0';
	mov	byte ptr[bx],0

;}

	pop	ax
	pop	bx
	pop	cx
	pop	dx

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
	lea	bx,MsgPedeArquivo
	call	printf_s

	;	// Lê uma linha do teclado
	;	FileNameBuffer[0]=100;
	;	gets(ah=0x0A, dx=&FileNameBuffer)
	mov	ah,0ah
	lea	dx,FileNameBuffer
	mov	byte ptr FileNameBuffer,100
	int	21h

	;	// Copia do buffer de teclado para o FileName
	;	for (char *s=FileNameBuffer+2, char *d=FileName, cx=FileNameBuffer[1]; cx!=0; s++,d++,cx--)
	;		*d = *s;
	lea	si,FileNameBuffer+2
	lea	di,FileName
	mov	cl,FileNameBuffer+1
	mov	ch,0
	mov	ax,ds ; Ajusta ES=DS para poder usar o MOVSB
	mov	es,ax
	rep 	movsb

	;	// Coloca o '\0' no final do string
	;	*d = '\0';
	mov	byte ptr es:[di],0
	ret
GetFileName	endp

;--------------------------------------------------------------------
;Função usada somente para debug
;--------------------------------------------------------------------
DDebug		proc	near
	lea	bx,DDebugStartEnd
	call	printf_s
	lea	bx,DDebugReg1
	call	printf_s
;;;;; Registrador
	; sprintf (String, "%d", 2943);
	;mov		ax,RegistradorAqui
	mov	ax,dx
	lea	bx,DDebugVal
	call	sprintf_w

	; printf("%s", String);
	lea	bx,DDebugVal
	call	printf_s

	lea	bx,DDebugStartEnd
	call	printf_s

	ret
DDebug	endp


;--------------------------------------------------------------------
; Função principal que recebe caracter por caracter os dados do arquivo
; do banco de dados, os analisa e tão logo esteja com informação suficiente
; salva nas estruturas de dados
;
; @see  DbAnalisaSalva   Quando um valor estiver concatenado para ser 
;                        analizado, é chamada para convertê-lo para
;                        valor numérico e salvar na estrutura de dados 
;
;Entra: DL             -> caracter atual do banco de dados, em HEX
;Sai:   DtAtualString  -> String concatenada (parcial ou completa)
;       DtAtualStringC -> Posição do próx. char em DtAtualString
;       DtAtualLinha   -> Linha do arquivo de banco de dados atual
;       DtAtualColuna  -> Coluna do valor na linha atual
;       DtAtualEhNeg   -> 1 se numero negavo, 0 se positivo
;       
;--------------------------------------------------------------------
DbAnalisa	proc	near
	;writechar dl

	; Testes básicos para saber qual é o tipo de caracter atual
	; conforme o caso, irá definir demais variáveis de acordo

	cmp	dl,2ch        ; if (dl = ,)
	je	DbAnalisaFimString
	cmp	dl,LF        ; if (dl = LF)
	je	DbAnalisaFimLinha
	cmp	dl,2dh        ; if (dl = -)
	je	DbAnalisaEhNegativo
	cmp	dl,CR        ; if (dl = CR || dl = " ")
	je	DbAnalisaIgnora
	cmp	dl,20h
	je	DbAnalisaIgnora

	jmp	DbAnalisaConcatena ; Se chegou ate aqui, é numero

DbAnalisaFimLinha:
	;call DDebug

	; Fecha string com \0
	mov	di, offset DtAtualString
	add 	di,DtAtualStringC
	mov	[di],0

	lea		bx,DtAtualString
	call 	DbStrToVal            ; DtAtualString & DtAtualEhNeg -> DtAtualInt
	call	DbAnalisaSalva

	mov	DtAtualStringC,0
	mov	DtAtualColuna,0
	inc	DtAtualLinha
	jmp	DbAnalisaIgnora
DbAnalisaFimString:

	; Fecha string com \0
	mov	di, offset DtAtualString
	add 	di,DtAtualStringC
	mov	[di],0

	lea	bx,DtAtualString
	call 	DbStrToVal            ; DtAtualString & DtAtualEhNeg -> DtAtualInt

	call	DbAnalisaSalva
	mov	DtAtualStringC,0
	inc	DtAtualColuna
	jmp	DbAnalisaIgnora

DbAnalisaEhNegativo:
	mov	DtAtualEhNeg,1
	jmp	DbAnalisaIgnora

DbAnalisaConcatena:
	mov	di, offset DtAtualString
	add 	di,DtAtualStringC
	mov	[di],dl
	inc	DtAtualStringC

DbAnalisaIgnora:
	ret
DbAnalisa	endp

;--------------------------------------------------------------------
; Chamada por DbAnalisa, analiza os dados pré-processados e os converte
; para estrutura de dados
; 
; @see  atoi             Usada para converter de string para numerico
;
;Entra: DtAtualInt     -> valor numérico do dado atual
;       DtAtualString  -> String concatenada
;       DtAtualLinha   -> Linha do arquivo de banco de dados atual
;       DtAtualColuna  -> Coluna do valor na linha atual
;       DtAtualEhNeg   -> 1 se numero negavo, 0 se positivo
;Sai:   DtNCidades     -> Número de cidades
;       DtNEng         -> Número de engenheiros
;       ...
;
;--------------------------------------------------------------------
DbAnalisaSalva	proc	near

	cmp	DtAtualLinha,0
	je	DbAnalisaSalvaLinha0
	cmp	DtAtualLinha,1
	je	DbAnalisaSalvaLinha1
	jmp	DbAnalisaSalvaLinha2p

; Primeira linha: sumário (DtNEng e DtNCidades)
;----------------------------------------------
DbAnalisaSalvaLinha0:

	cmp	DtAtualColuna,1
	je	DbAnalisaSalvaLinha01

	; Número total de engenheiros
	mov	ax,DtAtualInt
	mov	DtNEng,ax
	jmp	DbAnalisaSalvaFim

DbAnalisaSalvaLinha01:

	; Número total de cidades
	mov	ax,DtAtualInt
	mov	DtNCidades,ax
	jmp	DbAnalisaSalvaFim

; Segunda linha: lucro de cidades (DtCidades)
;----------------------------------------------
DbAnalisaSalvaLinha1:

	; Lucro de visita a cidade de indice 'DtAtualColuna'
	lea	bx,DtCidades
	mov	dx,DtAtualColuna
	shl	dx,1               ; Col*2, deslocamento conforme coluna
	add	bx,dx
	mov	ax,DtAtualInt
	mov	[bx],ax            ; Move valor atual para memoria DtCidades+DtAtualColuna

	jmp	DbAnalisaSalvaFim

; Terceira linha adiante: visitas de engenheiros a cidades
;----------------------------------------------
DbAnalisaSalvaLinha2p:

	; Caso não seja primeira coluna, passar adiante (n requer setar DtEngVisitasNxt)
	cmp	DtAtualColuna,0
	jne	DbAnalisaSalvaLinha2p1p

	; Se DtEngVisitasNxt ja foi iniciado, passar adiante
	cmp	DtEngVisitasNxt,0
	jne	DbAnalisaSalvaLinha2p0

	lea	bx,DtEngVisitas
	mov	DtEngVisitasNxt,bx ; Inicializa DtEngVisitasNxt primeira vez

;DtEngVisitasNxt ja esta iniciado, é primeira coluna, só definir DtEngVisitasT e DtEngVisitasPtr
    DbAnalisaSalvaLinha2p0:

	; Popula Total de visitas em DtEngVisitasT
	lea	bx,DtEngVisitasT
	mov	dx,DtAtualLinha
	shl	dx,1 ; L*2
	add	bx,dx
	sub	bx,4 ; L - 2 (linhas)
	mov	ax,DtAtualInt
	mov	[bx],ax

	; Total de visitas
	lea	bx,DtNVisitas
	mov	ax,DtAtualInt
	add	[bx],ax

	; Popula ponteiro DtEngVisitasPtr para inicio das viagens de DtEngVisitas (usa DtEngVisitasNxt)
	lea	ax,DtEngVisitasNxt
	mov	dx,DtAtualLinha
	shl	dx,1 ; L*2
	add	ax,dx
	sub	ax,2 ; L - 2(linhas) + 1 (proxima posição), AX contém pos inicial das viagens
	lea	bx,DtEngVisitasPtr
	mov	dx,DtAtualLinha
	shl	dx,1 ; L*2
	add	bx,dx
	sub	bx,4 ; L - 2 (linhas)
	mov	[bx],ax

	jmp	DbAnalisaSalvaFim

; Terceira linha ou maior, coluna apenas com locais visitados
    DbAnalisaSalvaLinha2p1p:

	mov	bx,DtEngVisitasNxt
	mov	ax,DtAtualInt
	mov	[bx],ax  ; Salva local visitado no local apontado

	; Obtem lucro da visital atual
	lea	bx,DtCidades
	mov	dx,DtAtualInt
	shl	dx,1     ; L*2, deslocamento DW de 2 bytes
	add	bx,dx
	mov	ax,[bx]
	lea	bx,DtAtualLucro
	mov	[bx],ax

	; Obtem lucro total de visitas DtNLucro
	lea	bx,DtNLucro
	mov	ax,DtAtualLucro
	add	[bx],ax

	; Faz total de lucro por engenheiro no array DtEngLucros
	lea	bx,DtEngLucros
	mov	dx,DtAtualLinha
	sub	dx,2
	shl	dx,1 ; L*2
	add	bx,dx
	mov	ax,DtAtualLucro
	add	[bx],ax

	add	DtEngVisitasNxt,2  ; Preparar para proxima posição de DtEngVisitas
	jmp	DbAnalisaSalvaFim

DbAnalisaSalvaFim:
	mov bx,0
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
	mov	DtAtualEhNeg,0           ; Reseta flag
	mov	DtAtualInt,ax
	ret

DbStrToVal	endp

;--------------------------------------------------------------------
;Função para receber um numeral e imprimir com padding na tela e ,00
;
;Entra: AX -> Numero inteiro
;
;--------------------------------------------------------------------
DbPrintN	proc	near

	mov	Temp,ax
	cmp	ax,0
	jl	DbPrintNNegativo

	lea	bx,Space3
	call	printf_s
	lea	bx,String
	mov	ax,Temp
	call	sprintf_w
	lea	bx,String
	call	printf_s
	lea	bx,Virgulas
	call	printf_s
	jmp	DbPrintNFim

DbPrintNNegativo:
	mov	ax,Temp
	neg	ax
	mov	Temp,ax
	lea	bx,Space12
	call	printf_s
	lea	bx,String
	mov	ax,Temp
	call	sprintf_w
	lea	bx,String
	call	printf_s
	lea	bx,Virgulas
	call	printf_s

DbPrintNFim:
	ret

DbPrintN	endp

	.startup

TelaAutoria:
	lea	bx,Autor
	call	printf_s
	call	gets

TelaArquivoDados:
	; TELA: Solicitação de arquivo de dados
	; Necessario resetar
	mov	DtAtualInt,0
	mov	DtAtualEngSel,0
	mov	DtAtualEhNeg,0
	mov	DtAtualLucro,0
	mov	DtAtualStringC,0
	mov	DtAtualLinha,0
	mov	DtAtualColuna,0
	mov	DtNCidades,0
	mov	DtNEng,0
	mov	DtNVisitas,0
	mov	DtNLucro,0
	mov	DtEngVisitasNxt,0
	mov	DtLoop,0
	mov	Xpto,0

	jmp	SubrotinaLeArquivo
	call	gets

TelaResumoGeral:
	; TELA: Resumo geral dos arquivo de dados (visualização prévia)
	lea	bx,DadosResumo1
	call	printf_s

	mov	ax,DtNCidades
	lea	bx,String
	call	sprintf_w
	lea	bx,String
	call	printf_s

	lea	bx,DadosResumo2
	call	printf_s

	mov	ax,DtNEng
	lea	bx,String
	call	sprintf_w
	lea	bx,String
	call	printf_s
	;call	DDebubPilha

	;call	gets

TelaAjuda:
	; TELA: Tela de ajuda
	lea	bx,Ajuda
	call	printf_s
	call	SubrotinaNavegacao

TelaResumoGeralSobDemanda:
	; TELA: Resumo geral dos arquivo de dados (visualização sob demanda)
	call	SubrotinaRelatorioGeral

TelaEngEscolha:
	; TELA: Engenheiro, solicitação da escolha
	lea	bx,RelatorioEngN
	call	printf_s
	lea	bx,String
	call	gets                ; String obtida em bx
	call	atoi                ; Converte string de bx para inteiro em ax
	mov	DtAtualEngSel,ax
	cmp	ax,DtNEng
	jge	TelaEngErro         ; Selecionado Eng superior a qtd de engs
	;call	SubrotinaNavegacao

TelaEngRelatorio:
	; TELA: Engenheiro, exibição do relatório específico
	; "Relatorio do Engenheiro N \0"
	lea	bx,RelatorioEng1
	call	printf_s
	mov	ax,DtAtualEngSel
	lea	bx,String
	call	sprintf_w
	lea	bx,String
	call	printf_s

	; "Numero de visitas:  N \0"
	lea	bx,RelatorioEng2
	call	printf_s

	;@todo Implementar na tela de engenheiro a exibição de lucros/prejuízos (fititnt, 2014-11-26 15h56min)
	; lea	bx,DtEngVisitasPtr
	; add	bx,DtAtualEngSel
	; mov	ax,[bx]
	;mov	bx,Xpto
	lea	bx,DtEngVisitasT
	mov	dx,DtAtualEngSel
	shl	dx,1 ; * 2, deslocamento dw
	add	bx,dx
	mov	ax,[bx]
	;mov bx,Xpto
	;mov	ax,bx

	lea	bx,String
	call	sprintf_w
	lea	bx,String
	call	printf_s

	;"Cidade       Lucro     Prejuizo"
	lea	bx,RelatorioEng3
	call	printf_s

	; contador de visitas
	lea	bx,DtEngVisitasT
	mov	dx,DtAtualEngSel
	shl	dx,1 ; * 2, deslocamento dw
	add	bx,dx
	mov	ax,[bx]
	mov	cx,ax
	;dec	cx

; Item por item
     TelaEngRelatorioItens:

	; Espacos
	lea	bx,RelatorioEng5
	call	printf_s

	; Nº Cidade
	mov	bx,DtEngVisitasPtr
	mov	dx,cx
	shl	dx,1             ; pos*2, DW usa 2 bytes de deslocamento
	add	bx,dx
	mov	ax,[bx]
	lea	bx,String
	call	sprintf_w
	lea	bx,String
	call	printf_s

	; Fim de linha
	lea	bx,Crlf
	call	printf_s

	dec	cx
	cmp	cx,0
	jge	TelaEngRelatorioItens

TelaEngRelatorioFim:
	; "TOTAL:  "
	lea	bx,RelatorioEng4
	call	printf_s

	; NNN,NN    NNN,NN (lucro/prejuizo)
	mov	ax,DtNLucro
	call	DbPrintN

	; lea	bx,Crlf
	; call	printf_s
	call	SubrotinaNavegacao

TelaEngErro:
	; TELA: Engenheiro, erro de escolha de engenheiro inválido
	lea	bx,RelatorioErro
	call	printf_s

	call	SubrotinaNavegacao

TelaEncerramento:
	; TELA: Encerramento do programa
	lea	bx,EncerramentoMsg
	call	printf_s
	lea	bx,Cursor
	call	printf_s
	jmp	Encerramento

; Subrotina de navegação. Gerencia input do usuário e navegação em telas
;----------------------------------------------
SubrotinaNavegacao:
	lea	bx,Cursor
	call	printf_s

	mov	ah,1	; Prepara para obter tecla digitada em al
	int	21h
	cmp	al,'a'
	je	TelaArquivoDados
	cmp	al,'g'
	je	TelaResumoGeralSobDemanda
	cmp	al,'e'
	je	TelaEngEscolha
	cmp	al,'a'
	je	TelaArquivoDados
	cmp	al,'f'
	je	TelaEncerramento
	cmp	al,'?'
	je	TelaAjuda
	jmp	SubrotinaNavegacao

; Subrotina usada na tela Relatorio Geral
;----------------------------------------------
SubrotinaRelatorioGeral:
	; TELA: Resumo geral dos arquivo de dados (visualização sob demanda)
	lea	bx,RelatorioGeral
	call	printf_s
	mov	cx,0

; Loop para gerar linha por linha
    SubrotinaRelatorioGeralLinha:
	; Espacos
	lea	bx,RelatorioGeral2
	call	printf_s

	; Eng nº
	mov	ax,cx
	lea	bx,String
	call	sprintf_w
	lea	bx,String
	call	printf_s

	; Espaços
	lea	bx,RelatorioGeral2
	call	printf_s

	; Nº visitas
	lea	bx,DtEngVisitasT
	mov	dx,cx
	shl	dx,1             ; pos*2, DW usa 2 bytes de deslocamento
	add	bx,dx
	mov	ax,[bx]
	lea	bx,String
	call	sprintf_w
	lea	bx,String
	call	printf_s

	; Espaços
	lea	bx,RelatorioGeral2
	call	printf_s

	; Lucro/Prejuizo
	lea	bx,DtEngLucros
	mov	dx,cx
	shl	dx,1             ; pos*2, DW usa 2 bytes de deslocamento
	add	bx,dx
	mov	ax,[bx]
	call	DbPrintN

	; Fim de linha
	lea	bx,RelatorioGeral3
	call	printf_s

	inc	cx
	cmp	cx,DtNEng
	je	SubrotinaRelatorioGeralTotal

	jmp	SubrotinaRelatorioGeralLinha

; Fim da tabela (exibe totais)
    SubrotinaRelatorioGeralTotal:
	; "TOTAL"
	lea	bx,RelatorioGeral4
	call	printf_s

	; "N (visitas)
	mov	ax,DtNVisitas
	lea	bx,String
	call	sprintf_w
	lea	bx,String
	call	printf_s

	; "    "
	lea	bx,RelatorioGeral2
	call	printf_s

	; NNN,NN    NNN,NN (lucro/prejuizo)
	mov	ax,DtNLucro
	call	DbPrintN

; Fim da subrotina
    SubrotinaRelatorioGeralFim:
	call	SubrotinaNavegacao

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

	;if ( (ax=fopen(ah=0x3d, dx->FileName) ) ) {
	;	printf("Erro na abertura do arquivo.\r\n");
	;exit(1);
	;}
	mov	al,0
	lea	dx,FileName
	mov	ah,3dh
	int	21h
	jnc	Continua1
	
	lea	bx,MsgErroOpenFile
	call	printf_s
	
	.exit	1
	
Continua1:

	;	FileHandle = ax
	mov	FileHandle,ax		; Salva handle do arquivo

	;	while(1) {
Again:
	;	if ( (ax=fread(ah=0x3f, bx=FileHandle, cx=1, dx=FileBuffer)) ) {
	;		printf ("Erro na leitura do arquivo.\r\n");
	;		fclose(bx=FileHandle)
	;		exit(1);
	;	}
	mov	bx,FileHandle
	mov	ah,3fh
	mov	cx,1
	lea	dx,FileBuffer
	int	21h
	jnc	Continua2
	
	lea	bx,MsgErroReadFile
	call	printf_s
	
	mov	al,1
	jmp	CloseAndFinal

Continua2:
	;	if (ax==0) {
	;		fclose(bx=FileHandle);
	;		exit(0);
	;	}
	cmp	ax,0
	jne	Continua3

	mov	al,0
	jmp	CloseAndFinal

Continua3:
	;	printf("%c", FileBuffer[0]);	// Coloca um caractere na tela
	;mov	ah,2
	mov	dl,FileBuffer
	;int	21h

	call	DbAnalisa ; Chama DbAnalisa caracter por caracter

	;	}
	jmp	Again

CloseAndFinal:
	mov	bx,FileHandle		; Fecha o arquivo
	mov	ah,3eh
	int	21h

Final:
	jmp	TelaResumoGeral

Encerramento:
	.exit


;------------------------------------------------------------------------------
	end
;------------------------------------------------------------------------------
