section .data
  O_RDONLY equ 0q
  O_WRONLY equ 01q 
  O_RDWR equ 02q

section .text 
  global open_file_rdonly 
  extern sys_open

open_file_rdonly: ; rdi = filename | rax = fd || errcode
  push rbp 
  mov rbp, rsp  

  mov rsi, O_RDONLY
  call sys_open 
  
  mov rsp, rbp 
  pop rbp

  ret 


