section .data
  O_RDONLY equ 0q
  O_WRONLY equ 01q 
  O_RDWR equ 02q

section .text 
  global create_file 

create_file: ; rdi = filename | rax = fd || errcode
  mov rax, 2 
  mov rsi, 0x241 ; O_CREAT | O_WRONLY | O_TRUNC 
  mov rdx, 0644q

  syscall

  ret 

