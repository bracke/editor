#ifndef RUNTIME_GLFW_H
#define RUNTIME_GLFW_H

typedef struct RuntimeGlfwOptions {
    int smoke_mode;
    int smoke_max_frames;
    int smoke_resize;
    int smoke_resize_count;
    int smoke_zero_framebuffer;
    unsigned smoke_atlas_min_nonzero_bytes;
    int smoke_visual_contract;
    unsigned smoke_visual_min_rects;
    unsigned smoke_visual_min_glyphs;
    int smoke_max_seconds;
} RuntimeGlfwOptions;

int runtime_glfw_run(void);
int runtime_glfw_run_with_options(const RuntimeGlfwOptions *options);

#endif
