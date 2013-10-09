#include "absolute.h"

#include <xs1.h>
#include <stdio.h>
#include "capsens.h"

void absolute_slider_init(absolute_pos & this, port cap, clock k, int n_elements,
                          int threshold_press, int threshold_unpress) {
    this.n_elements = n_elements;
    this.pressed = 0;
    this.threshold_press = threshold_press;
    this.threshold_unpress = threshold_unpress;
    setupNbit(cap, k);
    measureAverage(cap, this.base);
    for(int k = 0; k < this.n_elements; k++) {
        this.base[k] >>= 1;
    }
}

int absolute_slider(absolute_pos &this, port cap) {
    int avg = 0, n = 0;
    int coord;
    int minoffset = 999;

    measureAverage(cap, this.t);
    for(int k = 0; k < this.n_elements; k++) {
        this.t[k] >>= 1;
    }
#if 0
    for(int k = 0; k < this.n_elements; k++) {
        int offset = this.t[k]-this.base[k];
        if (offset < minoffset) {
            minoffset = offset;
        }
    }
#endif
    for(int k = 0; k < this.n_elements; k++) {
        int offset = (this.t[k]-this.base[k]);// - minoffset;
        unsigned int h, l, correctionSpeed;
//            printf(" %8d ", this.t[k] - this.base[k]);
        avg = avg + k * offset;
        n += offset;
        if (this.base[k] > this.t[k]) {
            correctionSpeed = 10;        // Lower sample found - adapt quickly
        } else {
            correctionSpeed = 10;       // Higher sample found - adapt slowly
        }                               // compute base = ((2^cs - 1) * base + t) 2^-cs
        {h,l} = mac( (1<<correctionSpeed) - 1, this.base[k], 0, this.t[k]);
        this.base[k] = h << (32-correctionSpeed) | l >> correctionSpeed;
    }
    if (this.pressed) {
        if (n < this.threshold_unpress) {
            this.pressed = 0;
        }
    } else {
        if (n > this.threshold_press) {
            this.pressed = 1;
        }
    }
    coord = this.pressed ? ABSOLUTE_SLIDER_ELEMENT*avg/n : 0;
//    printf("%6d %d %8d %8d\n", coord, this.pressed, avg, n);
    return coord;
}
