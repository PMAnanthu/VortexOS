org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

start:
	jmp main

;
;	print a string in to the screen
;	Params:
;		-	ds:si prints to string 
puts:
	;	save registers
	push si
	push ax

.loop:
	lodsb		;	load next char in al
	or al, al 	;	verify if next is present 
	jz .done

	mov ah, 0x0e	;	call bios intrupt for print char
	mov bh, 0
	int 0x10

	jmp .loop

.done:
	pop ax
	pop si
	ret


main:
	; setup data segment
	mov ax, 0   							; cant write data to es directly
	mov ds, ax
	mov es, ax

	; setup stack
	mov ss, ax
	mov sp, 0x7C00 							; stack grows downwards 

	;	print message
	mov si, msg
	call puts

	hlt

.halt:
	jmp .halt

msg: db 'VortexOS', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h