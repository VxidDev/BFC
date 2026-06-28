section .text 
  global sys_exit

sys_exit: ; rdi = exit code
  mov rax, 60
  syscall

  ret
