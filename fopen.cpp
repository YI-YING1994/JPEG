#include <fstream>

using namespace std;

/*****************************************************************************************************/
// 
// Marker struct and override operator to convenience read
//
/*****************************************************************************************************/

struct Marker {
	unsigned char cCode[2];
	unsigned char cLength[2];
};

istream& operator>> (istream& s, Marker& val) {

	s.read((char*)val.cCode, 2);
	s.read((char*)val.cLength, 2);

	return s;
}

ostream& operator<< (ostream& s, Marker& val) {
	s << hex << (int)val.cCode[0] << " " << (int)val.cCode[1] << " ";
	s << hex << (int)val.cLength[0] << " " << (int)val.cLength[1];
}
