#ifndef EDITOR_BRIDGE_H
#define EDITOR_BRIDGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum Editor_Event_Kind {
    CHAR_INPUT = 0,
    KEY_LEFT = 1,
    KEY_RIGHT = 2,
    KEY_UP = 3,
    KEY_DOWN = 4,
    KEY_HOME = 5,
    KEY_END = 6,
    KEY_PAGE_UP = 7,
    KEY_PAGE_DOWN = 8,
    KEY_BACKSPACE = 9,
    KEY_DELETE = 10,
    KEY_UNDO = 11,
    KEY_REDO = 12,
    KEY_SAVE = 13,
    MOUSE_DOWN = 14,
    MOUSE_DRAG = 15,
    SELECT_WORD = 16,
    SELECT_LINE = 17,
    ADD_CARET = 18,
    CLEAR_EXTRA_CARETS = 19,
    OPEN_COMMAND_PALETTE = 20,
    MOUSE_MOVE = 21,
    KEY_TAB = 22,
    KEY_F2 = 23,
    KEY_F3 = 24,
    MOUSE_WHEEL = 25
} Editor_Event_Kind;

typedef struct Platform_Event {
    int kind;
    uint32_t ch;
    int shift;
    int ctrl;
    int alt;
    int x;
    int y;
    int wheel_x;
    int wheel_y;
} Platform_Event;


/*
 * Render layer ABI values.  These values must match
 * Editor.Render_Layers.To_C in Ada.
 *
 * The Vulkan backend validates these values before drawing and then
 * renders by numeric layer order, not packet append order.
 */
typedef enum Render_Layer {
    LAYER_BACKGROUND = 0,
    LAYER_TAB_BAR_BACKGROUND = 1,
    LAYER_TAB_BAR_TAB = 2,
    LAYER_TAB_BAR_DIRTY = 3,
    LAYER_TAB_BAR_CLOSE = 4,
    LAYER_TAB_BAR_TEXT = 5,
    LAYER_FILE_TREE_BACKGROUND = 6,
    LAYER_FILE_TREE_ROW_HIGHLIGHT = 7,
    LAYER_FILE_TREE_INDENT_GUIDE = 8,
    LAYER_FILE_TREE_TEXT = 9,
    LAYER_FILE_TREE_SEPARATOR = 10,
    LAYER_FILE_TREE_SPLITTER = 11,
    LAYER_GUTTER_BACKGROUND = 12,
    LAYER_CURRENT_LINE = 13,
    LAYER_ACTIVE_FIND_MATCH = 14,
    LAYER_SELECTION = 15,
    LAYER_GUTTER_SEPARATOR = 16,
    LAYER_GUTTER_TEXT = 17,
    LAYER_GUTTER_MARKER = 18,
    LAYER_GUTTER_MARKER_HOVER = 19,
    LAYER_FOLD_MARKER = 20,
    LAYER_DIAGNOSTIC = 21,
    LAYER_TEXT = 22,
    LAYER_CARET = 23,
    LAYER_MINIMAP_BACKGROUND = 24,
    LAYER_MINIMAP_CONTENT = 25,
    LAYER_MINIMAP_VIEWPORT = 26,
    LAYER_SCROLLBAR_TRACK = 27,
    LAYER_SCROLLBAR_THUMB = 28,
    LAYER_PROBLEMS_BACKGROUND = 29,
    LAYER_PROBLEMS_HEADER = 30,
    LAYER_PROBLEMS_ROW = 31,
    LAYER_PROBLEMS_SEVERITY = 32,
    LAYER_PROBLEMS_TEXT = 33,
    LAYER_STATUS_BAR_BACKGROUND = 34,
    LAYER_STATUS_BAR_TEXT = 35,
    LAYER_ACTIVE_FIND_PROMPT_BACKGROUND = 36,
    LAYER_ACTIVE_FIND_PROMPT_FIELD = 37,
    LAYER_ACTIVE_FIND_PROMPT_BUTTON = 38,
    LAYER_ACTIVE_FIND_PROMPT_TEXT = 39,
    LAYER_ACTIVE_FIND_PROMPT_CARET = 40,
    LAYER_SEMANTIC_POPUP_BACKGROUND = 41,
    LAYER_SEMANTIC_POPUP_ROW = 42,
    LAYER_SEMANTIC_POPUP_TEXT = 43,
    LAYER_QUICK_OPEN_BACKGROUND = 44,
    LAYER_QUICK_OPEN_FIELD = 45,
    LAYER_QUICK_OPEN_RESULT = 46,
    LAYER_QUICK_OPEN_SELECTED_RESULT = 47,
    LAYER_QUICK_OPEN_TEXT = 48,
    LAYER_QUICK_OPEN_CARET = 49,
    LAYER_PROJECT_SEARCH_BAR_BACKGROUND = 50,
    LAYER_PROJECT_SEARCH_BAR_FIELD = 51,
    LAYER_PROJECT_SEARCH_BAR_BUTTON = 52,
    LAYER_PROJECT_SEARCH_BAR_TEXT = 53,
    LAYER_PROJECT_SEARCH_BAR_CARET = 54,
    LAYER_PENDING_TRANSITION_BACKGROUND = 55,
    LAYER_PENDING_TRANSITION_TEXT = 56,
    LAYER_PENDING_TRANSITION_ACTION = 57,
    LAYER_MESSAGE_BACKGROUND = 58,
    LAYER_MESSAGE_TEXT = 59,
    LAYER_PALETTE_BACKGROUND = 60,
    LAYER_PALETTE_SELECTION = 61,
    LAYER_PALETTE_TEXT = 62,

    LAYER_FIRST = LAYER_BACKGROUND,
    LAYER_LAST = LAYER_PALETTE_TEXT
} Render_Layer;

typedef struct Rect_Command {
    int layer;
    float x;
    float y;
    float w;
    float h;
    float r;
    float g;
    float b;
} Rect_Command;

typedef struct Glyph_Command {
    int layer;
    float x;
    float y;
    float w;
    float h;
    float u0;
    float v0;
    float u1;
    float v1;
    float r;
    float g;
    float b;
} Glyph_Command;

enum {
    MAX_RECTANGLES = 8192,
    MAX_GLYPHS = 8192
};

typedef struct Render_Packet {
    int rect_count;
    int glyph_count;
    Rect_Command rects[MAX_RECTANGLES];
    Glyph_Command glyphs[MAX_GLYPHS];
} Render_Packet;

void editor_init(void);
void editor_open_project_path(const char *path);
void editor_handle_platform_event(Platform_Event ev);
int  editor_should_quit(void);
void editor_set_viewport_size(int w, int h);
void editor_set_time_seconds(double t);
void editor_tick(void);
void editor_get_render_packet(Render_Packet *packet);

#ifdef __cplusplus
}
#endif

#endif
