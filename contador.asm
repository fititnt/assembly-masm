
;
;====================================================================
;	- Colocar na tela do computador uma contagem de 1 até 20.
;		Cada número deve ser colocado em uma linha
;	- O contador, que deverá estar em memória, deve ter largura 
;		de 16 bits e estar representado em binário
;	- O contador deverá ser convertido de binário para ASCII de 
;		maneira a ser colocado na tela
;	- Usar as funções HexToDecAscii e a WriteString
;====================================================================
;
		.model small
		.stack

		.data
Contador		dw	0
BufferWRWORD	DB	10 DUP(?)	; Para uso dentro de WriteWord

		.code
		.startup

		mov		ax,0			; Zera contador
		mov		Contador,ax

Again:
		mov		ax,Contador		; Apresenta o conteúdo de Contador na tela
		call	WriteWord

		mov		ah,2			; Envia CRLF
		mov		dl,13
		int		21H
		mov		ah,2
		mov		dl,10
		int		21H

		inc		Contador		; Incrementa contador e verifica se chegou ao final
		cmp		Contador,21
		jnz		Again
		
		.exit


;
;--------------------------------------------------------------------
;Função: Escreve o valor de AX na tela
;--------------------------------------------------------------------
WriteWord	proc	near
		lea		bx,BufferWRWORD
		call	HexToDecAscii
		
		lea		bx,BufferWRWORD
		call	WriteString
		
		ret
WriteWord	endp


;
;--------------------------------------------------------------------
;Função:Escrever um string na tela
;Entra: DS:BX -> Ponteiro para o string
;--------------------------------------------------------------------
WriteString	proc	near

WS_2:
		mov		dl,[bx]		; While (*S!='\0') {
		cmp		dl,0
		jnz		WS_1
		ret

WS_1:
		mov		ah,2		; 	Int21(2)
		int		21H

		inc		bx			; 	++S
		jmp		WS_2		; }

WriteString	endp


;
;--------------------------------------------------------------------
;Função: Converte um valor HEXA para ASCII-DECIMAL
;Entra:  (A) -> AX -> Valor "Hex" a ser convertido
;        (S) -> DS:BX -> Ponteiro para o string de destino
;--------------------------------------------------------------------
HexToDecAscii	proc near

		mov	cx,0			;N = 0;
H2DA_2:
		or	ax,ax			;while (A!=0) {
		jnz	H2DA_0
		or	cx,cx
		jnz	H2DA_1

H2DA_0:
		mov	dx,0			;A = A / 10
		mov	si,10			;dl = A % 10 + '0'
		div	si
		add	dl,'0'

		mov	si,cx			;S[N] = dl
		mov	[bx+si],dl

		inc	cx				;++N
		jmp	H2DA_2

H2DA_1:
		mov	si,cx			;S[N] = '\0'
		mov	byte ptr[bx+si],0

		mov	si,bx			;i = 0

		add	bx,cx			;j = N-1
		dec	bx

		sar	cx,1			;N = N / 2

H2DA_4:
		or	cx,cx			;while (N!=0) {
		jz	H2DA_3


		mov	al,[si]			;S[i] <-> S[j]
		mov	ah,[bx]
		mov	[si],ah
		mov	[bx],al

		dec	cx				;	--N

		inc	si				;	++i

		dec	bx				;	--j
		jmp	H2DA_4

H2DA_3:
		ret

HexToDecAscii	endp

		
;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------
	