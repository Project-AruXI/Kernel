.include "sectRanges.adecl"

.extern kmalloc
.extern kfree

.glob PS_PTR
.glob KERN_STATE_SP

.glob _destroyPS

.data
	PS_PTR: .word #0x0

	KERN_STATE:
		% saved sp of the kernel stack to return after user program
		KERN_STATE_SP: .word STACK_LIMIT


.text
	__onStart:
		% code that runs when the kernel is first started
		% for now NOP then halt
		nop
		hlt

	% no need to mark global, the location is always known
	_usrSetup:
		% loader/emulator placed user entry point at the very bottom of the stack (aka at the limit)
		% however it did not update the sp, but it is to be guaranteed to be at STACK_LIMIT-4
		ld sp, =STACK_LIMIT - 0x4

		call _setPS

		% save kernel sp
		ld c1, =KERN_STATE_SP
		str sp, [c1]

		% a call is to be done but the addres is known in stack, move it to a reg
		ld c1, [sp]
		% c1 contains the entry point, before a simulated call, set the link register
		%  so on user return, it comes back here
		% save the instruction after ubr
		ld lr, =USER_RET_AT

		% set the user stack pointer
		ld sp, =USR_STACK_START - 0x4

		% switch to user mode, this needs to be done right before the call
		% CSTR = CSTR & ~(1<<9)
		ldcstr x10
		mv x11, #0x1
		lsl x11, x11, #9 % PRIV flag is bit 9
		not x11, x11
		and x10, x10, x11
		mvcstr x10
		ubr c1 % run user program
		.set USER_RET_AT, @
		% restore sp
		ld sp, KERN_STATE_SP
		% return value of user program is in xr
		sub sp, sp, #4
		str xr, [sp]

		% remove PS
		call _destroyPS

		ld xr, [sp]
		add sp, sp, #4

		hlt



	.set PS_SIZE, #570 % size that a process state takes in bytes
	_setPS:
		% set up the process state

		% get memory for the process state
		% PS takes up PS_SIZE bytes

		mv a0, PS_SIZE
		% save LR
		sub sp, sp, #4
		str lr, [sp]
		call kmalloc
		% restore LR
		ld lr, [sp]
		add sp, sp, #4
		% xr contains pointer to memory block for PS, save it
		ld c1, =PS_PTR
		str xr, [c1]

		strb xz, [xr] % ignore PIDs for now; PS.pid
		strb xz, [xr, #1] % no threads for now; PS.threadc
		str xz, [xr, #2] % no threads; PS.threadStates
		ld c1, =USR_STACK_START
		str c1, [xr, #6] % user sp; PS.sp
		str x1, [xr, #10] % user ir; PS.ir

		mv c2, #566 % offset is too large for mem ops (9 bits), use index mode
		str xz, [xr], c3 % excpType

		ret

	_destroyPS:
		% free the process state
		% basically just free the memory from pointer
		ld a0, =PS_PTR % get the stored PS pointer
		mv a1, PS_SIZE

		sub sp, sp, #4
		str lr, [sp]
		call kfree
		ld lr, [sp]
		add sp, sp, #4

		% "null" PS_PTR
		str xz, [a0]

		ret