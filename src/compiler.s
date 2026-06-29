default rel 

section .data
  outname db "bfc-out.s", 0
  loop_count dq 0
  stack_ptr dq 0

  header db "default rel", 10, 10, \
            "section .bss", 10, \
            " memory resb 30000", 10, 10, \
            "section .text", 10, \
            " global _start", 10, 10, \
            "_start: ", 10, \
            " lea r12, [memory]", 10, 0

  header_len equ $ - header - 1
  
  footer db " mov rax, 60 ; sys_exit", 10, \
            " xor rdi, rdi", 10, \
            " syscall", 10, 0 
  
  footer_len equ $ - footer - 1 
  
  cursor_right_template db  " ; '>'", 10, \
                            " add r12, ", 0

  cursor_right_template_len equ $ - cursor_right_template - 1 

  cursor_left_template db " ; '<'", 10, \
                          " sub r12, ", 0

  cursor_left_template_len equ $ - cursor_left_template - 1

  add_cell_template db  " ; '+'", 10, \
                        " add byte [r12], ", 0

  add_cell_template_len equ $ - add_cell_template - 1

  sub_cell_template db " ; '-'", 10, \
                       " sub byte [r12], ", 0

  sub_cell_template_len equ $ - sub_cell_template - 1 

  print_cell_asm db " ; '.'", 10, \
                    " mov rax, 1 ; sys_write", 10, \
                    " mov rdi, 1 ; stdout", 10, \
                    " mov rsi, r12 ; cell", 10, \
                    " mov rdx, 1", 10, \
                    " syscall", 10, 10, 0

  print_cell_len equ $ - print_cell_asm - 1

  read_byte_asm db  " ; ','", 10, \
                    " mov rax, 0 ; sys_read", 10, \
                    " mov rdi, 0 ; stdin", 10, \
                    " mov rsi, r12", 10, \
                    " mov rdx, 1", 10, \
                    " syscall", 10, 10, 0 

  read_byte_len equ $ - read_byte_asm - 1

  loop_start_template db  " ; '['", 10, \
                          " loop_start_", 0 
  loop_start_template_len equ $ - loop_start_template - 1 

  loop_start_center db ":", 10, \
                       "  cmp byte [r12], 0", 10, \
                       "  jz loop_end_", 0
  
  loop_start_center_len equ $ - loop_start_center - 1

  loop_end_header db  " ; ']'", 10, \
                        " cmp byte [r12], 0", 10, \
                        " jne loop_start_", 0
  
  loop_end_header_len equ $ - loop_end_header - 1

  loop_end_template db 10, 10, " loop_end_", 0
  loop_end_template_len equ $ - loop_end_template - 1

  clear_cell_template db  " ; '[-]' / '[+]'", 10, \
                          " mov byte [r12], 0", 10, 10, 0

  clear_cell_template_len equ $ - clear_cell_template - 1

section .bss 
  passedfd resd 1 
  outfd resd 1 
  
  compiled_buf resb 4096 
  bytes_to_write resq 1

  bytes_to_compile resq 1 
  
  tmp resb 1 

  stack resq 100

  utoa_buf resb 4096

section .text 
  global compile_file 

  extern chunk
  extern read_chunk
  extern create_file

utoa: ; rdi = number | rax = bytes_converted 
  push rbx
  push r12
  
  xor r12, r12 ; counter 
  mov rax, rdi 
  mov rcx, 10 

  .loop:
    cmp rax, 0 
    je .end 

    xor rdx, rdx ; clear for rdx:rax division
    div rcx ; rax /= 10 -> rdx = remainder 
    
    inc r12 
    ; utoa_buf[4096 - r12] = rdx 
    lea rbx, [utoa_buf + 4096]
    sub rbx, r12 
    
    add dl, '0'
    mov [rbx], dl 

    jmp .loop

  .end:
    mov rax, r12

    pop r12 
    pop rbx 

    ret 

compile_file: ; rdi = fd | rax = 0/1 success code 
  push rbp 
  mov rbp, rsp
  
  mov [passedfd], edi 

  mov rdi, outname
  call create_file

  cmp rax, 0
  jge .store_fd  
  
  jmp .handle_error

  .store_fd:
    mov [outfd], eax 

  mov rax, 1 
  mov rdi, [outfd]
  mov rsi, header 
  mov rdx, header_len

  syscall

  .compile_loop:
    mov rdi, [passedfd]
    call read_chunk

    test rax, rax 

    js .handle_error 
    jz .handle_eof
    
    mov rdi, rax 

    call compile_chunk
    
    jmp .compile_loop

  .handle_eof: 
    mov r12, 1 
    jmp .end 

  .handle_error:
    mov r12, 0 
    jmp .end 

  .end:
    mov rax, 3
    mov rdi, [passedfd] 
    syscall 

    cmp [outfd], 0
    jl .skip

    mov rax, 1 
    mov rdi, [outfd]
    mov rsi, compiled_buf
    mov rdx, [bytes_to_write]

    syscall

    mov rax, 1 
    mov rdi, [outfd]
    mov rsi, footer
    mov rdx, footer_len

    syscall
    
    mov rax, 3 
    mov rdi, [outfd]
    syscall 

    .skip:
    mov rax, r12
    
    mov rsp, rbp 
    pop rbp 

    ret 
  
compile_chunk: ; rdi = bytes to read 
  xor r10, r10 ; index 
  mov [bytes_to_compile], rdi 
  
  .loop:
    cmp [bytes_to_compile], r10 
    je .chunk_end
    
    mov cl, [chunk + r10]
    mov [tmp], cl 
    
    cmp cl, '>'
    je .cursor_right

    cmp cl, '<'
    je .cursor_left

    cmp cl, '+'
    je .add_cell

    cmp cl, '-'
    je .sub_cell

    cmp cl, '.'
    je .print_cell

    cmp cl, ','
    je .read_cell

    cmp cl, '['
    je .loop_start

    cmp cl, ']'
    je .loop_end

    jmp .continue

  .cursor_right:
    xor rbx, rbx 
    
    .count_right:
      cmp r10, [bytes_to_compile]
      jge .right_done 

      cmp byte [chunk + r10], '>'
      jne .right_done 

      inc rbx 
      inc r10 

      jmp .count_right  

    .right_done:
      mov rsi, cursor_right_template 
      mov rcx, cursor_right_template_len 
      call writebuf

      mov rdi, rbx 
      call utoa 
      lea rsi, [utoa_buf + 4096]
      sub rsi, rax 
      mov rcx, rax 

      call writebuf

      mov byte [tmp], 0xA
      mov rsi, tmp
      mov rcx, 1 
      call writebuf

      mov byte [tmp], 0xA
      mov rsi, tmp
      mov rcx, 1 
      call writebuf
    
    dec r10 

    jmp .continue

  .cursor_left:
    xor rbx, rbx 
    
    .count_left:
      cmp r10, [bytes_to_compile]
      jge .left_done 

      cmp byte [chunk + r10], '<'
      jne .left_done 

      inc rbx 
      inc r10 

      jmp .count_left  

    .left_done:
      mov rsi, cursor_left_template 
      mov rcx, cursor_left_template_len 
      call writebuf

      mov rdi, rbx 
      call utoa 
      lea rsi, [utoa_buf + 4096]
      sub rsi, rax 
      mov rcx, rax 

      call writebuf

      mov byte [tmp], 0xA
      mov rsi, tmp
      mov rcx, 1 
      call writebuf

      mov byte [tmp], 0xA
      mov rsi, tmp
      mov rcx, 1 
      call writebuf
    
    dec r10 

    jmp .continue

  .add_cell:
    xor rbx, rbx 
    
    .count_plus:
      cmp r10, [bytes_to_compile]
      jge .plus_done 

      cmp byte [chunk + r10], '+'
      jne .plus_done 

      inc rbx 
      inc r10 

      jmp .count_plus

    .plus_done:
      mov rsi, add_cell_template
      mov rcx, add_cell_template_len 
      call writebuf

      mov rdi, rbx 
      call utoa 
      lea rsi, [utoa_buf + 4096]
      sub rsi, rax 
      mov rcx, rax 

      call writebuf

      mov byte [tmp], 0xA
      mov rsi, tmp
      mov rcx, 1 
      call writebuf

      mov byte [tmp], 0xA
      mov rsi, tmp
      mov rcx, 1 
      call writebuf
    
    dec r10 
    jmp .continue

  .sub_cell:
    xor rbx, rbx 
    
    .count_minus:
      cmp r10, [bytes_to_compile]
      jge .minus_done 

      cmp byte [chunk + r10], '-'
      jne .minus_done 

      inc rbx 
      inc r10 

      jmp .count_minus 

    .minus_done:
      mov rsi, sub_cell_template 
      mov rcx, sub_cell_template_len 
      call writebuf

      mov rdi, rbx 
      call utoa 
      lea rsi, [utoa_buf + 4096]
      sub rsi, rax 
      mov rcx, rax 

      call writebuf

      mov byte [tmp], 0xA
      mov rsi, tmp
      mov rcx, 1 
      call writebuf

      mov byte [tmp], 0xA
      mov rsi, tmp
      mov rcx, 1 
      call writebuf
    
    dec r10 

    jmp .continue

  .print_cell:
    mov rsi, print_cell_asm
    mov rcx, print_cell_len
    call writebuf

    jmp .continue

  .read_cell:
    mov rsi, read_byte_asm 
    mov rcx, read_byte_len
    call writebuf

    jmp .continue
  
  .loop_start:
    mov rax, r10 
    add rax, 3
    cmp rax, [bytes_to_compile]
    jg .no_optimizations
    
    cmp byte [chunk + r10 + 1], '-'
    je .check_close_minus
    
    cmp byte [chunk + r10 + 1], '+'
    je .check_close_plus

    jmp .no_optimizations

    .check_close_minus:
      cmp byte [chunk + r10 + 2], ']'
      jne .no_optimizations
      jmp .emit_clear_cell

    .check_close_plus:
      cmp byte [chunk + r10 + 2], ']'
      jne .no_optimizations
      jmp .emit_clear_cell

    .emit_clear_cell:
      mov rsi, clear_cell_template
      mov rcx, clear_cell_template_len 
      call writebuf

      add r10, 2
      jmp .continue

    .no_optimizations:
 
    push rbx ; rbx is callee saved  

    ; stack[sp++] = ++loop_count
    inc qword [loop_count]
    mov rbx, [stack_ptr]
    mov rax, [loop_count]
    mov [stack + rbx * 8], rax  
    inc qword [stack_ptr]

    pop rbx 
    
    mov rsi, loop_start_template
    mov rcx, loop_start_template_len
    call writebuf

    push rbx 
    
    ; rax = stack[sp - 1]
    mov rbx, [stack_ptr]
    dec rbx 
    mov rax, [stack + rbx * 8]

    pop rbx 

    mov rdi, rax

    push r10 
    call utoa
    pop r10 
  
    lea rsi, [utoa_buf + 4096]
    sub rsi, rax

    mov rcx, rax
    
    push rsi 
    push rcx 

    call writebuf

    mov rsi, loop_start_center
    mov rcx, loop_start_center_len
    call writebuf
    
    pop rcx 
    pop rsi 
    call writebuf
    
    mov [tmp], 0xA 

    mov rsi, tmp 
    mov rcx, 1 
    call writebuf
    
    mov rsi, tmp 
    mov rcx, 1 
    call writebuf

    jmp .continue

  .loop_end: 
    mov rsi, loop_end_header 
    mov rcx, loop_end_header_len 
    call writebuf

    push rbx 
    
    ; rax = stack[sp - 1]
    mov rbx, [stack_ptr]
    dec rbx 
    mov rax, [stack + rbx * 8]

    pop rbx 

    mov rdi, rax

    push r10 
    call utoa
    pop r10 
  
    lea rsi, [utoa_buf + 4096]
    sub rsi, rax

    mov rcx, rax
    
    call writebuf
    
    mov rsi, loop_end_template
    mov rcx, loop_end_template_len
    call writebuf

    push rbx ; rbx is callee saved  

    ; rdi = stack[--sp]
    dec qword [stack_ptr]
    mov rbx, [stack_ptr] 
    mov rdi, [stack + rbx * 8]

    pop rbx 

    push r10
    call utoa 
    pop r10 

    lea rsi, [utoa_buf + 4096]
    sub rsi, rax
    mov rcx, rax
    
    call writebuf

    mov [tmp], ':'
    mov rsi, tmp 
    mov rcx, 1 
    call writebuf

    mov [tmp], 10 
    mov rsi, tmp 
    mov rcx, 1 
    call writebuf

    jmp .continue

  .continue:
    inc r10
    jmp .loop 

  .chunk_end:
    ret 

writebuf: ; rsi = string | rcx = length
  .write_loop:
    cmp rcx, 0
    je .ret 
    
    mov rdx, [bytes_to_write]
    cmp rdx, 4095
    jl .write 
    
    push rcx 
    push rsi 

    mov rax, 1 
    mov rdi, [outfd]
    mov rsi, compiled_buf
    mov rdx, [bytes_to_write]
    
    syscall 
  
    mov qword [bytes_to_write], 0

    pop rsi 
    pop rcx

    .write:

    mov rdx, [bytes_to_write]
    movzx rax, byte [rsi]
    mov byte [compiled_buf + rdx], al 

    inc rsi 
    inc qword [bytes_to_write]
    dec rcx 

    jmp .write_loop 

  .ret:
    ret 
