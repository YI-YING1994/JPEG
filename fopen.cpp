#include <fstream>
using namespace std;

#define SOF 0xC0
#define DHT 0xC4
#define SOI 0xD8
#define EOI 0xD9
#define SOS 0xDA
#define DQT 0xDB

/*****************************************************************************************************/
// 
// Structs used to read data and overriding operators to convenience using these structs
//
/*****************************************************************************************************/

struct Marker {
	unsigned char cCode[2];
} smMarker;

istream& operator>> (istream& s, Marker& val) {

	s.read((char*)val.cCode, 2);

	return s;
}

ostream& operator<< (ostream& s, Marker& val) {
	s << hex << (int)val.cCode[0] << " " << (int)val.cCode[1] << " ";
}

/*******************************************************************************************************/

