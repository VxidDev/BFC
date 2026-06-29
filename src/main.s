default rel 

section .rodata
  arg_overflow_s1 db "BFC: invalid argument: '", 0
  arg_overflow_s2 db "'", 0xA, 0

  filename_expected db "BFC: filename expected.", 0xA, 0
  
  open_fail db "BFC: failed to open file.", 0xA, 0

section .bss 
  argc resq 1 
  argv resq 1

  filename resq 1
  
section .text 
  global _start 
  
  extern sys_exit
  extern strcmp
  extern prints
  extern printnl
  extern open_file_rdonly
  extern compile_file

_start:
  mov rax, [rsp] ; argc 
  mov [argc], rax 

  lea rax, [rsp + 8] ; argv 
  mov [argv], rax 

  push rbp 
  mov rbp, rsp 

  call parseargs
  
  mov rdi, [filename]
  test rdi, rdi
  jnz .continue
  
  mov rdi, filename_expected
  call prints 
  
  mov rsp, rbp
  pop rbp 

  mov rdi, 1 
  call sys_exit

  .continue:

  call open_file_rdonly
  cmp rax, 0
  jge .compile 

  mov rdi, open_fail
  call prints

  mov rsp, rbp 
  pop rbp 

  call sys_exit

  .compile: 
  mov rdi, rax
  call compile_file
  
  mov rdi, rax 

  mov rsp, rbp 
  pop rbp 

  call sys_exit

parseargs: 
  push rbp 
  mov rbp, rsp 

  mov r8, 1 ; index 
  xor r9, r9 ; positonals 

  .loop:
    cmp r8, [argc]
    jge .end 
    
    mov rbx, [argv]
    mov rax, [rbx + 8 * r8]

    test rax, rax 
    jz .end

    mov cl, byte [rax]

    cmp cl, '-'
    je .flag 
    
    jmp .positional 

  .flag:
    ; TODO: add support for flags 
    jmp .continue 
  
  .positional:
    cmp r9, 0 ; filename 
    jg .arg_overflow 
    
    mov [filename], rax 

    inc r9 
    jmp .continue

  .arg_overflow:
    mov rbx, rax  

    mov rdi, arg_overflow_s1 
    call prints
    
    mov rax, rbx 

    mov rdi, rax 
    call prints

    mov rdi, arg_overflow_s2
    call prints 
    
    mov rax, 1 
    call sys_exit

  .continue:
    inc r8 
    jmp .loop 

  .end:
    mov rsp, rbp 
    pop rbp 

    ret
