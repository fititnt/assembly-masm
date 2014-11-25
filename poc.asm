
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
DtCidades	dw		0,1,2,3,4,5,6,7,8,9  ; Lucros de cada cidade
DtCidadesPtr	dw		10 dup (0)
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
	; Inserido dados no array
	; lea	bx,DtCidades
	; add	bx,Counter
	; mov	ax,Counter
	; mov	[bx],ax

	; inc	Counter
	; mov 	ax,Counter
	; cmp	ax,11
	; jne	lb1

	; Inserido dados no array
	mov 	cl,0
	mov	ch,0
lb2:
	lea	bx,DtCidadesPtr
	add	bx,cx
	lea	ax,DtCidades
	add	ax,cx
	mov	[bx],ax

	inc	cl
	cmp	cl,10
	jne	lb2

	; Exibido resultado do array
	mov 	cl,0
	mov	ch,0
	mov	ax,DtCidadesPtr

lb3:
	add	ax,cx
	mov	bx, ax
	; print
	;mov	dl,cl
	mov	dl,byte ptr[bx]
	add	dl,49
	mov ah, 2
	int 21h

	inc	cx
	cmp	cx,10
	jne	lb3
	
	.exit


;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------


	




