all:
	arxsm onRun.s -o onRun.o
	arxsm handlers.s -o handlers.o
	arxsm alloc.s -o alloc.o

# 	arxlnk onRun.o handlers.o alloc.o -o kern.ark --kernel