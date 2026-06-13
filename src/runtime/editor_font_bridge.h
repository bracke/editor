#ifndef EDITOR_FONT_BRIDGE_H
#define EDITOR_FONT_BRIDGE_H

const unsigned char *editor_font_atlas_pixels(void);
int editor_font_atlas_width(void);
int editor_font_atlas_height(void);

int editor_font_atlas_dirty(void);
void editor_font_clear_atlas_dirty(void);

#endif