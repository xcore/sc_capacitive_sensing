#include <xs1.h>
#include "slider.h"
#include "capsens.h"

static int abs(int x) {
    return x < 0 ? -x : x;
}


void sliderInit(slider & this, port cap, clock k) {
    timer tt;
    this.state = IDLE;
    tt :> this.lastTime;
    this.coord = 0;
    this.nomoves = this.lefts = this.rights = 0;
    this.pressed = 0;
    setupNbit(cap, k);
    measureAverage(cap, this.base);
}

sliderstate filterSlider(slider &this, port cap) {
    int avg = 0, n = 0;
    int coord;
    unsigned time, timePassed;
    timer tt;
    int minoffset = 999;

    tt :> time;
    timePassed = time - this.lastTime;
    measureAverage(cap, this.t);
    for(int k = 0; k < 8; k++) {
        int offset = ((int)(this.t[k]-this.base[k])) >> 10;
        if (offset < minoffset) {
            minoffset = offset;
        }
      //  printf(" %6d", offset);
    }
//    printf("\n");
    for(int k = 0; k < 8; k++) {
        int offset = (((int)(this.t[k]-this.base[k])) >> 10) - minoffset;
        unsigned int h, l, correctionSpeed;
        avg = avg + k * offset;
        n += offset;
        if (this.base[k] > this.t[k]) {
            correctionSpeed = 7;        // Lower sample found - adapt quickly
        } else {
            correctionSpeed = 13;       // Higher sample found - adapt slowly
        }                               // compute base = ((2^cs - 1) * base + t) 2^-cs
        {h,l} = mac( (1<<correctionSpeed) - 1, this.base[k], 0, this.t[k]);
        this.base[k] = h << (32-correctionSpeed) | l >> correctionSpeed;
    }
    if (this.pressed) {
        if (n < 75) {
            this.pressed = 0;
        }
    } else {
        if (n > 150) {
            this.pressed = 1;
        }
    }
    coord = this.pressed ? 10000*avg/n : 0;
    switch (this.state) {
    case IDLE:
        if (this.pressed) {
            this.state = PRESSING;
            this.lastTime = time;
            this.coord = coord;
            this.nomoves = this.lefts = this.rights = 0;
        }
        break;
    case PRESSING:
        if (timePassed > 500000 && this.pressed) {
            int ms = timePassed / 100000;
            int speed = (coord - this.coord)*100/ms;
            if (speed > 5000) {
                this.rights++;
            } else if (speed < -5000) {
                this.lefts++;
            } else {
                this.nomoves++;
            }
            this.lastTime = time;
            this.coord = coord;
//            if (this.lefts + this.rights + this.nomoves > 15) {
            if (this.nomoves > this.lefts+3 && this.nomoves > this.rights+3 || abs(this.lefts - this.rights) < 3 && (this.lefts+this.rights) > 15) {
                    this.state = PRESSED;
                    return PRESSED;
                }
                if (this.rights > this.lefts + this.nomoves + 5) {
                    this.state = LEFTING;
                    return LEFTING;
                }
                if (this.lefts > this.rights + this.nomoves + 5) {
                    this.state = RIGHTING;
                    return RIGHTING;
                }
/*                this.state = PRESSED;
                xscope_probe_data(3, coord);
                return PRESSED;
            }*/
        } else if (timePassed > 20000000 && !this.pressed) {
            this.state = IDLE;
        }
        break;
    case PRESSED:
        if (!this.pressed && (time - this.lastTime) > 10000000) {
            this.state = IDLE;
            this.lastTime = time;
            return RELEASED;
        }
        break;
    case RELEASED:
    case LEFTING:
    case RIGHTING:
        if (!this.pressed && (time - this.lastTime) > 10000000) {
            this.state = IDLE;
            this.lastTime = time;
        }
        break;
    }
    return IDLE;
}
