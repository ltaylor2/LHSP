CC = g++
CXXFLAGS = -g -Wall -std=c++11

default: compile

compile: Main.o Petrel.o Egg.o
	$(CC) -o lhsp

Main.o : Main.cpp
	$(CC) $(CXXFLAGS) -c Main.cpp

Petrel.o : Petrel.cpp Petrel.h
	$(CC) $(CXXFLAGS) -c Petrel.cpp

Egg.o : Egg.cpp Egg.h
	$(CC) $(CXXFLAGS) -c Egg.cpp

clean:
	$(RM) *.o *~ lhsp