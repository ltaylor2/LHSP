CXXFLAGS=-g -std=c++11 -pthread
BIN=lhsp

SRC=$(wildcard *.cpp)
OBJ=$(SRC:%.cpp=%.o)

all: $(OBJ)
	$(CXX) -pthread -o $(BIN) $^

%.o: %.c
	$(CXX) $@ -c $<

clean:
	rm -f *.o
	rm -f $(BIN)