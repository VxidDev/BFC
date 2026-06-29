# BFC

A simple Brainfuck compiler that translates Brainfuck source code into x86-64 NASM assembly.

The generated assembly can be assembled with NASM and linked into a native Linux executable.

## Features

* Compiles Brainfuck to x86-64 assembly
* Generates NASM-compatible output
* Produces native Linux executables
* Supports nested loops
* Uses a 30,000-byte memory tape with wrapping 8-bit cells

## Requirements

* Linux
* NASM
* GNU ld

## Building

```bash
make
```

## Usage

Compile a Brainfuck program:

```bash
./bfc hello-world.bf
```

This generates:

```text
bfc-out.s
```

Assemble and link:

```bash
nasm -f elf64 bfc-out.s
ld bfc-out.o -o hello
```

Run:

```bash
./hello
```

Output:

```text
Hello World!
```

## Example

`hello-world.bf`

```brainfuck
++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
```

## Memory Model

* 30,000 memory cells
* 8-bit wrapping values (0-255)
* Data pointer starts at the first cell

## Project Structure

```text
.
├── hello-world.bf
├── LICENSE
├── makefile
├── README.md
└── src
    ├── compiler.s
    ├── io
    │   ├── create_file.s
    │   ├── open_file.s
    │   ├── printnl.s
    │   ├── prints.s
    │   └── read_chunk.s
    ├── main.s
    ├── string
    │   ├── strcmp.s
    │   └── strlen.s
    └── syscalls
        ├── sys_exit.s
        └── sys_open.s
```

## Future Improvements

* Instruction optimization (`+++++` → `add`)
* Peephole optimizations
* error reporting
* Configurable tape size
* Additional target architectures

## License

GPL v3.0
