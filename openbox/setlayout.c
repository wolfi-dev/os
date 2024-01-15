/* To compile this program, run
 * gcc -o setlayout setlayout.c -lX11
 */
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>

/* orientation of pager */
#define _NET_WM_ORIENTATION_HORZ 0
#define _NET_WM_ORIENTATION_VERT 1

/* starting corner for counting spaces */
#define _NET_WM_TOPLEFT     0
#define _NET_WM_TOPRIGHT    1
#define _NET_WM_BOTTOMRIGHT 2
#define _NET_WM_BOTTOMLEFT  3

int main(int argc, char *argv[]) {
  unsigned long data[4];
  Display *display;
  int screen;
  Window root;

  if (argc < 4) {
    printf("pls, you need to give 4 numbers to me.\n"
           "The first is layout, 0 is horizontal and 1 is vertical.\n"
           "Second and third is number of desks horizontally and vertically.\n"
           "The last is starting corner, 0 = topleft, 1 = topright,\n"
           "                             2 = bottomright, 3 = bottomleft.\n");
    return 1;
  }

  data[0] = atoi(argv[1]); //_NET_WM_ORIENTATION_HORZ;
  data[1] = atoi(argv[2]);
  data[2] = atoi(argv[3]);
  data[3] = atoi(argv[4]); //_NET_WM_TOPLEFT;

  display = XOpenDisplay(NULL);
  screen = DefaultScreen(display);
  root = RootWindow(display, screen);

  XChangeProperty(display, root,
                  XInternAtom(display, "_NET_DESKTOP_LAYOUT", False),
                  XA_CARDINAL, 32, PropModeReplace, (unsigned char *)&data, 4);

  XFlush(display);
  XCloseDisplay(display);

  return 0;
}
