all:
	arxsm onRun.s -o onRun.ao
	arxsm handlers.s -o handlers.ao
	arxsm alloc.s -o alloc.ao

# 	arxlnk onRun.ao handlers.ao alloc.ao -o kern.ark --kernel