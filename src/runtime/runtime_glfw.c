#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <GLFW/glfw3.h>

#include "editor_bridge.h"
#include "runtime_glfw.h"
#include "render_backend.h"

/* ============================================================ */
/* Globals                                                      */
/* ============================================================ */

static GLFWwindow *g_window = NULL;
static int g_left_mouse_down = 0;
static int g_drag_shift = 0;
static int g_drag_ctrl = 0;
static int g_drag_alt = 0;

static double g_last_click_time = -1.0;
static int g_last_click_x = 0;
static int g_last_click_y = 0;
static int g_click_count = 0;

/* ============================================================ */
/* Helpers                                                      */
/* ============================================================ */

static void decode_modifiers(int mods,
                             int *shift,
                             int *ctrl,
                             int *alt)
{
    *shift = (mods & GLFW_MOD_SHIFT) != 0;
    *ctrl  = (mods & GLFW_MOD_CONTROL) != 0;
    *alt   = (mods & GLFW_MOD_ALT) != 0;
}

/* ============================================================ */
/* Callbacks                                                    */
/* ============================================================ */

static void cursor_position_callback(GLFWwindow *window,
                                     double xpos,
                                     double ypos)
{
    Platform_Event ev;

    memset(&ev, 0, sizeof ev);

    (void)window;

    ev.kind = g_left_mouse_down ? MOUSE_DRAG : MOUSE_MOVE;
    ev.ch = 0;

    if (g_left_mouse_down) {
        ev.shift = g_drag_shift;
        ev.ctrl = g_drag_ctrl;
        ev.alt = g_drag_alt;
    } else {
        ev.shift = 0;
        ev.ctrl = 0;
        ev.alt = 0;
    }

    ev.x = (int)xpos;
    ev.y = (int)ypos;

    editor_handle_platform_event(ev);
}

static void key_callback(GLFWwindow *window,
                         int key,
                         int scancode,
                         int action,
                         int mods)
{
    Platform_Event ev;

    memset(&ev, 0, sizeof ev);

    (void)window;
    (void)scancode;

    if (action != GLFW_PRESS && action != GLFW_REPEAT) {
        return;
    }

    ev.ch = 0;
    decode_modifiers(mods, &ev.shift, &ev.ctrl, &ev.alt);

    ev.x = 0;
    ev.y = 0;

    switch (key) {
        case GLFW_KEY_ENTER:
        case GLFW_KEY_KP_ENTER:
            ev.kind = CHAR_INPUT;
            ev.ch = '\n';
            break;

        case GLFW_KEY_LEFT:
            ev.kind = KEY_LEFT;
            break;

        case GLFW_KEY_RIGHT:
            ev.kind = KEY_RIGHT;
            break;

        case GLFW_KEY_UP:
            ev.kind = KEY_UP;
            break;

        case GLFW_KEY_DOWN:
            ev.kind = KEY_DOWN;
            break;

        case GLFW_KEY_HOME:
            ev.kind = KEY_HOME;
            break;

        case GLFW_KEY_END:
            ev.kind = KEY_END;
            break;

        case GLFW_KEY_PAGE_UP:
            ev.kind = KEY_PAGE_UP;
            break;

        case GLFW_KEY_PAGE_DOWN:
            ev.kind = KEY_PAGE_DOWN;
            break;

        case GLFW_KEY_BACKSPACE:
            ev.kind = KEY_BACKSPACE;
            break;

        case GLFW_KEY_TAB:
            if (mods & GLFW_MOD_CONTROL) {
                ev.kind = KEY_TAB;
            } else {
                return;
            }
            break;

        case GLFW_KEY_DELETE:
            ev.kind = KEY_DELETE;
            break;

        case GLFW_KEY_F2:
            ev.kind = KEY_F2;
            break;

        case GLFW_KEY_F3:
            ev.kind = KEY_F3;
            break;

        case GLFW_KEY_Z:
            if (mods & GLFW_MOD_CONTROL) {
                ev.kind = (mods & GLFW_MOD_SHIFT) ? KEY_REDO : KEY_UNDO;
            } else {
                return;
            }
            break;

        case GLFW_KEY_Y:
            if (mods & GLFW_MOD_CONTROL) {
                ev.kind = KEY_REDO;
            } else {
                return;
            }
            break;

        case GLFW_KEY_S:
            if (mods & GLFW_MOD_CONTROL) {
                ev.kind = KEY_SAVE;
            } else {
                return;
            }
            break;

        case GLFW_KEY_F:
            if (mods & GLFW_MOD_CONTROL) {
                ev.kind = CHAR_INPUT;
                ev.ch = 'f';
            } else {
                return;
            }
            break;

        case GLFW_KEY_H:
            if (mods & GLFW_MOD_CONTROL) {
                ev.kind = CHAR_INPUT;
                ev.ch = 'h';
            } else {
                return;
            }
            break;

        case GLFW_KEY_P:
            if (mods & GLFW_MOD_CONTROL) {
                ev.kind = OPEN_COMMAND_PALETTE;
            } else {
                return;
            }
            break;

        case GLFW_KEY_ESCAPE:
            ev.kind = CLEAR_EXTRA_CARETS;
            break;

        default:
            return;
    }

    editor_handle_platform_event(ev);
}

static void char_callback(GLFWwindow *window,
                          unsigned int codepoint)
{
    Platform_Event ev;

    memset(&ev, 0, sizeof ev);

    (void)window;

    ev.kind = CHAR_INPUT;
    ev.ch = codepoint;
    ev.shift = 0;
    ev.ctrl = 0;
    ev.alt = 0;

    ev.x = 0;
    ev.y = 0;

    editor_handle_platform_event(ev);
}

static void mouse_button_callback(GLFWwindow *window,
                                  int button,
                                  int action,
                                  int mods)
{
    double x = 0.0;
    double y = 0.0;
    Platform_Event ev;

    memset(&ev, 0, sizeof ev);

    if (button != GLFW_MOUSE_BUTTON_LEFT) {
        return;
    }

    glfwGetCursorPos(window, &x, &y);

    if (action == GLFW_PRESS) {
        int ix = (int)x;
        int iy = (int)y;
        double now = glfwGetTime();
        int close_to_last = abs(ix - g_last_click_x) <= 3
                         && abs(iy - g_last_click_y) <= 3;

        g_left_mouse_down = 1;

        decode_modifiers(mods, &ev.shift, &ev.ctrl, &ev.alt);
        g_drag_shift = ev.shift;
        g_drag_ctrl = ev.ctrl;
        g_drag_alt = ev.alt;

        if (g_last_click_time >= 0.0
            && now - g_last_click_time <= 0.50
            && close_to_last) {
            g_click_count += 1;
        } else {
            g_click_count = 1;
        }

        g_last_click_time = now;
        g_last_click_x = ix;
        g_last_click_y = iy;

        if (ev.alt && !ev.shift) {
            ev.kind = ADD_CARET;
        } else if (!ev.shift && g_click_count >= 3) {
            ev.kind = SELECT_LINE;
            g_click_count = 0;
        } else if (!ev.shift && g_click_count == 2) {
            ev.kind = SELECT_WORD;
        } else {
            ev.kind = MOUSE_DOWN;
        }

        ev.ch = 0;
        ev.x = ix;
        ev.y = iy;

        editor_handle_platform_event(ev);
    }
    else if (action == GLFW_RELEASE) {
        g_left_mouse_down = 0;
        g_drag_shift = 0;
        g_drag_ctrl = 0;
        g_drag_alt = 0;
    }
}


static void scroll_callback(GLFWwindow *window,
                            double xoffset,
                            double yoffset)
{
    double x = 0.0;
    double y = 0.0;
    Platform_Event ev;

    memset(&ev, 0, sizeof ev);
    glfwGetCursorPos(window, &x, &y);

    ev.kind = MOUSE_WHEEL;
    ev.x = (int)x;
    ev.y = (int)y;
    ev.wheel_x = (int)xoffset;
    ev.wheel_y = (int)yoffset;

    editor_handle_platform_event(ev);
}


static void framebuffer_size_callback(GLFWwindow *window, int width, int height)
{
    RenderBackend *backend = (RenderBackend *)glfwGetWindowUserPointer(window);

    (void)width;
    (void)height;

    render_backend_request_swapchain_recreate(backend);
}

static void runtime_smoke_prime_text(void)
{
    static const char smoke_text[] = "procedure Smoke is begin null; end; -- runtime smoke";

    for (size_t i = 0; smoke_text[i] != '\0'; ++i) {
        Platform_Event ev;
        memset(&ev, 0, sizeof ev);
        ev.kind = CHAR_INPUT;
        ev.ch = (unsigned char)smoke_text[i];
        editor_handle_platform_event(ev);
    }
}

/* ============================================================ */
/* Main runtime                                                 */
/* ============================================================ */

int runtime_glfw_run_with_options(const RuntimeGlfwOptions *options)
{
    int smoke_mode = options && options->smoke_mode;
    int smoke_max_frames = options ? options->smoke_max_frames : 0;
    int smoke_resize = options && options->smoke_resize;
    int smoke_zero_framebuffer = options && options->smoke_zero_framebuffer;
    int smoke_visual_contract = options && options->smoke_visual_contract;
    int smoke_max_seconds = (options && options->smoke_max_seconds > 0)
                            ? options->smoke_max_seconds
                            : 30;
    double smoke_start_time = 0.0;
    unsigned smoke_visual_min_rects = (options && options->smoke_visual_min_rects > 0u)
                                      ? options->smoke_visual_min_rects
                                      : 1u;
    unsigned smoke_visual_min_glyphs = (options && options->smoke_visual_min_glyphs > 0u)
                                       ? options->smoke_visual_min_glyphs
                                       : 1u;
    unsigned smoke_visual_first_rect_count = 0u;
    unsigned smoke_visual_first_glyph_count = 0u;
    uint32_t smoke_visual_first_geometry_checksum = 0u;
    uint32_t smoke_visual_first_color_checksum = 0u;
    int smoke_visual_contract_observed = 0;
    int smoke_resize_count = (options && options->smoke_resize_count > 0)
                             ? options->smoke_resize_count
                             : (smoke_resize ? 1 : 0);
    int smoke_resize_requests = 0;
    int smoke_zero_framebuffer_checked = 0;
    unsigned smoke_zero_framebuffer_recreate_baseline = 0;
    unsigned smoke_recreate_baseline = 0;
    unsigned smoke_atlas_upload_baseline = 0;
    unsigned smoke_first_atlas_upload_count = 0;
    int smoke_frames_after_first_atlas_upload = 0;
    int smoke_redundant_atlas_upload = 0;
    unsigned smoke_atlas_min_nonzero_bytes = (options && options->smoke_atlas_min_nonzero_bytes > 0u)
                                             ? options->smoke_atlas_min_nonzero_bytes
                                             : 32u;
    unsigned smoke_first_atlas_width = 0u;
    unsigned smoke_first_atlas_height = 0u;
    unsigned smoke_first_atlas_nonzero_bytes = 0u;
    uint32_t smoke_first_atlas_checksum = 0u;
    int smoke_atlas_metadata_changed_after_cache_hit = 0;
    int rendered_frames = 0;
    int loop_iterations = 0;
    int max_iterations;

    if (smoke_mode && smoke_resize && smoke_resize_count <= 0) {
        smoke_resize_count = 1;
    }

    if (smoke_mode && smoke_max_frames <= 0) {
        smoke_max_frames = smoke_resize ? smoke_resize_count + 3 : 3;
    }

    if (smoke_mode && smoke_resize && smoke_max_frames <= smoke_resize_count + 1) {
        smoke_max_frames = smoke_resize_count + 3;
    }

    if (smoke_mode && smoke_zero_framebuffer && smoke_max_frames <= smoke_resize_count + 3) {
        smoke_max_frames = smoke_resize_count + 5;
    }

    if (smoke_mode && smoke_visual_contract && smoke_max_frames < 5) {
        smoke_max_frames = 5;
    }

    max_iterations = smoke_mode ? smoke_max_frames * 20 + 60 : 0;

    if (!glfwInit()) {
        fprintf(stderr, "runtime error: GLFW init failed\n");
        return 1;
    }

    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    if (smoke_mode) {
        glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
    }

    g_window = glfwCreateWindow(800, 600, "Editor", NULL, NULL);
    if (!g_window) {
        fprintf(stderr, "runtime error: GLFW window creation failed\n");
        glfwTerminate();
        return 1;
    }

    glfwSetKeyCallback(g_window, key_callback);
    glfwSetCharCallback(g_window, char_callback);
    glfwSetMouseButtonCallback(g_window, mouse_button_callback);
    glfwSetCursorPosCallback(g_window, cursor_position_callback);
    glfwSetScrollCallback(g_window, scroll_callback);
    glfwSetFramebufferSizeCallback(g_window, framebuffer_size_callback);

    editor_init();
    if (smoke_mode) {
        runtime_smoke_prime_text();
    }

    RenderBackend *backend = render_backend_create(g_window);

    if (!backend) {
        fprintf(stderr, "runtime error: Vulkan render backend creation failed\n");
        glfwDestroyWindow(g_window);
        glfwTerminate();
        return 1;
    }

    glfwSetWindowUserPointer(g_window, backend);
    smoke_recreate_baseline = render_backend_swapchain_recreate_count(backend);
    smoke_atlas_upload_baseline = render_backend_font_atlas_upload_count(backend);
    smoke_start_time = smoke_mode ? glfwGetTime() : 0.0;

    while (!glfwWindowShouldClose(g_window)) {

        glfwPollEvents();

        if (editor_should_quit()) {
            glfwSetWindowShouldClose(g_window, GLFW_TRUE);
        }

        int width = 0;
        int height = 0;
        glfwGetFramebufferSize(g_window, &width, &height);

        if (smoke_mode) {
            double smoke_elapsed = glfwGetTime() - smoke_start_time;

            if (smoke_elapsed > (double)smoke_max_seconds) {
                fprintf(stderr,
                        "runtime smoke error: exceeded internal smoke timeout before requested frames completed\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            loop_iterations += 1;
            if (loop_iterations > max_iterations) {
                fprintf(stderr,
                        "runtime smoke error: exceeded bounded loop without rendering requested frames\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }
        }

        if (width <= 0 || height <= 0) {
            if (smoke_mode) {
                glfwPollEvents();
            } else {
                glfwWaitEvents();
            }
            continue;
        }

        if (smoke_mode && smoke_zero_framebuffer &&
            !smoke_zero_framebuffer_checked &&
            rendered_frames >= 1) {
            smoke_zero_framebuffer_recreate_baseline =
                render_backend_swapchain_recreate_count(backend);

            if (!render_backend_begin_frame(backend, 0, 0) ||
                !render_backend_draw_editor(backend) ||
                !render_backend_end_frame(backend)) {
                fprintf(stderr, "runtime smoke error: zero-framebuffer skip path failed\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            if (render_backend_frame_was_rendered(backend)) {
                fprintf(stderr, "runtime smoke error: zero-framebuffer skip path counted as a rendered frame\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            smoke_zero_framebuffer_checked = 1;
            glfwSetWindowSize(g_window, 800, 600);
            glfwPollEvents();
            continue;
        }

        editor_set_viewport_size(width, height);

        double now = glfwGetTime();
        editor_set_time_seconds(now);
        editor_tick();

        if (smoke_mode && smoke_resize &&
            smoke_resize_requests < smoke_resize_count &&
            rendered_frames >= smoke_resize_requests + 1) {
            static const int smoke_sizes[][2] = {
                {640, 480},
                {960, 540},
                {320, 240},
                {800, 600}
            };
            int size_index = smoke_resize_requests %
                (int)(sizeof smoke_sizes / sizeof smoke_sizes[0]);

            glfwSetWindowSize(g_window,
                              smoke_sizes[size_index][0],
                              smoke_sizes[size_index][1]);
            render_backend_request_swapchain_recreate(backend);
            smoke_resize_requests += 1;
        }

        if (!render_backend_begin_frame(backend, width, height) ||
            !render_backend_draw_editor(backend) ||
            !render_backend_end_frame(backend)) {
            fprintf(stderr, "runtime error: render frame failed\n");
            render_backend_destroy(backend);
            glfwDestroyWindow(g_window);
            glfwTerminate();
            return 1;
        }

        if (render_backend_frame_was_rendered(backend)) {
            unsigned current_atlas_uploads = render_backend_font_atlas_upload_count(backend);

            rendered_frames += 1;

            if (smoke_mode && smoke_visual_contract) {
                unsigned rect_count = render_backend_last_visual_rect_count(backend);
                unsigned glyph_count = render_backend_last_visual_glyph_count(backend);
                uint32_t geometry_checksum = render_backend_last_visual_geometry_checksum(backend);
                uint32_t color_checksum = render_backend_last_visual_color_checksum(backend);

                if (!smoke_visual_contract_observed ||
                    (rect_count >= smoke_visual_min_rects &&
                     glyph_count >= smoke_visual_min_glyphs &&
                     geometry_checksum != 0u &&
                     color_checksum != 0u)) {
                    smoke_visual_first_rect_count = rect_count;
                    smoke_visual_first_glyph_count = glyph_count;
                    smoke_visual_first_geometry_checksum = geometry_checksum;
                    smoke_visual_first_color_checksum = color_checksum;
                    smoke_visual_contract_observed = 1;
                }
            }

            if (smoke_mode && current_atlas_uploads > smoke_atlas_upload_baseline) {
                if (smoke_first_atlas_upload_count == 0u) {
                    smoke_first_atlas_upload_count = current_atlas_uploads;
                    smoke_first_atlas_width = render_backend_font_atlas_last_upload_width(backend);
                    smoke_first_atlas_height = render_backend_font_atlas_last_upload_height(backend);
                    smoke_first_atlas_nonzero_bytes = render_backend_font_atlas_last_upload_nonzero_bytes(backend);
                    smoke_first_atlas_checksum = render_backend_font_atlas_last_upload_checksum(backend);
                    smoke_frames_after_first_atlas_upload = 0;
                } else if (current_atlas_uploads != smoke_first_atlas_upload_count) {
                    smoke_redundant_atlas_upload = 1;
                } else {
                    if (render_backend_font_atlas_last_upload_width(backend) != smoke_first_atlas_width ||
                        render_backend_font_atlas_last_upload_height(backend) != smoke_first_atlas_height ||
                        render_backend_font_atlas_last_upload_nonzero_bytes(backend) != smoke_first_atlas_nonzero_bytes ||
                        render_backend_font_atlas_last_upload_checksum(backend) != smoke_first_atlas_checksum) {
                        smoke_atlas_metadata_changed_after_cache_hit = 1;
                    }
                    smoke_frames_after_first_atlas_upload += 1;
                }
            }
        }

        if (smoke_mode && rendered_frames >= smoke_max_frames) {
            if (smoke_visual_contract) {
                if (!smoke_visual_contract_observed) {
                    fprintf(stderr, "runtime smoke error: visual contract metrics were not observed on a rendered frame\n");
                    render_backend_destroy(backend);
                    glfwDestroyWindow(g_window);
                    glfwTerminate();
                    return 1;
                }

                if (smoke_visual_first_rect_count < smoke_visual_min_rects) {
                    fprintf(stderr, "runtime smoke error: visual contract recorded too few visible rectangle commands\n");
                    render_backend_destroy(backend);
                    glfwDestroyWindow(g_window);
                    glfwTerminate();
                    return 1;
                }

                if (smoke_visual_first_glyph_count < smoke_visual_min_glyphs) {
                    fprintf(stderr, "runtime smoke error: visual contract recorded too few visible glyph commands\n");
                    render_backend_destroy(backend);
                    glfwDestroyWindow(g_window);
                    glfwTerminate();
                    return 1;
                }

                if (smoke_visual_first_geometry_checksum == 0u ||
                    smoke_visual_first_color_checksum == 0u) {
                    fprintf(stderr, "runtime smoke error: visual contract checksums were not recorded\n");
                    render_backend_destroy(backend);
                    glfwDestroyWindow(g_window);
                    glfwTerminate();
                    return 1;
                }
            }

            if (render_backend_font_atlas_upload_count(backend) <= smoke_atlas_upload_baseline) {
                fprintf(stderr, "runtime smoke error: deterministic text did not trigger a font atlas upload\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            if (render_backend_font_atlas_last_upload_width(backend) == 0u ||
                render_backend_font_atlas_last_upload_height(backend) == 0u) {
                fprintf(stderr, "runtime smoke error: font atlas upload dimensions were not recorded\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            if (render_backend_font_atlas_last_upload_nonzero_bytes(backend) == 0u) {
                fprintf(stderr, "runtime smoke error: uploaded font atlas contained no rasterized glyph pixels\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            if (render_backend_font_atlas_last_upload_nonzero_bytes(backend) <
                    smoke_atlas_min_nonzero_bytes) {
                fprintf(stderr,
                        "runtime smoke error: font atlas upload had fewer non-zero bytes than the required deterministic text threshold\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            if (render_backend_font_atlas_last_upload_checksum(backend) == 0u) {
                fprintf(stderr, "runtime smoke error: font atlas upload checksum was not recorded\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            if (render_backend_font_atlas_dirty(backend)) {
                fprintf(stderr, "runtime smoke error: font atlas dirty flag remained set after upload\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            if (smoke_redundant_atlas_upload || smoke_frames_after_first_atlas_upload < 1) {
                fprintf(stderr, "runtime smoke error: font atlas upload did not reach a stable cache-hit frame after dirty upload\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            if (smoke_atlas_metadata_changed_after_cache_hit) {
                fprintf(stderr, "runtime smoke error: font atlas upload metadata changed during cache-hit stability frame\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            if (smoke_zero_framebuffer && !smoke_zero_framebuffer_checked) {
                fprintf(stderr, "runtime smoke error: zero-framebuffer transition was not exercised\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            if (smoke_zero_framebuffer &&
                render_backend_swapchain_recreate_count(backend) <=
                    smoke_zero_framebuffer_recreate_baseline) {
                fprintf(stderr, "runtime smoke error: zero-framebuffer restore did not recreate the swapchain\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            if (smoke_resize && smoke_resize_requests < smoke_resize_count) {
                fprintf(stderr, "runtime smoke error: requested resize sequence did not complete\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }

            if (smoke_resize &&
                render_backend_swapchain_recreate_count(backend) <
                    smoke_recreate_baseline +
                    (unsigned)smoke_resize_count +
                    (smoke_zero_framebuffer ? 1u : 0u)) {
                fprintf(stderr, "runtime smoke error: requested resize sequence did not recreate swapchain for every transition\n");
                render_backend_destroy(backend);
                glfwDestroyWindow(g_window);
                glfwTerminate();
                return 1;
            }
            glfwSetWindowShouldClose(g_window, GLFW_TRUE);
        }
    }

    render_backend_destroy(backend);

    glfwDestroyWindow(g_window);
    glfwTerminate();

    return 0;
}
int runtime_glfw_run(void)
{
    return runtime_glfw_run_with_options(NULL);
}
