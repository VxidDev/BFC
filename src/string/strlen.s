section .text 
  global strlen 

strlen: ; rdi = string (null-term)
  xor rax, rax  ; index 

  .loop:
    mov cl, byte [rdi + rax]
    cmp cl, 0

    je .end

    inc rax 
    jmp .loop 

  .end:
    ret 
