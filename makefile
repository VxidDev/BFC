AS = nasm
ASFLAGS = -f elf64
LD = ld
LDFLAGS = 

SRC_DIR = src
OBJ_DIR = .
TARGET = bfc

VPATH := $(shell find $(SRC_DIR) -type d)
SOURCES := $(shell find $(SRC_DIR) -name "*.s")
OBJECTS := $(patsubst %.s, %.o, $(notdir $(SOURCES)))

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: all clean
