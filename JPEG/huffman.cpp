/*****************************************************************************************************/
//
// Input BITS list
// Output HUFFSIZE table
//
/*****************************************************************************************************/
template <typename T1, typename T2>
int generateSizeTable(T1 BITS, T2 HUFFSIZE) {
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

/*****************************************************************************************************/
//
// Input HUFFSIZE table
// Output HUFFCODE
//
/*****************************************************************************************************/

template <typename T1, typename T2>
void generateCodeTable(T1 HUFFSIZE, T2 HUFFCODE) {
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
//
// Input HUFFSIZE, HUFFCODE, HUFFVAL, LASTK
// Output EHUFCO, EHUFSI
//
/*****************************************************************************************************/

template <typename T1, typename T2, typename T3, typename T4,  typename T5>
void generateEHUFCOandEHUFSI(T1 HUFFSIZE, T2 HUFFCODE, T3 HUFFVAL, T4 EHUFCO, T5 EHUFVAL,
                             int LASTK) {

    int i;
    int k = 0;

    do {
        // Value stores in HUFFVAL is directly the category, not the postion.
        i = (HUFFVAL[k] >> 4) * 10 + (HUFFVAL[k] & 0x0F);
        if ((HUFFVAL[k] >> 4) == 0x0F)
            i++;

        EHUFCO[i] = HUFFCODE[k];
        EHUFVAL[i] = HUFFVAL[k];

        k++;
    } while (k < LASTK);
}
