all:
	wla-65816 snestest.asm
	wlalink snestest.link snestest.smc
clean:
	rm snestest.smc snestest.o
