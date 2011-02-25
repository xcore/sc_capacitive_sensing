Capacitive Sensing
..................

:Version: 
  unreleased

:Status:
  Proof of concept

:Maintainer:
  henkmuller



This repository has functions for capacitive sensing, and for interpreting
capacitive sensing data. At present they are all in a single module, with
an example app.

Pictures of the board are in the docs directory.
A video is on http://www.youtube.com/watch?v=A5VPMJAM3tQ



Key Features
============

   * measurement of raw data
   * smoothing of data, automatic background level detection
   * recognition of motion on a slider

To Do
=====

   * 

Firmware Overview
=================

* module_capacitive_sensing: module that implements capacitive sensing functions

* app_example_capsens: Example application for an XK-1 that requires cap
  sense hardware to be attached to the northern connector (not the one next
  to the power supply)

Hardware schematics and other documentation to be added soon.

Known Issues
============

none

Required Repositories
=====================

   * xcommon git\@github.com:xmos/xcommon.git

Support
=======

Issues may be submitted via the Issues tab in this github repo. Response to any issues submitted as at the discretion of the maintainer for this line.


