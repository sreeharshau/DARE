#
# Copyright (c) 2014-2015 ETH-Zurich. All rights reserved.
#
# Author(s): Marius Poke <marius.poke@inf.ethz.ch>
#

CC = gcc

FLAGS        = -std=gnu99 -I./include -I./utils/rbtree/include -I/usr/include
CFLAGS       = #-Wall -Wunused-function #-Wextra
LDFLAGS      = 

PREFIX  = /users/s2udayas/DARE
LIBPATH = $(PREFIX)/lib
BINDIR = $(PREFIX)/bin

HEADERS = $(shell echo include/*.h)
SRCS = $(shell echo src/*.c)
OBJS = $(SRCS:.c=.o)
DARE = $(LIBPATH)/libdare.a

RBTREE_HEADERS = $(shell echo utils/rbtree/include/*.h)
RBTREE_SRCS = $(shell echo  utils/rbtree/src/*.c)
RBTREE_OBJS = $(RBTREE_SRCS:.c=.o)
RBTREE = $(LIBPATH)/librbtree.a

SRV_TEST_SRCS = $(shell echo test/srv_test.c)
SRV_TEST_OBJS = $(SRV_TEST_SRCS:.c=.o)
SRV_TEST = $(BINDIR)/srv_test

CLT_TEST_SRCS = $(shell echo test/clt_test.c)
CLT_TEST_OBJS = $(CLT_TEST_SRCS:.c=.o)
CLT_TEST = $(BINDIR)/clt_test

MPI_LAUNCH_SRCS = $(shell echo test/mpi_launcher.c)
MPI_LAUNCH_OBJS = $(MPI_LAUNCH_SRCS:.c=.o)
MPI_LAUNCH = $(BINDIR)/mpi_launcher

KVS_TRACE_SRCS = $(shell echo trace/kvs_trace.c)
KVS_TRACE_OBJS = $(KVS_TRACE_SRCS:.c=.o)
KVS_TRACE = $(BINDIR)/kvs_trace

RESIZE_TRACE_SRCS = $(shell echo trace/resize_trace.c)
RESIZE_TRACE_OBJS = $(RESIZE_TRACE_SRCS:.c=.o)
RESIZE_TRACE = $(BINDIR)/resize_trace

all: dare test trace

$(RBTREE): rbtree_print $(RBTREE_OBJS) $(RBTREE_HEADERS)
	mkdir -pm 755 $(LIBPATH)
	ar -rcs $@ $(RBTREE_OBJS)
	@echo "##############################"
	@echo
rbtree_print:
	@echo "##### BUILDING Red-Black Tree #####"
	
dare: FLAGS += -I/usr/lib/x86_64-linux-gnu//include
dare: LDFLAGS += -lev
dare: $(DARE) 
$(DARE): $(RBTREE) dare_print $(OBJS) $(HEADERS) 
	mkdir -pm 755 $(LIBPATH)
	ar -rcs $@ $(OBJS) $(RBTREE_OBJS)
	@echo "##############################"
	@echo
dare_print:
	@echo "##### BUILDING DARE #####"

test: FLAGS += -I/usr/lib/x86_64-linux-gnu//include
test: LDFLAGS +=  -L$(LIBPATH) -ldare -lev -libverbs -lm 
test: $(SRV_TEST) $(CLT_TEST) $(MPI_LAUNCH)
$(SRV_TEST): srv_test_print $(SRV_TEST_OBJS) $(HEADERS) $(DARE)
	mkdir -pm 755 $(BINDIR)
	$(CC) $(FLAGS) $(CFLAGS) -o $(SRV_TEST) $(SRV_TEST_OBJS) $(LDFLAGS)
	@echo "##############################"
	@echo
srv_test_print:
	@echo "##### BUILDING Server #####"

$(CLT_TEST): clt_test_print $(CLT_TEST_OBJS) $(HEADERS) $(DARE)
	mkdir -pm 755 $(BINDIR)
	$(CC) $(FLAGS) $(CFLAGS) -o $(CLT_TEST) $(CLT_TEST_OBJS) $(LDFLAGS)
	@echo "##############################"
	@echo
clt_test_print:
	@echo "##### BUILDING Client #####"

$(MPI_LAUNCH): mpi_launch_print
	mkdir -pm 755 $(BINDIR)
	mpicc $(MPI_LAUNCH_SRCS) -o $(MPI_LAUNCH)
	@echo "##############################"
	@echo
mpi_launch_print:
	@echo "##### BUILDING MPI Launcher #####"
	
trace: LDFLAGS +=  -L$(LIBPATH) -ldare
trace: trace_print $(KVS_TRACE) $(RESIZE_TRACE)
$(KVS_TRACE): $(KVS_TRACE_OBJS) $(HEADERS) $(DARE)
	mkdir -pm 755 $(BINDIR)
	$(CC) $(FLAGS) $(CFLAGS) -o $(KVS_TRACE) $(KVS_TRACE_OBJS) $(LDFLAGS)
$(RESIZE_TRACE): $(RESIZE_TRACE_OBJS) $(HEADERS) $(DARE)
	mkdir -pm 755 $(BINDIR)
	$(CC) $(FLAGS) $(CFLAGS) -o $(RESIZE_TRACE) $(RESIZE_TRACE_OBJS) $(LDFLAGS)	
	@echo "##############################"
	@echo
trace_print:
	@echo "##### BUILDING Trace Generators #####"

# Conditional inclusion can be used to include debugging code with something like
# #ifdef DEBUG
#	  printf();
# #endif
# To achieve such conditional debug statements, you can either add the line
# #define DEBUG
# at the beginning of the source code or compile the source code with
# gcc -DDEBUG file
# The flag -D stands for define
debug: FLAGS += -DDEBUG -g -O0
debug: dare test trace

clean:
	@echo "##### CLEAN-UP #####"
	-rm -f $(SRV_TEST_OBJS)
	-rm -f $(CLT_TEST_OBJS)
	-rm -f $(KVS_TRACE_OBJS) $(RESIZE_TRACE_OBJS)
	-rm -f $(RBTREE_OBJS)
	-rm -f $(OBJS)
	-rm -f $(SRV_TEST) $(CLT_TEST) $(KVS_TRACE) $(RESIZE_TRACE) $(DARE) $(RBTREE)
	-rm -f $(MPI_LAUNCH) 
	@echo "####################"
	@echo
	 
distclean: clean
	-rm -f Makefile

%.o: %.c $(HEADERS)
	$(CC) $(FLAGS) $(CFLAGS) -c -o $@ $<
	 
	 
.PHONY : all clean distclean
