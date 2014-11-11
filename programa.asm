; @autor Emerson Rocha Luiz <emerson at alligo.com.br>
; @desc  Programa funcional escrito em assembly, compatível com MASM 6.11+
;------------------------------------------------------------------------------
	; Declaração do modelo de segmentos
	.model		small
	
	; Declaração do segmento de pilha
	.stack

	; Declaração do segmento de dados
	.data

	; Variávies usadas internamentes nas funções
FileBuffer	db		10 dup (?)		    ; Declarar no segmento de dados
MAXSTRING	equ		200
String		db		MAXSTRING dup (?)	; Declarar no segmento de dados

	; Variáveis/constantes específicas deste programas
CR		equ		13
LF		equ		10

Autor		db		"Emerson Rocha Luiz - 143503",CR,LF,0
Cursor		db		"Comando>",CR,LF,0
DadosArquivo	db		"Arquivo de dados:",CR,LF,0
DadosResumo	db		"@todo resumo de dados",CR,LF,0
Ajuda		db		"Caracteres de comandos:",CR,LF," [a] Solicita novo arquivo de dados",CR,LF," [g] Apresenta o relatorio geral",CR,LF," [e] Apresenta o relatório do engenheiro",CR,LF," [f] Encerra programa",CR,LF," [?] lista comandos validos",CR,LF,0
;Ajuda		db		"Comandos: [?] [g] [e] [a] [f]",CR,LF,0
RelatorioGeral	db		"@todo relatorio geral",CR,LF,0
RelatorioEngN	db		"Engenheiro:",CR,LF,0
RelatorioEng	db		"@todo relatorio engenheiro",CR,LF,0
RelatorioErro	db		"Numero de engenheiro invalido",CR,LF,0
EncerramentoMsg	db		"Programa encerrado",CR,LF,0

	; Declaração do segmento de código
	.code

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

	.startup

	; TELA: Autoria
	lea		bx,Autor
	call	printf_s
	call	gets

	; TELA: Solicitação de arquivo de dados
	lea		bx,DadosArquivo
	call	printf_s
	call	gets

	; TELA: Resumo geral dos arquivo de dados (visualização prévia)
	lea		bx,DadosResumo
	call	printf_s
	call	gets

	; TELA: Tela de ajuda
	lea		bx,Ajuda
	call	printf_s
	call	gets

	; TELA: Resumo geral dos arquivo de dados (visualização sob demanda)
	lea		bx,RelatorioGeral
	call	printf_s
	call	gets

	; TELA: Engenheiro, solicitação da escolha
	lea		bx,RelatorioEngN
	call	printf_s
	call	gets

	; TELA: Engenheiro, exibição do relatório específico
	lea		bx,RelatorioEng
	call	printf_s
	call	gets

	; TELA: Engenheiro, erro de escolha de engenheiro inválido
	lea		bx,RelatorioErro
	call	printf_s
	call	gets

	; TELA: Engenheiro do programa
	lea		bx,EncerramentoMsg
	call	printf_s
	call	gets


	.exit


;------------------------------------------------------------------------------
	end
;------------------------------------------------------------------------------
