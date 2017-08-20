#include <fstream>
#include <vector>
#include <set>

using namespace std;

#define TEM 0x01

#define SOF 0xC0
#define DHT 0xC4
#define DAC 0xCC

#define SOI 0xD8
#define EOI 0xD9

#define SOS 0xDA
#define DQT 0xDB
#define DNL 0xDC
#define DRI 0xDD
#define DHP 0xDE
#define EXP 0xDF

#define COM 0xFE

set<unsigned char> setMarkers = {
    0x01,          // TEM
    // 0X02 ~ 0xBF // RES

    0xC0,          // SOF
    0xC4,          // DHT
    0xCC,          // DAC

    0xD8,          // SOI
    0xD9,          // EOI

    0xDA,          // SOS
    0xDB,          // DQT
    0xDC,          // DNL
    0xDD,          // DRI
    0xDE,          // DHP
    0xDF,          // EXP

    // 0xD0 ~ 0xD7 // RST
    // 0xE0 ~ 0xEF // APP
    // 0xF0 ~ 0xFD // JPG

    0xFE,          // COM
};

/*****************************************************************************************************/
// 
// Structs used to read data and overriding operators to convenience using these structs
//
/*****************************************************************************************************/

struct ComponentParameter {
    unsigned char Ci;
    unsigned char Hi;
    unsigned char Vi;
    unsigned char Tqi;
};

struct FrameHeader {
    unsigned char marker = SOF;
    unsigned short Lf;
    unsigned char P;
    unsigned short Y;
    unsigned short X;
    unsigned char Nf;
    vector<ComponentParameter> componentParameters;


} frameHeader;

istream& operator>> (istream& s, FrameHeader& val) {
    
    return s;
}

/*******************************************************************************************************/

struct ScanComponentParameter {
    unsigned char Csj;
    unsigned char Tdj;
    unsigned char Taj;
};

struct ScanHeader {
    unsigned char marker = SOS;
    unsigned short Ls;
    unsigned char Ns;
    vector<ScanComponentParameter> scanComponentParameters;
    unsigned char Ss;
    unsigned char Se;
    unsigned char Ah;
    unsigned char Al;
};

vector<ScanHeader> scanHeaders;

/*******************************************************************************************************/

struct QuantizationParameter {
    unsigned char Pq;
    unsigned char Tq;
    unsigned short Qk[64];
};

struct QuantizationTable {
    unsigned char marker = DQT;
    unsigned short Lq;
    vector<QuantizationParameter> quantizationParameters;
} quantizationTable;

/*******************************************************************************************************/

struct HuffmanParameter {
    unsigned char Tc;
    unsigned char Th;
    unsigned char Li[16];
    vector<unsigned char> Vij;
};

struct HuffmanTable {
    unsigned char marker = DHT;
    unsigned short Lh;
    vector<HuffmanParameter> huffmanParameters;
    
} huffmanTable;

/*******************************************************************************************************/

struct ArithmeticParameter {
    unsigned char Tc;
    unsigned char Tb;
    unsigned char Cs;
};

struct ArithmeticTable {
    unsigned char marker = DAC;
    unsigned short La;
    vector<ArithmeticParameter> arithmeticParameters;
};

/*******************************************************************************************************/

struct RestartInterval {
    unsigned char marker = DRI;
    unsigned short Lr;
    unsigned short Ri;
};

vector<RestartInterval> restartInterval;

/*******************************************************************************************************/

struct Comment {
    unsigned char marker = COM;
    unsigned short Lc;
    vector<unsigned char> Cmi;
};

/*******************************************************************************************************/

struct Application {
    unsigned char marker;
    unsigned short Lp;
    vector<unsigned char> Api;
};

/*******************************************************************************************************/

struct DefineNumberOfLine {
    unsigned char marker = DNL;
    unsigned short Ld;
    unsigned short NL;
};

/*******************************************************************************************************/
