#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "runtime_glfw.h"
#include "render_backend.h"

#ifdef __cplusplus
extern "C" {
#endif
void adainit(void);
void adafinal(void);
#ifdef __cplusplus
}
#endif

static void print_usage(const char *program)
{
    fprintf(stderr,
            "usage: %s [--runtime-smoke] [--runtime-smoke-frames=N] [--runtime-smoke-resize] [--runtime-smoke-resize-count=N] [--runtime-smoke-zero-framebuffer] [--runtime-smoke-visual-contract] [--runtime-smoke-visual-min-rects=N] [--runtime-smoke-visual-min-glyphs=N] [--runtime-smoke-atlas-min-nonzero=N] [--runtime-smoke-max-seconds=N] [--runtime-check-shaders]\n",
            program ? program : "editor_app");
}

static int parse_int_suffix(const char *text, int *out_value)
{
    char *end = NULL;
    long parsed;

    if (!text || !*text || !out_value) {
        return 0;
    }

    parsed = strtol(text, &end, 10);
    if (!end || *end != '\0' || parsed < 1 || parsed > 1000000) {
        return 0;
    }

    *out_value = (int)parsed;
    return 1;
}

int main(int argc, char **argv)
{
    RuntimeGlfwOptions options;
    int rc;
    int i;
    int check_shaders_only = 0;

    memset(&options, 0, sizeof options);
    options.smoke_max_frames = 0;
    options.smoke_atlas_min_nonzero_bytes = 32u;
    options.smoke_visual_min_rects = 1u;
    options.smoke_visual_min_glyphs = 1u;
    options.smoke_max_seconds = 30;

    for (i = 1; i < argc; ++i) {
        const char *arg = argv[i];

        if (strcmp(arg, "--runtime-check-shaders") == 0) {
            check_shaders_only = 1;
        } else if (strcmp(arg, "--runtime-smoke") == 0) {
            options.smoke_mode = 1;
            if (options.smoke_max_frames <= 0) {
                options.smoke_max_frames = 3;
            }
        } else if (strncmp(arg, "--runtime-smoke-frames=", 23) == 0) {
            options.smoke_mode = 1;
            if (!parse_int_suffix(arg + 23, &options.smoke_max_frames)) {
                fprintf(stderr, "invalid --runtime-smoke-frames value\n");
                print_usage(argv[0]);
                return 2;
            }
        } else if (strcmp(arg, "--runtime-smoke-resize") == 0) {
            options.smoke_mode = 1;
            options.smoke_resize = 1;
            if (options.smoke_resize_count <= 0) {
                options.smoke_resize_count = 1;
            }
            if (options.smoke_max_frames <= 0) {
                options.smoke_max_frames = 4;
            }
        } else if (strcmp(arg, "--runtime-smoke-zero-framebuffer") == 0) {
            options.smoke_mode = 1;
            options.smoke_zero_framebuffer = 1;
            if (options.smoke_max_frames <= 0) {
                options.smoke_max_frames = 5;
            }
        } else if (strcmp(arg, "--runtime-smoke-visual-contract") == 0) {
            options.smoke_mode = 1;
            options.smoke_visual_contract = 1;
            if (options.smoke_max_frames <= 0) {
                options.smoke_max_frames = 5;
            }
        } else if (strncmp(arg, "--runtime-smoke-visual-min-rects=", 33) == 0) {
            int parsed_min = 0;
            options.smoke_mode = 1;
            options.smoke_visual_contract = 1;
            if (!parse_int_suffix(arg + 33, &parsed_min)) {
                fprintf(stderr, "invalid --runtime-smoke-visual-min-rects value\n");
                print_usage(argv[0]);
                return 2;
            }
            options.smoke_visual_min_rects = (unsigned)parsed_min;
        } else if (strncmp(arg, "--runtime-smoke-visual-min-glyphs=", 34) == 0) {
            int parsed_min = 0;
            options.smoke_mode = 1;
            options.smoke_visual_contract = 1;
            if (!parse_int_suffix(arg + 34, &parsed_min)) {
                fprintf(stderr, "invalid --runtime-smoke-visual-min-glyphs value\n");
                print_usage(argv[0]);
                return 2;
            }
            options.smoke_visual_min_glyphs = (unsigned)parsed_min;

        } else if (strncmp(arg, "--runtime-smoke-atlas-min-nonzero=", 34) == 0) {
            int parsed_min = 0;
            options.smoke_mode = 1;
            if (!parse_int_suffix(arg + 34, &parsed_min)) {
                fprintf(stderr, "invalid --runtime-smoke-atlas-min-nonzero value\n");
                print_usage(argv[0]);
                return 2;
            }
            options.smoke_atlas_min_nonzero_bytes = (unsigned)parsed_min;
        } else if (strncmp(arg, "--runtime-smoke-max-seconds=", 28) == 0) {
            options.smoke_mode = 1;
            if (!parse_int_suffix(arg + 28, &options.smoke_max_seconds)) {
                fprintf(stderr, "invalid --runtime-smoke-max-seconds value\n");
                print_usage(argv[0]);
                return 2;
            }
        } else if (strncmp(arg, "--runtime-smoke-resize-count=", 29) == 0) {
            options.smoke_mode = 1;
            options.smoke_resize = 1;
            if (!parse_int_suffix(arg + 29, &options.smoke_resize_count)) {
                fprintf(stderr, "invalid --runtime-smoke-resize-count value\n");
                print_usage(argv[0]);
                return 2;
            }
            if (options.smoke_max_frames <= options.smoke_resize_count + 1) {
                options.smoke_max_frames = options.smoke_resize_count + 3;
            }
        } else if (strcmp(arg, "--help") == 0 || strcmp(arg, "-h") == 0) {
            print_usage(argv[0]);
            return 0;
        } else {
            fprintf(stderr, "unknown argument: %s\n", arg);
            print_usage(argv[0]);
            return 2;
        }
    }

    if (check_shaders_only) {
        return render_backend_validate_required_shader_assets() ? 0 : 1;
    }

    adainit();

    rc = runtime_glfw_run_with_options(options.smoke_mode ? &options : NULL);

    adafinal();

    return rc;
}
