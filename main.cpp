#include <iostream>
#include "fopen.cpp"
#include "decoder.cpp"

int main() {
	fstream fs;
	fs.open("Rex.jpg", fstream::in | fstream::out);

	return 0;
}