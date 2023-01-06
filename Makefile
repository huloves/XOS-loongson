#!Makefile

BUILD_DIR = ./build
C_SOURCES = $(shell find . -name "*.c")
C_OBJECTS = $(patsubst %.c, %.o, $(C_SOURCES))
S_SOURCES = $(shell find . -name "*.S")
S_OBJECTS = $(patsubst %.S, %.o, $(S_SOURCES))

CROSS_COMPILE = /opt/gcc-4.4-gnu/bin/mipsel-linux-
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld

QEMU = ~/loongson/emu/qemu/build/mips64el-softmmu/qemu-system-mips64el

C_FLAGS = -mabi=32 -mno-abicalls -D_LOCORE -G 0 -mips3 -fno-strict-aliasing -I ./include/ -c -fno-builtin -fno-stack-protector -nostdinc -fno-pic -gdwarf-2 -g
LD_FLAGS = -T ./script/ld.script -nostdlib

all: $(S_OBJECTS) $(C_OBJECTS) link

.c.o:
	@echo 编译代码文件 $< ...
	$(CC) $(C_FLAGS) $< -o $@

.S.o:
	@echo 编译汇编文件 $< ...
	$(CC) $(C_FLAGS) $< -o $@

link:
	@echo 链接内核文件...
	$(LD) $(LD_FLAGS) $(S_OBJECTS) $(C_OBJECTS) -o kernel.bin

.PHONY:clean
clean:
	$(RM) $(S_OBJECTS) $(C_OBJECTS) kernel.bin

.PHONY:qemu
qemu: all
	$(QEMU) -M ls2k -m 4G  -smp 1 --nographic -bios ./kernel.bin
