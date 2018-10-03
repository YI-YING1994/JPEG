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

enum JPEG_Marker{
    SOF0  = 0xC0, SOF1  = 0xC1, SOF2  = 0xC2, SOF3  = 0xC3, SOF5  = 0xC5, SOF6  = 0xC6, SOF7  = 0xC7, JPG  = 0xC8,
    SOF9  = 0xC9, SOF10 = 0xCA, SOF11 = 0xCB, SOF13 = 0xCD, SOF14 = 0xCE, SOF15 = 0xCF, DHT   = 0xC4, DAC  = 0xCC,
    RST0  = 0xD0, RST1  = 0xD1, RST2  = 0xD2, RST3  = 0xD3, RST4  = 0xD4, RST5  = 0xD5, RST6  = 0xD6, RST7 = 0xD7,
    SOI   = 0xD8, EOI   = 0xD9, SOS   = 0xDA, DQT   = 0xDB, DNL   = 0xDC, DRI   = 0xDD, DHP   = 0xDE, EXP  = 0xDF,
    APP0  = 0xE0, APP15 = 0xEF, JPG0  = 0xF0, JPG13 = 0xFD, COM   = 0xFE, TEM   = 0x01
    // 0X02 ~ 0xBF // RES
    // 0xE0 ~ 0xEF // APP
    // 0xF0 ~ 0xFD // JPG
};

/*****************************************************************************************************/
//
// Structs used to read data and overriding operators to convenience using these structs
//
/*****************************************************************************************************/
#pragma mark - FrameHeader

struct ComponentParameter {
    unsigned char Ci;
    unsigned char Hi;
    unsigned char Vi;
    unsigned char Tqi;
};

istream& operator>> (istream &s, ComponentParameter &val);

struct FrameHeader {
    unsigned char marker = SOF0;
    unsigned short Lf;
    unsigned char P;
    unsigned short Y;
    unsigned short X;
    unsigned char Nf;
    vector<ComponentParameter> componentParameters;
};

istream& operator>> (istream &s, FrameHeader &val);

/*******************************************************************************************************/
#pragma mark- ScanHeader

struct ScanComponentParameter {
    unsigned char Csj;
    unsigned char Tdj;
    unsigned char Taj;
};

istream& operator>> (istream &s, ScanComponentParameter &val);

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

istream& operator>> (istream &s, ScanHeader &val);

/*******************************************************************************************************/
#pragma mark- QuantizationTable

struct QuantizationParameter {
    unsigned char Pq;
    unsigned char Tq;
    unsigned short Qk[64];
};

istream& operator>> (istream &s, QuantizationParameter &val);

struct QuantizationHeader {
    unsigned char marker = DQT;
    unsigned short Lq;
    vector<QuantizationParameter> quantizationParameters;
};

istream& operator>> (istream &s, QuantizationHeader &val);

/*******************************************************************************************************/
#pragma mark- HuffmanTable

struct HuffmanParameter {
    unsigned char Tc;
    unsigned char Th;
    unsigned char Li[17];
    vector<unsigned char> Vij;
};

istream& operator>> (istream &s, HuffmanParameter &val);

struct HuffmanHeader {
    unsigned char marker = DHT;
    unsigned short Lh;
    vector<HuffmanParameter> huffmanParameters;

};

istream& operator>> (istream &s, HuffmanHeader &val);

/*******************************************************************************************************/
#pragma mark- ArithmeticTable

struct ArithmeticParameter {
    unsigned char Tc;
    unsigned char Tb;
    unsigned char Cs;
};

istream& operator>> (istream &s, ArithmeticParameter &val);

struct ArithmeticTable {
    unsigned char marker = DAC;
    unsigned short La;
    vector<ArithmeticParameter> arithmeticParameters;
};

istream& operator>> (istream &s, ArithmeticTable &val);

/*******************************************************************************************************/
#pragma mark- RestartInterval

struct RestartInterval {
    unsigned char marker = DRI;
    unsigned short Lr;
    unsigned short Ri;
};

istream& operator>> (istream &s, RestartInterval &val);

/*******************************************************************************************************/
#pragma mark- CommentSegment

struct CommentSegment {
    unsigned char marker = COM;
    unsigned short Lc;
    vector<unsigned char> Cmi;
};

istream& operator>> (istream &s, CommentSegment &val);

/*******************************************************************************************************/
#pragma mark- Application

struct Application {
    unsigned char marker;
    unsigned short Lp;
    vector<unsigned char> Api;
};

istream& operator>> (istream &s, Application &val);

/*******************************************************************************************************/
#pragma mark- DefineNumberOfLine

struct DefineNumberOfLine {
    unsigned char marker = DNL;
    unsigned short Ld;
    unsigned short NL;
};

istream& operator>> (istream &s, DefineNumberOfLine &val);

/*******************************************************************************************************/
