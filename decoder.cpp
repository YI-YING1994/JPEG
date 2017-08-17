#include <iostream>

using namespace std;
int iBit[] = {0, 0, 0, 7, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0};

// Input BITS list
// Output HUFFSIZE table
void generateSizeTable(int *BITS, int *HUFFSIZE) {
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

int main() {
    int iHuffSizeCount = 0;
    
    for (int i = 0; i < 17; i++)
        iHuffSizeCount += iBit[i];
    
    int *iHUFFSIZE = new int[iHuffSizeCount];
    
    generateSizeTable(iBit, iHUFFSIZE);
    
    int *iHUFFCODE = new int[iHuffSizeCount];

    generateCodeTable(iHUFFSIZE, iHUFFCODE);
        
    for (int i = 0; i < iHuffSizeCount; i++)
        cout << iHUFFCODE[i] << endl;
 
    delete[] iHUFFSIZE, iHUFFCODE;
    
    return 0;
}


