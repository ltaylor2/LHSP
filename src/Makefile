OBJS = Main.o Petrel.o Egg.o
CC = g++
DEBUG = -g
CFLAGS = -Wall -c $(DEBUG)
LFLAGS = -WALL $(DEBUG)

lhsp : $(OBJS)
    $(CC) $(LFLAGS) $(OBJS) -o lhsp

Main.o : Main.cpp
    $(CC) $(CFLAGS) Main.cpp

Petrel.o : Petrel.cpp Petrel.h
	$(CC) $(CFLAGS) Petrel.cpp

Egg.o : Egg.cpp Egg.h
	$(CC) $(CFLAGS) Egg.cpp

clean:
    \rm *.o *~ lhsp

