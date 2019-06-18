//
//  huffman.h
//  JPEG
//
//  Created by MCUCSIE on 8/23/17.
//  Copyright © 2017 MCUCSIE. All rights reserved.
//
#include <iostream>
#include <algorithm>
#include <string>
#include <vector>
using namespace std;

/*****************************************************************************************************/
#pragma mark - Huffman Tree Node
struct HuffmanTreeNode {
    int iCategory;
    HuffmanTreeNode *htnZeroSubtree;
    HuffmanTreeNode *htnOneSubtree;
    HuffmanTreeNode(int category = -1, HuffmanTreeNode *zero = NULL, HuffmanTreeNode *one = NULL): iCategory(category), htnZeroSubtree(zero), htnOneSubtree(one) { };
    ~HuffmanTreeNode() { delete htnZeroSubtree; delete htnOneSubtree; }
};

/*****************************************************************************************************/
// C1 procedure
// Input BITS list
// Output HUFFSIZE table
void generateSizeTable(unsigned char BITS[17], int HUFFSIZE[256]);

/*****************************************************************************************************/
// C2 procedure
// Input HUFFSIZE table
// Output HUFFCODE
void generateCodeTable(int HUFFSIZE[256], int HUFFCODE[256]);

/*****************************************************************************************************/
// C3 procedure
// Input HUFFSIZE, HUFFCODE, HUFFVAL, LASTK
// Output EHUFCO, EHUFSI
void generateEHUFFCODEandEHUFFSIZE(int HUFFSIZE[256], int HUFFCODE[256], vector<unsigned char> &HUFFVAL,
                                   int EHUFFCODE[256], int EHUFFSIZE[256]);

string transformValueToCodeWord(int code, int size);

/*****************************************************************************************************/
// Construct huffman tree
// Input EHUFFSIZE, EHUFFCODEBIT
// Output huffman tree

HuffmanTreeNode* constructHuffmanTree(int EHUFFSIZE[256], int EHUFFCODEBIT[256][16]);

/*****************************************************************************************************/
