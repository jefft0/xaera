# `xaera` - AERA I/O device for X11

`xaera` runs in X11 and allows an AERA I/O device to interact with the screen and control
the mouse and keyboard.

## Installation

This works with X11 (not Wayland). This has been tested on Ubuntu 20.04.

To install xdotool, in a terminal enter:

    cd
    git clone https://github.com/jordansissel/xdotool
    cd xdotool
    git checkout fd5cfdd55c87aab26531c4b6e8c3422c007ae742
    make
    sudo make install

To build xaera, in a terminal enter:

    cd
    git clone https://github.com/jefft0/xaera
    cd xaera
    make

