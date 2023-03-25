#include <gdk/gdkx.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include "xdo.h"

// Imitate screenshot_backend_x11_get_pixbuf in
// https://gitlab.gnome.org/GNOME/gnome-screenshot/-/blob/master/src/screenshot-backend-x11.c
static GdkPixbuf* get_root_screenshot(GdkWindow* root) {
  GdkRectangle extent;
  gdk_window_get_frame_extents(root, &extent);
  GdkPixbuf* screenshot = gdk_pixbuf_get_from_window(root, 0, 0, extent.width, extent.height);
  if (screenshot == NULL)
    return NULL;

  // Include the mouse pointer.
  // TODO: Use the actual mouse pointer, e.g. in an editor.
  g_autoptr(GdkCursor) pointer = gdk_cursor_new_for_display(gdk_display_get_default(), GDK_LEFT_PTR);
  g_autoptr(GdkPixbuf) pointer_pixbuf = gdk_cursor_get_image(pointer);

  if (pointer_pixbuf != NULL) {
    GdkSeat* seat = gdk_display_get_default_seat(gdk_display_get_default());
    GdkDevice* device = gdk_seat_get_pointer(seat);

    gint cx, cy;
    gdk_window_get_device_position(root, device, &cx, &cy, NULL);

    gint xhot, yhot;
    sscanf(gdk_pixbuf_get_option(pointer_pixbuf, "x_hot"), "%d", &xhot);
    sscanf(gdk_pixbuf_get_option(pointer_pixbuf, "y_hot"), "%d", &yhot);

    // In rect we have the mouse pointer window coordinates.
    GdkRectangle rect;
    rect.x = cx - xhot;
    rect.y = cy - yhot;
    rect.width = gdk_pixbuf_get_width(pointer_pixbuf);
    rect.height = gdk_pixbuf_get_height(pointer_pixbuf);

    // See if the mouse pointer is inside the window.
    GdkRectangle intersection;
    if (gdk_rectangle_intersect (&extent, &rect, &intersection)) {
      // Use the intersection so that we don't go outside the screenshot.
      gdk_pixbuf_composite(pointer_pixbuf, screenshot,
        intersection.x, intersection.y,
        intersection.width, intersection.height,
        rect.x, rect.y,
        1.0, 1.0, GDK_INTERP_BILINEAR, 255);
    }
  }

  return screenshot;
}

static void process_screenshot(GdkPixbuf* screenshot) {
  int n_channels = gdk_pixbuf_get_n_channels(screenshot);
  int width = gdk_pixbuf_get_width(screenshot);
  int height = gdk_pixbuf_get_height(screenshot);
  int rowstride = gdk_pixbuf_get_rowstride(screenshot);
  guchar *pixels = gdk_pixbuf_get_pixels(screenshot);

  u_int64_t reds = 0, greens = 0, blues = 0;
  for (int y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      guchar *pixel = pixels + y * rowstride + x * n_channels;
      reds += pixel[0];
      greens += pixel[1];
      blues += pixel[2];
    }
  }

  printf("Debug total RGB %lu %lu %lu\n", reds, greens, blues);
}

int main(__attribute__((unused)) int argc, __attribute__((unused)) char **argv) {
  gdk_init(0, NULL);

  GdkWindow* root = gdk_get_default_root_window();
  if (root == NULL) {
    fprintf(stderr, "Failed to get root window.\n");
    return 1;
  }

  xdo_t *xdo = xdo_new(NULL);
  if (xdo == NULL) {
    fprintf(stderr, "Failed creating new xdo instance.\n");
    return 1;
  }

  g_autoptr (GdkPixbuf) screenshot = get_root_screenshot(root);
  if (screenshot == NULL) {
    fprintf(stderr, "Failed to get screenshot.\n");
    return 1;
  }

  process_screenshot(screenshot);

  int ret = xdo_move_mouse_relative(xdo, 100, 100);

  xdo_free(xdo);

  return ret;
}
