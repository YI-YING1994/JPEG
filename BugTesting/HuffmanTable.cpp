#include <iostream>
#include <string>
#include <fstream>
#include <math.h>
using namespace std;

unsigned char ucBITS[17];// = {0, 0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 125};
int iHUFFSIZE[256] = {0};
int iHUFFCODE[256] = {0};
unsigned char ucHUFFVAL[256]; /*{0x1, 0x2, 0x3, 0x0, 0x4, 0x11, 0x5, 0x12, 0x21, 0x31, 0x41, 0x6, 0x13, 0x51, 0x61, 0x7,
                                0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x8, 0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1,
                                0xf0, 0x24, 0x33, 0x62, 0x72, 0x82, 0x9, 0xa, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x25, 0x26,
                                0x27, 0x28, 0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x43, 0x44, 0x45, 0x46,
                                0x47, 0x48, 0x49, 0x4a, 0x};*/
int iEHUFFCODE[256];
int iEHUFFSIZE[256];
int iEHUFFCODEBIT[256][16];

struct HuffmanTreeNode {
    int iCategory;
    int iID;
    HuffmanTreeNode *htnZeroSubtree;
    HuffmanTreeNode *htnOneSubtree;
    HuffmanTreeNode(int category = -1, HuffmanTreeNode *zero = NULL, HuffmanTreeNode *one = NULL): iCategory(category), htnZeroSubtree(zero), htnOneSubtree(one) { };
    ~HuffmanTreeNode() { delete htnZeroSubtree; delete htnOneSubtree; }
};
HuffmanTreeNode *htnHuffmanTreeRoot[2][2];
HuffmanTreeNode *htnCurrentNode;

template <typename T>
struct Queue {
private:
    T data;
    Queue *front, *rear;
    Queue *Next;

public:
    Queue(T element = NULL): data(element), front(NULL), rear(NULL), Next(NULL) { }

    void AddQueue(T element) {
        if (front == NULL) { rear = new Queue(element); front = rear; return; }
        rear->Next = new Queue(element);
        rear = rear->Next;
    }

    T deleteQueue() {
        T temp = NULL;
        if (front == NULL) { cout << "Queue is empty" << endl; return temp; }
        temp = front->data;
        Queue *p = front;
        front = p->Next;
        delete p;

        return temp;
    }
    bool IsEmpty() { return (front == NULL); }
};

void HuffmanHeaderHandler(fstream &fs);
void ShowHuffmanTable();
HuffmanTreeNode* ConstructHuffmanTree(int *size, int codebit[256][16]);
void TraversalTreeNode(HuffmanTreeNode *node);

int main(){
    int iPtr;
    char cTemp;
    int iTc, iTh;
    string sFileName;
    cin >> sFileName;

    fstream fs;
    fs.open(sFileName, fstream::in | fstream::out | fstream::binary);
    fs.unsetf(fstream::skipws);

    while (cin >> iPtr) {
        fs.seekg(iPtr);
        fs >> cTemp;
        iTc = (cTemp >> 4);
        iTh = (cTemp & 0xF);
        HuffmanHeaderHandler(fs);
        ShowHuffmanTable();

        htnHuffmanTreeRoot[iTc][iTh] = ConstructHuffmanTree(iEHUFFSIZE, iEHUFFCODEBIT);
        TraversalTreeNode(htnHuffmanTreeRoot[iTc][iTh]);
        cout << endl;
    }

	return 0;
} 
void HuffmanHeaderHandler(fstream &fs) {
    // C1: Generation of table of Huffman code sizes
    for (int i = 1; i < 17; i++) fs >> ucBITS[i]; // fin BITS
    int k = 0;
    int iLASTK;
    for (int i = 1 ; i < 17 ; i++){
        for (int j = 0; j < ucBITS[i]; j++){
            iHUFFSIZE[k] = i;
            k++;
        }
    }
    iHUFFSIZE[k] = 0;
    iLASTK = k;

    // C2: Generation of table of Huffman codes
    for (int i = 0; i < iLASTK; i++) fs >> ucHUFFVAL[i]; // fin HUFFVAL
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

    // C3: Generates the Huffman codes in symbol value order
    for (k=0;k < iLASTK;k++){
        int i = (int)ucHUFFVAL[k];

        iEHUFFCODE[i]=iHUFFCODE[k];
        iEHUFFSIZE[i]=iHUFFSIZE[k];
    }

    for (int k = 0;k < 256; k++){
        int iCodeLength = iEHUFFSIZE[k];
        int iCodeValue = iEHUFFCODE[k];
        for (int i= iCodeLength-1; i >= 0; i--){
            iEHUFFCODEBIT[k][i] = iCodeValue % 2;
            iCodeValue = iCodeValue / 2;
        }
    }
}

void ShowHuffmanTable() {
    for (int k = 0;k < 256; k++){
        int iCodeLength = iEHUFFSIZE[k];
        int iCodeValue = iEHUFFCODE[k];
        if (iCodeLength != 0) {
            printf("%X\t", k);
            for (int i = 0; i < iCodeLength; i++) cout << iEHUFFCODEBIT[k][i];
            cout << endl;
        }
    }
}

HuffmanTreeNode* ConstructHuffmanTree(int *size, int codebit[256][16]) {
    int iCodeLength;
    HuffmanTreeNode *huffmanTable = new HuffmanTreeNode();
    huffmanTable->iID = 1;

    for (int k = 0;k < 256; k++){
        iCodeLength = size[k];
        if (iCodeLength != 0) {
            htnCurrentNode = huffmanTable;

            for (int i = 0; i < iCodeLength; i++) {
                if (codebit[k][i] == 0) {
                    if (htnCurrentNode->htnZeroSubtree == NULL) {
                        htnCurrentNode->htnZeroSubtree = new HuffmanTreeNode();
                        htnCurrentNode->htnZeroSubtree->iID = 2 * htnCurrentNode->iID;
                    }
                    htnCurrentNode = htnCurrentNode->htnZeroSubtree;
                }
                else {
                    if (htnCurrentNode->htnOneSubtree == NULL) {
                        htnCurrentNode->htnOneSubtree = new HuffmanTreeNode();
                        htnCurrentNode->htnOneSubtree->iID = 2 * htnCurrentNode->iID + 1;
                    }
                    htnCurrentNode = htnCurrentNode->htnOneSubtree;
                }
            }
            htnCurrentNode->iCategory = k;
        }
    }
    return huffmanTable;
}

void TraversalTreeNode(HuffmanTreeNode *node) {
    int iID;
    int iDepth = 0;
    HuffmanTreeNode *temp;
    Queue<HuffmanTreeNode*> q;
    q.AddQueue(node);

    while (!q.IsEmpty()) {
        temp = q.deleteQueue();
        iID = temp->iID;

        if (iDepth < (int)log2(iID)) { iDepth++; cout << endl; }
        cout << iID << " ";

        if (temp->htnZeroSubtree != NULL) q.AddQueue(temp->htnZeroSubtree);
        if (temp->htnOneSubtree != NULL) q.AddQueue(temp->htnOneSubtree);
    }

}
