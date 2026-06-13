#ifndef PLATFORM_DRAW_H
#define PLATFORM_DRAW_H

void platform_begin_frame(int width, int height);
void platform_end_frame(void);

void draw_rect(int x, int y, int w, int h);
void draw_line(int x0, int y0, int x1, int y1);
void draw_text(int x, int y, const char *text);

#endif