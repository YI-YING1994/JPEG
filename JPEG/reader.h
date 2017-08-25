//
//  reader.h
//  JPEG
//
//  Created by MCUCSIE on 8/20/17.
//  Copyright © 2017 MCUCSIE. All rights reserved.
//
#include <iostream>
#include <fstream>
#include <vector>
#include <set>

using namespace std;

#define TEM 0x01

// 0X02 ~ 0xBF // RES

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

// 0xD0 ~ 0xD7 // RST
// 0xE0 ~ 0xEF // APP
// 0xF0 ~ 0xFD // JPG

#define COM 0xFE

/*****************************************************************************************************/
//
// Structs used to read data and overriding operators to convenience using these structs
//
/*****************************************************************************************************/
#pragma mark- FrameHeader

struct ComponentParameter {
    unsigned char Ci;
    unsigned char Hi;
    unsigned char Vi;
    unsigned char Tqi;
};

istream& operator>> (istream& s, ComponentParameter& val);

struct FrameHeader {
    unsigned char marker = SOF;
    unsigned short Lf;
    unsigned char P;
    unsigned short Y;
    unsigned short X;
    unsigned char Nf;
    vector<ComponentParameter> componentParameters;
};

istream& operator>> (istream& s, FrameHeader& val);

/*******************************************************************************************************/
#pragma mark- ScanHeader

struct ScanComponentParameter {
    unsigned char Csj;
    unsigned char Tdj;
    unsigned char Taj;
};

istream& operator>> (istream& s, ScanComponentParameter& val);

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

istream& operator>> (istream& s, ScanHeader& val);

/*******************************************************************************************************/
#pragma mark- QuantizationTable

struct QuantizationParameter {
    unsigned char Pq;
    unsigned char Tq;
    unsigned short Qk[64];
};

istream& operator>> (istream& s, QuantizationParameter& val);

struct QuantizationHeader {
    unsigned char marker = DQT;
    unsigned short Lq;
    vector<QuantizationParameter> quantizationParameters;
};

istream& operator>> (istream& s, QuantizationHeader& val);

/*******************************************************************************************************/
#pragma mark- HuffmanTable

struct HuffmanParameter {
    unsigned char Tc;
    unsigned char Th;
    unsigned char Li[17];
    vector<unsigned char> Vij;
};

istream& operator>> (istream& s, HuffmanParameter& val);

struct HuffmanHeader {
    unsigned char marker = DHT;
    unsigned short Lh;
    vector<HuffmanParameter> huffmanParameters;

};

istream& operator>> (istream& s, HuffmanHeader& val);

/*******************************************************************************************************/
#pragma mark- ArithmeticTable

struct ArithmeticParameter {
    unsigned char Tc;
    unsigned char Tb;
    unsigned char Cs;
};

istream& operator>> (istream& s, ArithmeticParameter& val);

struct ArithmeticTable {
    unsigned char marker = DAC;
    unsigned short La;
    vector<ArithmeticParameter> arithmeticParameters;
};

istream& operator>> (istream& s, ArithmeticTable& val);

/*******************************************************************************************************/
#pragma mark- RestartInterval

struct RestartInterval {
    unsigned char marker = DRI;
    unsigned short Lr;
    unsigned short Ri;
};

istream& operator>> (istream& s, RestartInterval& val);

/*******************************************************************************************************/
#pragma mark- CommentSegment

struct CommentSegment {
    unsigned char marker = COM;
    unsigned short Lc;
    vector<unsigned char> Cmi;
};

istream& operator>> (istream& s, CommentSegment& val);

/*******************************************************************************************************/
#pragma mark- Application

struct Application {
    unsigned char marker;
    unsigned short Lp;
    vector<unsigned char> Api;
};

istream& operator>> (istream& s, Application& val);

/*******************************************************************************************************/
#pragma mark- DefineNumberOfLine

struct DefineNumberOfLine {
    unsigned char marker = DNL;
    unsigned short Ld;
    unsigned short NL;
};

istream& operator>> (istream& s, DefineNumberOfLine& val);

/*******************************************************************************************************/
