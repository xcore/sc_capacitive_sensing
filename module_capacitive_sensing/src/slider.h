// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

typedef enum {IDLE, PRESSED, LEFTING, RIGHTING, RELEASED, PRESSING} sliderstate;

typedef struct {
    int state;
    int lastTime;
    unsigned int base[8];
    unsigned int t[8];
    int coord;
    unsigned int lefts, rights, nomoves;
    int pressed;
} slider;

void sliderInit(slider & this, port cap, clock k);
sliderstate filterSlider(slider &this, port cap);

