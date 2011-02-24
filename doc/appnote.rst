
============================
Capacitive input on the XS-1
============================

Corin Rathbone, Henk Muller

Introduction
============

Capacitive sensing can detect the presence of somebody's finger near a
capacitor, and use that as an input mechanism to implement, for example, a
slider or a button.

The XCore XS1 processor requires little external hardware to implement cap
sensing: a resistor. A demo is on
http://www.youtube.com/watch?v=A5VPMJAM3tQ

As an example, capacitive enables the possibility of adding a
volume control slider on an iPod dock, input for a mixer on a USB-audio
device, or a touch sensitive button on a guitar dongle.

The current incarnation can support one button per bit of an 8-bit port,
and as single 50 MIPS thread can monitor all four 8-bit ports, limiting the
number of buttons to 32. The cost of a button is the cost of the PCB or FPC
plus the cost of a resistor, $ 0.01 per button plus the cost of PCB or FPC.


Principles
==========

The principle of touch sensing is that the capacitance of a capacitor can
be modified by putting objects near it; such as a finger. On an XCore
processor we can measure the capacitance by writing a program that charges
the capacitor, and then measure how long it takes to discharge through a
resistor. 

The schematics of this solution are shown below
together with an example capacitor layout:

image::schematics

The capacitor has a nominal value of 10-20 pF (depending on the precise
layout), and putting a finger near it will cause it to go up by 1 or 2 pF.
If we choose a resistor of 500 k$\Omega$ then the RC time for this circuit
(assuming 20 pF) is 500 * 10^3 * 20 * 10^-12 = 10 * 10^-6 seconds, or about
1000 clock ticks of the 100 Mhz reference clock; with a variation of up to
100 clock ticks when a finger is near the capacitor. The sequence of
charging and measuring is shown below:

image::voltage

The system will be subject to noise (in ground and power rail for example),
this noise can be filtered out by taking several measurements. If a digital
output is required, the algorithm can be given hysteresis.

The accuracy of the resistor and the capacitor and resistor may be important if
calibration is to be performed at design time. A 100 ppm per degree Celsius
resistor will be perfectly adequate (1\% over a 100 degree range), but the
resistor will have to be 1\% accurate. A 0.5\% resistor with a 25 ppm/C
temperature coefficient costs 1c in volume. This resistor will have a
0.75\% tolerance.

Hardware
========

There are two methods to create the capacitor, using PCB (Printed Circuit
Board) traces or using FPC (Flexible PCB traces). The innards of an Apple
mouse reveal an FPC:

image::photo-2.jpg

The video above uses PCB traces:

image::front.jpg

FPC traces may be easier to mount inside a case, whereas PCB traces reduce
manufacturing costs because they are part of the PCB and hence reduces the
number of components. In the case of the PCB above the only components
required are a few SMD resistors:

image::back.jpg


Software
========

The software to interpret the signal performs two functions: one is to
measure the time and hence the capacitor value, and the other function is
to interpret this value and take the noise out.

Measuring capacitance
---------------------

There are many ways to interface the capacitive sensor to an XCore;
affecting required operating frequency, number of ports being used, and the
MIPS being used. We describe two methods here: a simple method that uses a
single 1 bit port, and a parallel method that inputs up to 8 values in
parallel on an 8-bit port.

Using a 1-bit port
~~~~~~~~~~~~~~~~~~

When using a single 1-bit port, the method used is to declare an output
port, drive it high, measuring the time that it was driven high, and then
sampling it ``when pinseq(0)''. The difference in times is the time that it
took for the capacitor to discharge::

  #include <xs1.h>

  #define TIMEC  10

  port cap = XS1_PORT_1A;

  int measure1bit() {
    int t0, t1;
    cap <: 1 @ t0;                  // Set high, record time
    t0 += TIMEC;  
    cap @ t0 <: 1;                  // Keep high for 100 ns
    sync(t0);                       // Wait for port to complete
    cap when pinseq(0) :> void @ t1;// Measure when low
    return (t1-t0) & 0xffff;        // return discharge time
  }

This code has a minor deviation in time, in that between the
``sync()`` and the port switching to input there is a delay of
thread cycle or two.

Using an 8-bit port
~~~~~~~~~~~~~~~~~~~

Often 1-bit ports are in high demand, and often multiple sensors should be
measured simultaneously. An 8 bit port can be used to measure multiple
sensors simultaneously. In order to get high precision inputs on all
sensors, we make the port a buffering input port, and we input buffered
samples over a period of time (eg 10 us), whereafter we interpret the
measured data.


The code for this is more complex than the 1-bit code because we need to
store all samples in an array and interpret the data, and we also need to
reverse a buffered port (an operation that is not supported by hardware,
and involves a small bit of assembly to revert to an unbuffered port)::

    void measureNbit(port cap, unsigned int times[]) {
        int values[N];
        int curCaps, notSeen, curTime, newCaps, newBits;
        int t1, t0;
        int width = 8;
        int mask = 0xFF;
        
        asm("setc res[%0], 8" :: "r"(cap));            // reset port - for flipping around
        cap <: ~0 @ t0;
        t0 += 10;                                      // Charge for 10 clock ticks.
        cap @ t0 <: ~0;
        sync(cap);
        asm("setc res[%0], 8" :: "r"(cap));            // reset port
        asm("setc res[%0], 0x200f" :: "r"(cap));       // set to buffering
        asm("settw res[%0], %1" :: "r"(cap), "r"(32)); // and set transfer width to 32
        
        cap :> void;                                   // Drain first two values, and record time
        cap :> void @ t1;                              // Then record values; find changes later
    #pragma unsafe arrays
    #pragma loop unroll(4)
        for(int i = 0; i < N; i++) {                   // Record up to N values.
            cap :> values[i];                            // Too high a value of N costs memory and time
        }                                              // Low low a value of N will miss large caps
        notSeen = mask;                                // Caps that are not yet Low
        curCaps = mask;                                // Caps that are High
        curTime = (t1 - t0) & 0xffff;                  // Time of first measurement
        for(int i = 0; i < N && notSeen != 0; i++) {
            for(int k = 0; k < 32; k += width) {
                newCaps = (values[i]>>k) & mask;       // Extract measurement
                newBits = (curCaps^newCaps)&notSeen;   // Changed caps
                if (newBits != 0) {
                    for(int j = 0; j < width; j ++) {
                        if(((newBits >> j) & 1) != 0) {
                            times[j] = curTime;      // Record time for
                        }                          // each changed cap
                    }
                    notSeen &= ~ newBits;        // And remember that
                }                               // this cap is low
                curCaps = newCaps;
                curTime++;
            }
        }
    }
    

Interpreting data
-----------------

The measurement above returns an *analogue* value that represents the
total capacitance. It includes noise caused by, for example, the power
supply, and its values are subject to design variations in for example
resistor values.

The operations can be performed to improve the data:
1. Smoothing
1. Background level detection
1. Pulse generation
1. Hysteresis

Smoothing
~~~~~~~~~

Smoothing is the process of averaging a series of samples in order to
remove high frequency noise. The average can be taken over a window of
recent measurements, using a running average, or by taking a block of
measurements. 

A window of recent measurements requires memory to store past measurements,
but can return a high rate of measurements. A running average will return a
high rate, but will pass more high frequency noise. A block measurement
will have a lower measurement rate, but will not require a lot of memory.

After smoothing, the data can be used as analogue data (to drive, for
example, a musical instrument), or it can be discretised to, for example,
``PRESSED'' and ``NOT PRESSED'' values.


Background level
~~~~~~~~~~~~~~~~

The background level is the value of the capacitor when it is not touched.
It can be established when switching the system on, or on-the-fly. On the
fly is preferable since there is no guarantee that the capacitor is at
background level on start up.

On-the-fly background level measurements take a running average over a
prolonged period of time, and measure the minimum over this period as a
measurement for the background level. The time over which the measurement
is taken limits the amount of time that a button can be pressed
continuously.

When the background level is determined, a rise of more than a set number
constitute an ``ON'' and a drop by more than a set amount will constitute an
``OFF''. By choosing the ON level to be higher than the OFF level hysteresis
is created that will avoid hesitation between ON and OFF.

Pulse generation
~~~~~~~~~~~~~~~~

Pulse generation avoids measuring the background level by generating a
``Press'' and ``Unpress'' event every time that the level has gone up by
more than a set amount; and it never generates these events within a set
time frame.

This method cannot be used to create ``Repeat'' events such as used for a
``Volume UP'' button where a prolonged press will cause the volume to go
up further.

Special button interpretation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Special shaped buttons, such as a slider, can be made noise free by
recognising specific motions only, such as slide-up and slide-down. It
takes measurements from multiple sensors in order to disambiguate the signal.

Limitations
===========

It is important to understand the limitations of this design. It is not
clear at present whether this system is robust enough to be rolled out in
volume design. One would expect a difference due to differences in distance between
the capacitor and the casing, differences in thickness of the casing, etc.
