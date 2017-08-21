#include "reader.h"

/*****************************************************************************************************/
//
// Global variable for checking markers 
//
/*****************************************************************************************************/

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
// Operator>> function for FrameHeader and ComponentParameter
//
/*****************************************************************************************************/

istream& operator>> (istream& s, ComponentParameter& val) {
    s >> val.Ci;

    unsigned char temp;
    s >> temp;
    val.Hi = temp >> 4;
    val.Vi = temp & 0x0F;

    s >> val.Tqi;

    return s;
}

istream& operator>> (istream& s, FrameHeader& val) {

    // Use 8 unsigned char to tempily store data which need to compute later
    unsigned char temp[8];

    for (int i = 0; i < 8; i++)
        s >> temp[i];

    val.Lf = (temp[0] << 8) + temp[1];
    val.P = temp[2];
    val.Y = (temp[3] << 8) + temp[4];
    val.X = (temp[5] << 8) + temp[6];
    val.Nf = temp[7];

    ComponentParameter componentParameter;

    for (int i = 0; i < val.Nf; i++) {
        s >> componentParameter;
        val.componentParameters.push_back(componentParameter);
    }

    return s;
}

/*****************************************************************************************************/
//
// Operator>> function for ScanHeader and ScanComponentParameter
//
/*****************************************************************************************************/

istream& operator>> (istream& s, ScanComponentParameter& val) {
    s >> val.Csj;

    unsigned char temp;
    s >> temp;

    val.Tdj = temp >> 4;
    val.Taj = temp & 0x0F;

    return s;
}

istream& operator>> (istream& s, ScanHeader& val) {

    // Use 2 unsigned char to tempily store data which need to compute later
    unsigned char temp[2];

    s >> temp[0] >> temp[1];

    val.Ls = (temp[0] << 8) + temp[1];

    s >> val.Ns;

    ScanComponentParameter scanComponent;

    for (int i = 0; i < val.Ns; i++) {
        s >> scanComponent;
        val.scanComponentParameters.push_back(scanComponent);
    }

    s >> val.Ss >> val.Se >> temp[0];

    val.Ah = temp[0] >> 4;
    val.Al = temp[0] & 0x0F;

    return s;
}

/*****************************************************************************************************/
//
// Operator>> function for QuantizationTable and QuantizationParameter
//
/*****************************************************************************************************/

istream& operator>> (istream& s, QuantizationParameter& val) {

    // Use 2 unsigned char to tempily store data which need to compute later
    unsigned char temp[2];

    s >> temp[0];

    val.Pq = temp[0] >> 4;
    val.Tq = temp[0] & 0x0F;

    for (int i = 0; i < 64; i++) {

        // if precision is 16 bits, read two bytes into temp buffer
        if (val.Pq) {
            s >> temp[0] >> temp[1];
            val.Qk[i] = (temp[0] << 8) + temp[1];
        }

        // if precision is 8 bits, read one bytes into temp buffer
        // Note: Qk is unsigned short, so need to read data into temp buffer
        //       before store data into Qk
        else {
            s >> temp[0];
            val.Qk[i] = temp[0];
        }
    }

    return s;
}

istream& operator>> (istream& s, QuantizationTable& val) {

    // Use 2 unsigned char to tempily store data which need to compute later
    unsigned char temp[2];

    s >> temp[0] >> temp[1];

    val.Lq = (temp[0] << 8) + temp[1];

    // Get Quantization Table's range
    long long int i = s.tellg();
    long long int end = i + val.Lq - 2;
    QuantizationParameter parameter;

    while (i < end) {
        s >> parameter;
        val.quantizationParameters.push_back(parameter);
        i = s.tellg();
    }

    return s;
}

/*****************************************************************************************************/
//
// Operator>> function for HuffmanTable and HuffmanParameter
//
/*****************************************************************************************************/

istream& operator>> (istream& s, HuffmanParameter& val) {

    // Use an unsigned char to tempily store data which need to compute later
    unsigned char temp;

    s >> temp;

    val.Tc = temp >> 4;
    val.Th = temp & 0x0F;

    for (int i = 0; i < 16; i++)
        s >> val.Li[i];

    for (int i = 0; i < 16; i++)
        for(int j = 0; j < val.Li[i]; j++) {
            s >> temp;
            val.Vij[i].push_back(temp);
        }

    return s;
}

istream& operator>> (istream& s, HuffmanTable& val) {

    // Use 2 unsigned char to tempily store data which need to compute later
    unsigned char temp[2];

    s >> temp[0] >> temp[1];

    val.Lh = (temp[0] << 8) + temp[1];

    // Get Huffman Table's range
    long long int i = s.tellg();
    long long int end = i + val.Lh - 2;

    while (i < end) {
        HuffmanParameter parameter;
        s >> parameter;

        val.huffmanParameters.push_back(parameter);

        i = s.tellg();

        if (i == -1) {
            cout << "istream huffman error" << endl;
            break;
        }
    }
    
    return s;
}

