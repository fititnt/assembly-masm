
;
;====================================================================
;	- Fonte base para a escrita de programa para o 8086
;	- Utiliza o modelo small
;====================================================================
;

	; Declaração do modelo de segmentos
	.model		small
	
	; Declaração do segmento de pilha
	.stack

	; Declaração do segmento de dados
	.data
DtCidades	dw		10 dup (0)  ; Lucros de cada cidade
Counter		dw		0;

	; Declaração do segmento de código
	.code

writechar MACRO char
	mov ah, 2    ;; Select DOS Print Char function
	mov dl, char ;; Select ASCII char
	int 21h      ;; Call DOS
ENDM

writeint MACRO number
	mov ah, 2    ;; Select DOS Print Char function
	mov dl, number
	add dl,49
	int 21h      ;; Call DOS
ENDM
	.startup
	
lb1:
	lea	bx,DtCidades
	add	bx,Counter
	mov	ax,Counter
	mov	[bx],ax

	
	; print
	mov	dl,byte ptr Counter
	add	dl,49
	mov ah, 2
	int 21h
	

	inc	Counter
	mov 	ax,Counter
	cmp	ax,11
	jne	lb1
	
	
	
	
	.exit


;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------


	




