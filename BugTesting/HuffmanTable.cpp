#include <iostream>
#include <fstream>
using namespace std;

int iBITS[17] = {0, 0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 125};
int iHUFFSIZE[256] = {0};
int iHUFFCODE[256] = {0};
unsigned char ucHUFFVAL[256]; /*{0x1, 0x2, 0x3, 0x0, 0x4, 0x11, 0x5, 0x12, 0x21, 0x31, 0x41, 0x6, 0x13, 0x51, 0x61, 0x7,
                                0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x8, 0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1,
                                0xf0, 0x24, 0x33, 0x62, 0x72, 0x82, 0x9, 0xa, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x25, 0x26,
                                0x27, 0x28, 0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x43, 0x44, 0x45, 0x46,
                                0x47, 0x48, 0x49, 0x4a, 0x};*/

int main(){
	
	
    int k = 0;
    int iLASTK;
    for (int i = 1 ; i < 17 ; i++){
        for (int j = 0; j < iBITS[i]; j++){
            iHUFFSIZE[k] = i;
            k++;
        }
    }
    iHUFFSIZE[k] = 0;
    iLASTK = k;


    k=0;
    int iCODE = 0;
    int iSI = iHUFFSIZE[0];
    do {
    	do {
    		iHUFFCODE[k] = iCODE;
    		iCODE++;
    		k++;
    	}
    	while (iHUFFSIZE[k] == iSI);
    
    	if (iHUFFSIZE[k]!=0){
    		do {
    			iCODE = iCODE << 1;
    			iSI++;
    		}
    		while (iHUFFSIZE[k] != iSI);    		
    	}
    }
    while (iHUFFSIZE[k] != 0);

   	fstream fs;
	fs.open("3x3.jpg", fstream::in | fstream::out | fstream::binary);
	fs.unsetf(fstream::skipws);
    fs.seekg(75);
    
    for (int i = 0; i < iLASTK; i++){
        if (fs.tellg() == -1) {
            cout << "something error at " << i << endl;
            break;
        }
        fs >> ucHUFFVAL[i];
    }

    int *iEHUFCO = new int[iLASTK];
    int *iEHUFSI = new int[iLASTK];
    for (k=0;k < iLASTK;k++){
        int i = (ucHUFFVAL[k] >> 4) * 10 + (ucHUFFVAL[k] & 0x0F);
        if ((ucHUFFVAL[k] >> 4) == 0x0F)
            i++;

        iEHUFCO[i]=iHUFFCODE[k];
        iEHUFSI[i]=iHUFFSIZE[k];
    }

    
    int **iEHUFCOB = new int*[iLASTK];
    for (int i = 0; i < iLASTK; i++)
        iEHUFCOB[i] = new int[16];
    
    for (int k = 0;k < iLASTK; k++){
        int iCodeLength = iEHUFSI[k];
        int iCodeValue = iEHUFCO[k];
        for (int i= iCodeLength-1; i >= 0; i--){
            iEHUFCOB[k][i] = iCodeValue % 2;
            iCodeValue = iCodeValue / 2;
        }
    }
    
    for (int k = 0;k < iLASTK; k++){
        int iCodeLength = iEHUFSI[k];
        int iCodeValue = iEHUFCO[k];
        for (int i= 0;i< iCodeLength;i++){
            cout << iEHUFCOB[k][i];
        }
        cout << endl;
    }

	return 0;
} 
