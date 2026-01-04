.glob kmalloc
.glob kfree

.include "sectRanges.adecl"

.data
	KERN_HEAPTOP: .word HEAP_START


.text

kmalloc:
	% Simple heap bump allocator
	% kmalloc(size:u32) -> &void
	% a0: size
	% xr: &void

	ld x10, KERN_HEAPTOP
	mv c1, x10 % have the previous heaptop be the return

	% get the actual address to update it by size
	ld x10, =KERN_HEAPTOP
	ld x11, [x10]
	add x11, x11, a0
	str x11, [x10]

	mv xr, c1
	ret

kfree:
	% simple free
	% kfree(ptr:&void, size:u32) -> void
	% a0: ptr
	% a1: size

	ld c1, =KERN_HEAPTOP
	ld c2, [c1]
	sub c2, c2, a1
	str c2, [c1]

	ret