#include <iostream>
#include <string>
#include <fstream>

using namespace std;

int main() {
    string s;
    cin >> s;

    fstream fs1,fs2;

    if (s == "DHT")
        fs1.open("DHT/Answer.txt", fstream::in);

    else if (s == "DQT")
        fs1.open("DQT/Answer.txt", fstream::in);

    else if (s == "SOF")
        fs1.open("SOF/Answer.txt", fstream::in);

    else if (s == "SOS")
        fs1.open("SOS/Answer.txt", fstream::in);

    cout << fs1.tellg() << endl;

    fs2.open("Comparison.txt", fstream::in);

    int i, j;
    bool bIsCorrect = true;

    while (fs1 >> i && fs2 >> j) {
        if (i != j) {
            bIsCorrect = false;
            break;
        }

    }

    if (bIsCorrect && fs1.tellg() == -1 && fs2.tellg() == -1)
        cout << "right answer!" << endl;
    else
        cout << "wrong answer!" << endl;

    return 0;
}
