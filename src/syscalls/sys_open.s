section .text 
  global sys_open 

sys_open: ; rdi = filename , rsi = flags , rdx = mode 
  mov rax, 2
  syscall 

  ret
