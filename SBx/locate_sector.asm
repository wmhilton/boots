; Pass the UID in EAX
; Pass the sequence number in EBX
; If successful, AX == 0 and SI points to the start of the data in memory
; If unsuccessful, AX > 0 and SI points to the start of the string "Not found"
use16
SBx_locate_sector:
.start:
  mov [.arg_uid+5], al
  mov [.arg_uid+4], ah
  shr eax, 16
  mov [.arg_uid+3], al
  mov [.arg_uid+2], ah
  mov [.arg_uid+1], 0
  mov [.arg_uid], 0
  mov [.arg_n+3], bl
  mov [.arg_n+2], bh
  shr ebx, 16
  mov [.arg_n+1], bl
  mov [.arg_n], bh
  mov [.sector], 1
  mov [.track], 0
  mov [.side], 0
  
  mov si, .print_intro
  call print_string
  rept 6 i:0 {
    mov al, [.arg_uid + i]
    call print_al
  }
  mov si, .print_intro2
  call print_string
  rept 4 i:6 {
    mov al, [.arg_uid + i]
    call print_al
  }
  mov si, .print_nl
  call print_string
  
  xor ax, ax
  mov ds, ax
  mov es, ax
  mov ss, ax

.loop:
  ; Loop through sectors, looking for a match
  mov bx, .sector_in_memory
  mov ch, [.track]
  mov cl, [.sector]             ; track 0, sector 2
  mov dh, [.side]                    ; side 0
  mov dl, 0
  mov ah, 2h
  mov al, 1h     ; length (1 sector)
  call .read
  jnc @f
  ; If an error occured (the carry flag is set) we'll just
  ; assume its a "you've gone too far" error and proceed to the next track
  mov [.sector], 1
  mov [.side], 0
  add [.track], 1
  cmp [.track], 80
  je .not_found
  jmp .loop
@@:
  ; Print current block data
  mov si, .print_cr
  call print_string
  mov si, .print_track
  call print_string
  mov ah, [.track]
  call print_ah
  mov si, .print_sector
  call print_string
  mov al, [.sector]
  call print_al
  mov si, .print_side
  call print_string
  mov al, [.side]
  call print_al
  mov si, .print_space
  call print_string
  
  ; cmp [.sector], 12
  ; je .not_found
  ; increment side
  add [.side], 1
  cmp [.side], 2
  jne @f
  mov [.side], 0
  ; increment sector
  inc [.sector]
  mov al, [.sector]
@@:
  ; print first 3 blocks
  mov al, [.sbx_signature]
  call print_al
  mov al, [.sbx_signature + 1]
  call print_al
  mov al, [.sbx_signature + 2]
  call print_al
  
  ; detect SBx blocks
  mov di, .expected_signature
  mov si, .sbx_signature
  mov cx, 3
  repe cmpsb
  jne .loop
  
  mov si, .print_detected_sb
  call print_string
  
  ; Print uid and seq number
  rept 6 i:0 {
    mov al, [.sbx_file_uid + i]
    call print_al
  }
  mov si, .print_space
  call print_string
  rept 4 i:6 {
    mov al, [.sbx_file_uid + i]
    call print_al
  }
  mov si, .print_nl
  call print_string
  
  ; Compare uid and seq number
  mov si, .arg_uid
  mov di, .sbx_file_uid
  mov cx, 10
  repe cmpsb
  jne .loop
  
  ; It's a match!
  mov si, .sbx_block_data
  mov ax, 1
  ret
.read:
  mov bp, 2                     ; 3 tries
@@:
  push ax
  int 13h
  jnc @f
  sub bp, 1
  jc @f
  xor ax, ax
  int 13h
  pop ax
  jmp @b
@@:
  pop bp
  ret
.not_found:
  mov si, .print_not_found
  call print_string
  mov si, .print_not_found
  ret
.locals:
  .arg_uid db 6 dup 0
  .arg_n db 4 dup 0
  .track db 0
  .sector db 0
  .side db 0
.sector_in_memory:
  .sbx_signature db 3 dup 0
  .sbx_version db 1 dup 0
  .sbx_crc16 db 2 dup 0
  .sbx_file_uid db 6 dup 0
  .sbx_block_sequence_number db 4 dup 0
  .sbx_block_data db 496 dup 0
db 0 ; null terminator for data
  .expected_signature db 53h, 42h, 78h, 01h  ; SBx (version 1)
  .print_track db 'track: ', 0
  .print_sector db ', sector: ', 0
  .print_side db ', side: ', 0
  .print_nl db 13, 10, 0
  .print_cr db 13, 0
  .print_space db ' ', 0
  .print_intro db 'Searching for SBx block uuid=', 0
  .print_intro2 db ' sequence_number=', 0
  .print_not_found db 'Not found', 13, 10, 0
  .print_detected_sb db ' <- SBx ', 0
  .print_match db 'Match!', 13, 10, 0
include 'util/cstrings.asm'
