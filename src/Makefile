CC = g++
CFLAGS= -g -Wall -std=c++0x

default: compile

compile: Main.o Petrel.o Egg.o
	$(CC) $? -o lhsp

Main.o: Main.cpp
	$(CC) $(CFLAGS) -c $< -o $@

Petrel.o: Petrel.cpp Petrel.h
	$(CC) $(CFLAGS) -c $< -o $@

Egg.o: Egg.cpp Egg.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	$(RM) *.o *~ lhsp