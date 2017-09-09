# parametrable :
# liste des autres repertoires d'entetes (./ deja pris en compte):
OTHER_HEADER_DIRS := /usr/include/python3.5m
# liste des autres repertoires de sources (put end /) :
OTHER_SRC_DIRS := test/
GCC_FLAGS := -Wall -Os

SHELL=/bin/bash

# EXE prend par defaut le nom du repertoire ou est situe le makefile
EXE ?= $(notdir $(CURDIR))

C_SRC = $(wildcard *.c)
# si OTHER_SRC_DIRS contient quelque chose
ifneq ($(strip $(OTHER_SRC_DIRS)),)
C_SRCS = $(C_SRC) $(foreach d, $(OTHER_SRC_DIRS), $(wildcard $(d)*.c))
endif
OBJS = $(C_SRCS:.c=.o)
DEPS = $(C_SRCS:.c=.d)
LIBS = -lpython3.5m
# si OTHER_HEADER_DIRS contient quelque chose
ifneq ($(strip $(OTHER_HEADER_DIRS)),)
INC_DIRS = $(foreach d, $(OTHER_HEADER_DIRS), -I$d)
endif


# list asm files to generate
ASM = $(C_SRCS:.c=.s)
# link each file separatly
LINK_EACH_FILE = $(C_SRCS:.c=)


# construit en meme temps un fichier de dependance .d
GCC_OPT := $(GCC_FLAGS) $(INC_DIRS) -MMD -MP


# ===== Specific for python ! =================================================
# retrieve python source files
PY_SRC = $(wildcard *.py)
# si OTHER_SRC_DIRS contient quelque chose
ifneq ($(strip $(OTHER_SRC_DIRS)),)
PY_SRCS = $(PY_SRC) $(foreach d, $(OTHER_SRC_DIRS), $(wildcard $(d)*.py))
endif
# retrieve c files generated from python source files
PY_CSRCS = $(PY_SRCS:.py=.c)
# =============================================================================


build_all build: $(EXE)

rebuild_all rebuild: clean build_all


# compile separatly each file

build_each: link-each

rebuild_each: clean build_each


# generate all files (include assembly file)

generate_all generate: compile assemble link-all

regenerate_all regenerate: clean generate_all

generate_each: compile assemble link-each

regenerate_each: clean generate_each

run: $(EXE)
	-sudo chmod u+x $(EXE)
	@echo '====================================================================='
	@echo 'Execution ...'
	./$(EXE)
	@echo '====================================================================='

$(EXE) link-all link: $(OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: GCC C Linker'
	gcc $(GCC_OPT) -o $(EXE) $(OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

link-each: $(OBJS)
	@$(foreach prog, $(LINK_EACH_FILE), \
	echo 'Linking file: $(prog)'; \
	echo 'Invoking: GCC C Linker'; \
	( set -x; gcc $(GCC_OPT) -o $(prog) $(prog).o $(LIBS) ); \
	echo 'Finished linking: $(prog)'; \
	echo ' '; \
	${\n})

# generate object file
assemble: $(OBJS)

%.o: ./%.c
	$(eval ASM_FILE := $(<:.c=.s))
	
	@if [ -f $(ASM_FILE) ]; \
	then \
		echo 'Building file: $(ASM_FILE)'; \
		echo 'Invoking: GCC C Assembler'; \
		( set -x; gcc $(GCC_OPT) -c -o "$@" $(ASM_FILE) $(LIBS) ); \
		echo 'Finished building: $(ASM_FILE)'; \
		echo ' '; \
	else \
		echo 'Building file: $<'; \
		echo 'Invoking: GCC C Compiler and Assembler'; \
		( set -x; gcc $(GCC_OPT) -c -o "$@" "$<" $(LIBS) ); \
		echo 'Finished building: $<'; \
		echo ' '; \
	fi \

# generate asm file
compile: $(ASM)

%.s: ./%.c
	@echo 'Compiling file: $<'
	@echo 'Invoking: GCC C Compiler'
	gcc $(GCC_OPT) -S -o "$@" "$<" $(LIBS)
	@echo 'Finished compiling: $<'
	@echo ' '

clean:
	-rm -f $(OBJS) $(ASM) $(DEPS) $(EXE) $(LINK_EACH_FILE)


# ===== Specific for python, to generate assembly from python source code ======
install_pyall: install_python install_cython

install_python:
	@echo 'Install package python3.5'
	sudo apt-get install python3.5

install_cython:
	@echo 'Install package cython3'
	sudo apt-get install cython3

runpy:
	@echo 'Set var EXE to specify which *.py file to execute, without extension'
	@echo 'EXE = "$(EXE)"'
	-sudo chmod u+x $(EXE).py
	@echo '====================================================================='
	@echo 'Execution ...'
	python3.5 ./$(EXE).py
	@echo '====================================================================='

runpygnu_all runpygnu: convpytoc
	@make run

# build each source file separatly
runpygnu_each: convpytoc
	@make build_each
	@echo 'Set var EXE to specify which file to execute'
	@echo 'EXE = "$(EXE)"'
	-sudo chmod u+x $(EXE)
	@echo '====================================================================='
	@echo 'Execution ...'
	./$(EXE)
	@echo '====================================================================='

convpytoasm : convpytoc
	@make compile

convpytoc: $(PY_CSRCS)

%.c: ./%.py
	cython3 "$<" --embed -o "$@"

# remove c files generated
cleanpy: clean
	-rm -f $(PY_CSRCS)

# ==============================================================================


.PHONY: build_all build rebuild_all rebuild build_each rebuild_each generate_all generate regenerate_all regenerate generate_each regenerate_each run link-all link link-each assemble compile clean install_pyall install_python install_cython runpy runpygnu_all runpygnu runpygnu_each convpytoasm convpytoc cleanpy

-include $(DEPS)


