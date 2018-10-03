#include "reader.h"

/*****************************************************************************************************/
//
// Global variable for checking markers 
//
/*****************************************************************************************************/
#pragma mark Global variable for checking markers
set<unsigned char> setMarkers = {
     SOF0,  SOF1,  SOF2,  SOF3,  SOF5,
     SOF6,  SOF7,  SOF9, SOF10, SOF11,
    SOF13, SOF14, SOF15,   DHT,   DAC,
      SOI,   EOI,   SOS,   DQT,   DNL,
      DRI,   DHP,   EXP,   COM,   TEM
};

/*****************************************************************************************************/
//
// Operator>> function for FrameHeader and ComponentParameter
//
/*****************************************************************************************************/
#pragma mark - Operator>> function for FrameHeader and ComponentParameter
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

    val.Lf = (temp[0] << 8) | temp[1];
    val.P = temp[2];
    val.Y = (temp[3] << 8) | temp[4];
    val.X = (temp[5] << 8) | temp[6];
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
#pragma mark - Operator>> function for ScanHeader and ScanComponentParameter
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

    val.Ls = (temp[0] << 8) | temp[1];

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
#pragma mark - Operator>> function for QuantizationTable and QuantizationParameter
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

istream& operator>> (istream& s, QuantizationHeader& val) {

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

        if (i == -1) {
            cout << "istream Quantization header error" << endl;
            break;
        }
    }

    return s;
}

/*****************************************************************************************************/
//
// Operator>> function for HuffmanTable and HuffmanParameter
//
/*****************************************************************************************************/
#pragma mark - Operator>> function for HuffmanTable and HuffmanParameter
istream& operator>> (istream& s, HuffmanParameter& val) {

    // Use an unsigned char to tempily store data which need to compute later
    unsigned char temp;

    s >> temp;

    val.Tc = temp >> 4;
    val.Th = temp & 0x0F;

    for (int i = 1; i < 17; i++)
        s >> val.Li[i];

    for (int i = 1; i < 17; i++)
        for(int j = 0; j < val.Li[i]; j++) {
            s >> temp;
            val.Vij.push_back(temp);
        }

    return s;
}

istream& operator>> (istream& s, HuffmanHeader& val) {

    // Use 2 unsigned char to tempily store data which need to compute later
    unsigned char temp[2];

    s >> temp[0] >> temp[1];

    val.Lh = (temp[0] << 8) | temp[1];

    // Get Huffman header's range
    long long int i = s.tellg();
    long long int end = i + val.Lh - 2;

    while (i < end) {
        HuffmanParameter parameter;
        s >> parameter;

        val.huffmanParameters.push_back(parameter);

        i = s.tellg();

        if (i == -1) {
            cout << "istream huffman header error" << endl;
            break;
        }
    }
    
    return s;
}

/*****************************************************************************************************/
//
// Operator>> function for ArithmeticTable and ArithmeticParameter
//
/*****************************************************************************************************/
#pragma mark - Operator>> function for ArithmeticTable and ArithmeticParameter
istream& operator>> (istream& s, ArithmeticParameter& val) {

    // Use an unsigned char to tempily store data which need to compute later
    unsigned char temp;

    s >> temp;

    val.Tc = temp >> 4;
    val.Tb = temp & 0x0F;

    s >> val.Cs;

    return s;
}

istream& operator>> (istream& s, ArithmeticTable& val) {

    // Use 2 unsigned char to tempily store data which need to compute later
    unsigned char temp[2];

    s >> temp[0] >> temp[1];

    val.La = (temp[0] << 8) | temp[1];

    // Get Arithmetic Table's range
    long long int i = s.tellg();
    long long int end = i + val.La - 2;

    while (i < end) {
        ArithmeticParameter arithmeticParameter;
        s >> arithmeticParameter;

        val.arithmeticParameters.push_back(arithmeticParameter);

        i = s.tellg();
    }
    
    return s;
}

/*****************************************************************************************************/
//
// Operator>> function for RestartInterval
//
/*****************************************************************************************************/
#pragma mark - Operator>> function for RestartInterval
istream& operator>> (istream& s, RestartInterval& val) {

    // Use 2 unsigned char to tempily store data which need to compute later
    unsigned char temp[2];

    s >> temp[0] >> temp[1];

    val.Lr = (temp[0] << 8) | temp[1];

    s >> temp[0] >> temp[1];

    val.Ri = (temp[0] << 8) | temp[1];
    
    return s;
}

/*****************************************************************************************************/
//
// Operator>> function for CommentSegment
//
/*****************************************************************************************************/
#pragma mark - Operator>> function for CommentSegment
istream& operator>> (istream& s, CommentSegment& val) {

    // Use 2 unsigned char to tempily store data which need to compute later
    unsigned char temp[2];

    s >> temp[0] >> temp[1];

    val.Lc = (temp[0] << 8) | temp[1];

    // Get CommentSegment's range
    long long int i = s.tellg();
    long long int end = i + val.Lc - 2;

    while (i < end) {
        s >> temp[0];

        val.Cmi.push_back(temp[0]);

        i = s.tellg();
    }

    return s;
}

/*****************************************************************************************************/
//
// Operator>> function for Application
//
/*****************************************************************************************************/
#pragma mark - Operator>> function for Application
istream& operator>> (istream& s, Application& val) {

    // Use 2 unsigned char to tempily store data which need to compute later
    unsigned char temp[2];

    s >> temp[0] >> temp[1];

    val.Lp = (temp[0] << 8) | temp[1];

    // Get Application's range
    long long int i = s.tellg();
    long long int end = i + val.Lp - 2;

    while (i < end) {
        s >> temp[0];

        val.Api.push_back(temp[0]);

        i = s.tellg();
    }
    
    
    return s;
}

/*****************************************************************************************************/
//
// Operator>> function for DefineNumberOfLine
//
/*****************************************************************************************************/
#pragma mark - Operator>> function for DefineNumberOfLine
istream& operator>> (istream& s, DefineNumberOfLine& val) {

    unsigned char temp[2];

    s >> temp[0] >> temp[1];

    val.Ld = (temp[0] << 8) | temp[1];

    s >> temp[0] >> temp[1];

    val.NL = (temp[0] << 8) | temp[1];
    
    return s;
}
