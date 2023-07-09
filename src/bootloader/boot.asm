org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

; 
; FAT12 header
; 
jmp short start
nop

bdb_oem:                    db "MSWIN4.1"           ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  db 0F0h                 ; F0 = 3.5" floppy disk
bdb_sectors_per_fat:        dw 9                    ; 9 sectors/fat
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hdd, useless
                            db 0                    ; reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 38h, 56h, 78h   ; serial number, value doesn't matter
ebr_volume_label:           db 'VortexOS  '           ; 11 bytes, padded with spaces
ebr_system_id:              db 'FAT12   '           ; 8 bytes


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
	; 	setup data segment
	mov ax, 0   							; cant write data to es directly
	mov ds, ax
	mov es, ax

	; 	setup stack
	mov ss, ax
	mov sp, 0x7C00 							; stack grows downwards 

	;	read data from disk
	mov [ebr_drive_number], dl

	mov ax, 1
	mov cl, 1
	mov bx, 0x7E00
	call disk_read


	;	print message
	mov si, msg
	call puts

	call end

read_error:
	mov si, read_error_message
	call puts
	jmp wait_for_key_and_reboot

wait_for_key_and_reboot:
	mov ah, 0
	int 16h
	jmp 0FFFFh:0

.halt:
	call end

;
;	End process
;
end:
	cli
	hlt

;
;	Disk
;

;
;	convert and LB address CHS address
;	Params;
;		- ax: LBA address
;	Return
;		- cx [bits 0-5]: sector number
;		- cx [bits 6-15]: cylinder number 
;		- dh: head
;
lba_to_chs:
	push ax
	push dx

	xor dx, dx								;	dx reset
	div word [bdb_sectors_per_track]		;	ax = LBA/ Sectors per Track
											;	dx = LBA % Sector per track
	inc dx									; 	dx =dx+1
	mov cx, dx								; 	cx = sector

	xor dx,dx								;	reset dx
	div word [bdb_heads]					; 	ax = LBA/ secotor per track / heads = cylinder
											;	dx = LBA/ sector per track % heads = head
	mov dh,	dl								; 	dl = head
	mov ch, al
	shl ah, 6
	or cl, ah								

	pop ax
	mov dl, al								;	reset dl
	pop ax
	ret


;
;	Read sector from disk
;	Params:
;		- ax: LBA address
;		- cl: number of sector to read
;		- dl: drive number
;		- es:bs: memory address where to store read data
;
disk_read:
	push ax
	push bx
	push cx
	push dx
	push di

	push cx									;	move to stack
	call lba_to_chs							; 	read disk location
	pop ax									; 	take ax value
	
	mov ah, 02h
	mov di, 3

.retry:
	pusha
	stc 
	int 13h
	jnc .done

	popa
	call disk_reset

	dec di
	test di, di
	jnz .retry

.fail:
	; all attempts completed 
	jmp read_error

.done:
	popa

	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

;
;	Reset the disk
;	Params:
;		- dl: dive number
disk_reset:
	pusha
	mov ah, 0
	stc
	int 13h
	jc read_error
	popa
	ret


msg: 					db 'VortexOS', ENDL, 0
read_error_message:		db 'Disk read failed!!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h