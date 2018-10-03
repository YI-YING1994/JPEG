#include "huffman.h"

/*****************************************************************************************************/
// C1 procedure
// Input BITS list
// Output HUFFSIZE table
//
/*****************************************************************************************************/
void generateSizeTable(unsigned char BITS[17], int HUFFSIZE[256]) {
    int k = 0;
    int i = 1, j = 1;
    
    do {
        while (!(j > BITS[i])) {
            HUFFSIZE[k] = i;
            k++;
            j++;
        }
        i++;
        j = 1;
    } while (!(i > 16));
}

/*****************************************************************************************************/
// C2 procedure
// Input HUFFSIZE table
// Output HUFFCODE
//
/*****************************************************************************************************/

void generateCodeTable(int HUFFSIZE[256], int HUFFCODE[256]) {
    int k = 0;
    int iCode = 0;
    int iSi = HUFFSIZE[0];

    while (true) {
        do {
            HUFFCODE[k] = iCode;
            iCode++;
            k++;
        } while (HUFFSIZE[k] == iSi);
    
        if (HUFFSIZE[k] == 0)
            break;

        do {
            iCode = iCode << 1;
            iSi++;
        } while (HUFFSIZE[k] != iSi);
    }

}

/*****************************************************************************************************/
// C3 procedure
// Input HUFFSIZE, HUFFCODE, HUFFVAL, LASTK
// Output EHUFCO, EHUFSI
//
/*****************************************************************************************************/

void generateEHUFFCODEandEHUFFSIZE(int HUFFSIZE[256], int HUFFCODE[256],
                                   vector<unsigned char> &HUFFVAL, int EHUFFCODE[256], int EHUFFSIZE[256]) {
    int i;
    int k = 0;
    int iLask = (int)HUFFVAL.size();
        do {
            i = HUFFVAL[k];
            EHUFFCODE[i] = HUFFCODE[k];
            EHUFFSIZE[i] = HUFFSIZE[k];
            k++;
        } while (k < iLask);
}

string transformValueToCodeWord(int code, int size) {
    string sCodeWord = "";

    for (size -= 1; size >= 0; size--)
        sCodeWord += to_string((code >> size) & 0x1);

    return sCodeWord;
}

/*****************************************************************************************************/
// Construct huffman tree
// Input EHUFFSIZE, EHUFFCODEBIT
// Output huffman tree
/*****************************************************************************************************/
HuffmanTreeNode* constructHuffmanTree(int EHUFFSIZE[256], int EHUFFCODEBIT[256][16]) {
    int iCodeLength;
    HuffmanTreeNode *huffmanTable = new HuffmanTreeNode();
    HuffmanTreeNode *htnCurrentNode;

    for (int k = 0;k < 256; k++){
        iCodeLength = EHUFFSIZE[k];
        if (iCodeLength != 0) {
            htnCurrentNode = huffmanTable;

            for (int i = 0; i < iCodeLength; i++) {
                if (EHUFFCODEBIT[k][i] == 0) {
                    if (htnCurrentNode->htnZeroSubtree == NULL) {
                        htnCurrentNode->htnZeroSubtree = new HuffmanTreeNode();
                    }
                    htnCurrentNode = htnCurrentNode->htnZeroSubtree;
                }
                else {
                    if (htnCurrentNode->htnOneSubtree == NULL) {
                        htnCurrentNode->htnOneSubtree = new HuffmanTreeNode();
                    }
                    htnCurrentNode = htnCurrentNode->htnOneSubtree;
                }
            }
            htnCurrentNode->iCategory = k;
        }
    }
    return huffmanTable;
}
