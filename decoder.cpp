#include <iostream>

using namespace std;
int iBits[] = {0, 0, 0, 7, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0};

void generateSizeTable(int* iHuffSize) {
    int k = 0;
    int i = 1, j = 1;
    
    do {
        while (!(j > iBits[i])) {
            iHuffSize[k] = i;
            k++;
            j++;
        }
        i++;
        j = 1;
    } while (!(i > 16));
}


void generateCodeTable(
int main() {
    int iHuffSize = 0;
    
    for (int i = 0; i < 17; i++)
        iHuffSize += iBits[i];
    
    int *iHUFFSIZE = new int[iHuffSize];
    
    generateSizeTable(iHUFFSIZE);
    
    for (int i = 0; i < iHuffSize; i++)
        cout << iHUFFSIZE[i] << endl;
        
    delete[] iHUFFSIZE;
    
    return 0;
}


