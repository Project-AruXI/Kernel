OUT = ./out

SRCS = onRun.s handlers.s alloc.s
TARGET = $(OUT)/kern.ark

OBJS = $(SRCS:.s=.ao)

%.ao: %.s
	arxsm $< -o $@

all: $(OBJS)
	arxlnk $(OBJS) -o $(TARGET) --kernel

clean:
	rm -f *.ao