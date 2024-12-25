all: terminal

terminal: terminal.c
	zcc +zx -vn -startup=0 -clib=new terminal.c -o terminal -create-app

clean:
	rm -f terminal.tap terminal *.bin
