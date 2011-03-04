// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

void setupNbit(port cap, clock k);
void measureNbit(port cap, unsigned int times[], int pullDown);
void measureAverage(port cap, unsigned int avg[8], int pullDown);

