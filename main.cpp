#include <iostream>
#include "fopen.cpp"
#include "huffman.cpp"

int main() {
	fstream fs;
	fs.open("Rex.jpg", fstream::in | fstream::out);

	return 0;
}