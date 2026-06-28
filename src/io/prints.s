section .text 
  global prints 
  extern strlen

prints: ; rdi = buffer (null-terminated)
  push rbp 
  mov rbp, rsp

  call strlen ; rax = len 

  mov rdx, rax ; len 
  mov rsi, rdi ; buffer 
  mov rax, 1 ; sys_write
  mov rdi, 1 ; stdout

  syscall

  mov rsp, rbp 
  pop rbp 
  ret 
