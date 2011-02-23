#include <stdio.h>
#include <capsens.h>

//port leds = XS1_PORT_4F;
port cap8 = XS1_PORT_8B;

clock clk1 = XS1_CLKBLK_1;

main() {
    slider x;
    int ov = 0;
    timer t;
    sliderInit(x, cap8, clk1);
    while(1) {
        int v = filterSlider(x);
        if (v != ov) {
            switch (v) {
            case 1:
                printstr("Press\n");
                break;
            case 2:
                printstr("Left\n");
                break;
            case 3:
                printstr("Right\n");
                break;
            case 4:
                printstr("Release\n");
                break;
            }
            ov = v;
        }
    }
}
