section .data 
  nl db 0xA

section .text 
  global printnl

printnl: 
  mov rax, 1 
  mov rdi, 1 
  mov rsi, nl 
  mov rdx, 1 

  syscall 

  ret 
