//  JPEG
//
//  Created by MacLaptop on 2019/6/25.
//  Copyright © 2019 MCUCSIE. All rights reserved.
//

#include "SteganPriority.h"
using namespace std;

bool cmp(const Qvu &v1, const Qvu &v2) {
    if (v1.iValue < v2.iValue) return true;
    return false;
}

void GetSteganPriority(int data[64], int iSteganPriority[64]) {
    Qvu temp[64];
    for (int i = 0; i < 64; i++) {
        temp[i].iOriginPosition = i;
        temp[i] = data[i];
    }
    sort(temp + 1, temp + 64, cmp);
    
    int iCurrentQvu = -1;
    int iOrderCount = -1;
    iSteganPriority[0] = -1;
    for (int i = 1; i < 64; i++) {
        if (iCurrentQvu != temp[i].iValue) {
            iCurrentQvu = temp[i].iValue;
            iOrderCount++;
        }
        iSteganPriority[temp[i].iOriginPosition] = iOrderCount;
    }
}
