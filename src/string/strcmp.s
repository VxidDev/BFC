section .text 
  global strcmp

strcmp: ; rdi = s1 (null-term) , rsi = s2 (null-term) | rax = 0/1
  xor r8, r8 ; current index 

  .cmploop:
    mov r9b, [rdi + r8] 
    mov r10b, [rsi + r8]

    cmp r9b, r10b  
    jne .noteq

    test r9b, r9b 
    jz .eq 
    
    inc r8 
    jmp .cmploop 

  .noteq:
    mov rax, 0
    ret 

  .eq:
    mov rax, 1 
    ret 
