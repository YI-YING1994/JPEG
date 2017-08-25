//
//  huffman.h
//  JPEG
//
//  Created by MCUCSIE on 8/23/17.
//  Copyright © 2017 MCUCSIE. All rights reserved.
//

/*****************************************************************************************************/
// Input BITS list
// Output HUFFSIZE table
template <typename T1, typename T2>
int generateSizeTable(T1 BITS, T2 HUFFSIZE);

/*****************************************************************************************************/
// Input HUFFSIZE table
// Output HUFFCODE
template <typename T1, typename T2>
void generateCodeTable(T1 HUFFSIZE, T2 HUFFCODE);

/*****************************************************************************************************/
// Input HUFFSIZE, HUFFCODE, HUFFVAL, LASTK
// Output EHUFCO, EHUFSI
template <typename T1, typename T2, typename T3, typename T4,  typename T5>
void generateEHUFCOandEHUFSI(T1 HUFFSIZE, T2 HUFFCODE, T3 HUFFVAL, T4 EHUFCO, T5 EHUFVAL,
                             int LASTK);
/*****************************************************************************************************/

#include "huffman.cpp"
