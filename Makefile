WARNFLAGS+=-pedantic -Wall -W -Wundef \
           -Wendif-labels -Wshadow -Wpointer-arith \
           -Wcast-align -Wwrite-strings \
           -Winline \
           -Wdisabled-optimization -Wno-missing-field-initializers

CFLAGS?=-pipe -O2 $(WARNFLAGS)
CFLAGS+=$(CPPFLAGS)

INC=-I$(XDOTOOL_DIR) -I/usr/X11R6/include -I/usr/local/include -I/usr/include/gtk-3.0 -I/usr/include/glib-2.0 \
  -I/usr/lib/x86_64-linux-gnu/glib-2.0/include -I/usr/include/cairo -I/usr/include/pango-1.0 \
  -I/usr/include/harfbuzz -I/usr/include/gdk-pixbuf-2.0
CFLAGS+=$(INC) 

.PHONY: all
all: xaera

.PHONY: clean
clean:
	rm -f *.o xaera

xaera.o: xaera.cpp
	$(CC) $(CFLAGS) -c xaera.cpp

xaera: LDFLAGS+=-lxdo -lstdc++ -Xlinker -lgdk-3 -lgdk_pixbuf-2.0 -lgobject-2.0
xaera: xaera.o
	$(CC) -o $@ xaera.o $(LDFLAGS)
