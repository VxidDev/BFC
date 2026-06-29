section .bss
  global chunk
  chunk resb 4096

section .text 
  global read_chunk

read_chunk: ; rdi = fd | rax = bytes read 
  mov rax, 0
  mov rsi, chunk 
  mov rdx, 4096 

  syscall 

  ret 
