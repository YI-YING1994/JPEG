#include <iostream>

using namespace std;

int iBITS[] = {0, 0, 0, 7, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0};
int iHUFFVAL[] = {0x4, 0x5, 0x3, 0x2, 0x6, 0x1, 0x0, 0x7, 0x8, 0x9, 0xA, 0xB};

// Input BITS list
// Output HUFFSIZE table
int generateSizeTable(int *BITS, int *HUFFSIZE) {
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

    return k;
}

// Input HUFFSIZE table
// Output HUFFCODE
void generateCodeTable(int *HUFFSIZE, int *HUFFCODE) {
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

void generateEHUFCOandEHUFSI(int *HUFFSIZE, int *HUFFCODE, int *HUFFVAL, int *EHUFCO, int *EHUFSI,
 int LASTK) {

    int i;
    int k = 0;

    do {
        i = HUFFVAL[k];
        
        EHUFCO[i] = HUFFCODE[k];
        EHUFSI[i] = HUFFSIZE[k];

        k++;
    } while (k < LASTK);
}

int main() {
    int iHuffSizeCount = 0;
    
    for (int i = 0; i < 17; i++)
        iHuffSizeCount += iBITS[i];
    
    int *iHUFFSIZE = new int[iHuffSizeCount];
    
    int iLASTK = generateSizeTable(iBITS, iHUFFSIZE);
    
    int *iHUFFCODE = new int[iHuffSizeCount];

    generateCodeTable(iHUFFSIZE, iHUFFCODE);
        

    int *iEHUFCO = new int[iHuffSizeCount];
    int *iEHUFSI = new int[iHuffSizeCount];

    generateEHUFCOandEHUFSI(iHUFFSIZE, iHUFFCODE, iHUFFVAL, iEHUFCO, iEHUFSI, iLASTK);

    cout << "HUFFSIZE: ";
    for (int i = 0; i < iHuffSizeCount; i++)
        cout << iHUFFSIZE[i] << " ";

    cout << endl;

    cout << "HUFFCODE: ";
    for (int i = 0; i < iHuffSizeCount; i++)
        cout << iHUFFCODE[i] << " ";

    cout << endl;
    
    cout << "EHUFCO: ";
    for (int i = 0; i < iHuffSizeCount; i++)
        cout << iEHUFCO[i] << " ";

    cout << endl;

    cout << "EHUFSI: ";
    for (int i = 0; i < iHuffSizeCount; i++)
        cout << iEHUFSI[i] << " ";
 
    cout << endl;

    cout << "LASTK: " << iLASTK << endl;
    
    delete[] iHUFFSIZE, iHUFFCODE, iEHUFCO, iEHUFSI;
    
    return 0;
}


