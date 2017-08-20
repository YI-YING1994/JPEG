/*****************************************************************************************************/
// 
// Generate HUFFMAN Tables
//
/*****************************************************************************************************/

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

// Input HUFFSIZE, HUFFCODE, HUFFVAL, LASTK
// Output EHUFCO, EHUFSI
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
