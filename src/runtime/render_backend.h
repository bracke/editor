#ifndef RENDER_BACKEND_H
#define RENDER_BACKEND_H

#include <stdint.h>
#include <GLFW/glfw3.h>

/* Forward declaration */
typedef struct RenderBackend RenderBackend;

/* ============================================================ */
/* Public API                                                   */
/* ============================================================ */

/* Create Vulkan backend bound to a GLFW window */
RenderBackend *render_backend_create(GLFWwindow *window);

/* Begin frame (acquire swapchain image, etc.).
 * Returns 0 only for unrecoverable runtime failures.  Recoverable skipped
 * frames such as zero-sized/minimized windows or out-of-date swapchains return
 * 1 with no active frame. */
int render_backend_begin_frame(RenderBackend *backend,
                               int width,
                               int height);

/* Draw the current editor frame (uses render packet internally).
 * Returns 0 when packet validation, atlas upload, or vertex upload fails. */
int render_backend_draw_editor(RenderBackend *backend);

/* End frame (submit + present).
 * Returns 0 when command submission or presentation has an unrecoverable
 * failure.  Out-of-date/suboptimal present is recorded for next-frame
 * swapchain recreation and returns 1. */
int render_backend_end_frame(RenderBackend *backend);

/* Request swapchain recreation before the next frame, used by deterministic
 * runtime smoke resize validation and GLFW framebuffer resize callbacks. */
void render_backend_request_swapchain_recreate(RenderBackend *backend);

/* True after a complete acquire/record/submit/present sequence in the most
 * recent frame.  Smoke mode uses this to avoid counting skipped minimized or
 * out-of-date frames as rendered frames. */
int render_backend_frame_was_rendered(const RenderBackend *backend);

/* Number of successful swapchain recreations since backend creation. */
unsigned render_backend_swapchain_recreate_count(const RenderBackend *backend);

/* Number of successful dirty font atlas uploads since backend creation.
 * Runtime smoke uses this to prove that deterministic text priming exercised
 * the Textrender dirty/upload/clear contract instead of only rendering empty
 * rectangles. */
unsigned render_backend_font_atlas_upload_count(const RenderBackend *backend);

/* Atlas upload diagnostics for runtime smoke.  These values describe the most
 * recent atlas upload and let the smoke gate prove that the uploaded atlas was
 * initialized, non-empty, and stable after Textrender clears Atlas_Dirty. */
unsigned render_backend_font_atlas_last_upload_width(const RenderBackend *backend);
unsigned render_backend_font_atlas_last_upload_height(const RenderBackend *backend);
unsigned render_backend_font_atlas_last_upload_nonzero_bytes(const RenderBackend *backend);
uint32_t render_backend_font_atlas_last_upload_checksum(const RenderBackend *backend);
int render_backend_font_atlas_dirty(const RenderBackend *backend);

/* Visual render contract diagnostics for runtime smoke.  These values are
 * captured from the Render_Packet that was recorded for the most recent
 * rendered frame.  They do not replace a future framebuffer readback/golden
 * image test, but they prove that the runtime submitted deterministic visible
 * rectangles and glyph quads instead of only passing swapchain/atlas counters. */
unsigned render_backend_last_visual_rect_count(const RenderBackend *backend);
unsigned render_backend_last_visual_glyph_count(const RenderBackend *backend);
uint32_t render_backend_last_visual_geometry_checksum(const RenderBackend *backend);
uint32_t render_backend_last_visual_color_checksum(const RenderBackend *backend);

/* Validate that all required runtime shader assets can be resolved through
 * the normal shader lookup contract.  This does not create a GLFW window or
 * Vulkan device, so packaging checks can verify missing-asset behavior without
 * requiring a graphical session.  Returns nonzero when every required shader
 * is found and readable. */
int render_backend_validate_required_shader_assets(void);

/* Destroy all Vulkan resources */
void render_backend_destroy(RenderBackend *backend);

#endif /* RENDER_BACKEND_H */