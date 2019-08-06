//  JPEG
//
//  Created by MacLaptop on 2019/6/25.
//  Copyright © 2019 MCUCSIE. All rights reserved.
//

#include <iostream>

struct Qvu {
    int iValue;
    int iOriginPosition;
    void operator=(const int value) {
        this->iValue = value;
    }
};

void GetSteganPriority(int data[64], int iSteganPriority[64]);
