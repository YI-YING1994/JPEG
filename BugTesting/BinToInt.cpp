#include <iostream>
#include <string>
using namespace std;
int iS[2][12] = {{0, -1, -3, -7, -15, -31, -63, -127, -255, -511, -1023, -2047},
                 {0,  1,  2,  4,   8,  16,  32,   64,  128,  256,   512,  1024}};
int main() {
    int iClass;
    int iDec;
    string sBin;

    while (cin >> iClass >> sBin) {
        iDec = 0;
        for (int i = 1; i < sBin.size(); i++)
            iDec = iDec * 2 + sBin[i] - '0';
        cout << iS[sBin[0]-'0'][iClass] << " " << iDec << endl;
    }
    
    return 0;
}
