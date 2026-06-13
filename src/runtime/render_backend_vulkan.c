#define _POSIX_C_SOURCE 200809L
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(__linux__)
#include <unistd.h>
#endif

#include <vulkan/vulkan.h>
#include <GLFW/glfw3.h>

#include "render_backend.h"
#include "editor_bridge.h"
#include "editor_font_bridge.h"


/* ============================================================ */
/* Vertex types                                                 */
/* ============================================================ */

typedef struct {
    float pos[2];
    float color[3];
} RectVertex;

typedef struct {
    float pos[2];
    float uv[2];
    float color[3];
} TextVertex;

/* ============================================================ */
/* Push constants                                               */
/* ============================================================ */

typedef struct {
    float framebuffer_size[2];
} PushConstants;

/* ============================================================ */
/* Backend                                                      */
/* ============================================================ */

struct RenderBackend {
    GLFWwindow *window;

    VkInstance instance;
    VkPhysicalDevice physical_device;
    VkDevice device;
    uint32_t graphics_queue_family;
    VkQueue graphics_queue;

    VkSurfaceKHR surface;
    VkSwapchainKHR swapchain;

    VkFormat swapchain_format;
    VkExtent2D swapchain_extent;

    uint32_t image_count;
    VkImage *images;
    VkImageView *image_views;
    VkFramebuffer *framebuffers;

    VkRenderPass render_pass;

    VkPipelineLayout rect_pipeline_layout;
    VkPipeline rect_pipeline;

    VkPipelineLayout text_pipeline_layout;
    VkPipeline text_pipeline;

    VkDescriptorSetLayout text_descriptor_set_layout;
    VkDescriptorPool descriptor_pool;
    VkDescriptorSet text_descriptor_set;

    VkSampler atlas_sampler;
    VkImage atlas_image;
    VkDeviceMemory atlas_image_memory;
    VkImageView atlas_image_view;

    VkBuffer vertex_buffer;
    VkDeviceMemory vertex_buffer_memory;

    VkBuffer text_vertex_buffer;
    VkDeviceMemory text_vertex_buffer_memory;

    VkCommandPool command_pool;
    VkCommandBuffer *command_buffers;

    VkSemaphore image_available_semaphore;
    VkSemaphore render_finished_semaphore;
    VkFence in_flight_fence;

    uint32_t current_image_index;
    int frame_active;
    int frame_rendered;
    int swapchain_needs_recreate;
    unsigned swapchain_recreate_count;
    unsigned font_atlas_upload_count;
    unsigned font_atlas_last_upload_width;
    unsigned font_atlas_last_upload_height;
    unsigned font_atlas_last_upload_nonzero_bytes;
    uint32_t font_atlas_last_upload_checksum;
    unsigned last_visual_rect_count;
    unsigned last_visual_glyph_count;
    uint32_t last_visual_geometry_checksum;
    uint32_t last_visual_color_checksum;
};

/* ============================================================ */
/* Simple globals                                               */
/* ============================================================ */

static const uint32_t MAX_RECT_VERTICES = MAX_RECTANGLES * 6;
static const uint32_t MAX_TEXT_VERTICES = MAX_GLYPHS * 6;

static const uint32_t MAX_VERTEX_BYTES =
    MAX_RECT_VERTICES * sizeof(RectVertex);

static const uint32_t MAX_TEXT_VERTEX_BYTES =
    MAX_TEXT_VERTICES * sizeof(TextVertex);

/* ============================================================ */
/* Visual contract diagnostics                                  */
/* ============================================================ */

static uint32_t checksum_mix_u32(uint32_t checksum, uint32_t value)
{
    checksum ^= value;
    checksum *= 16777619u;
    return checksum;
}

static uint32_t checksum_mix_float_1000(uint32_t checksum, float value)
{
    int32_t scaled = (int32_t)(value * 1000.0f);
    return checksum_mix_u32(checksum, (uint32_t)scaled);
}

static void capture_visual_contract(RenderBackend *backend,
                                    const Render_Packet *packet)
{
    uint32_t geometry = 2166136261u;
    uint32_t color = 2166136261u;

    backend->last_visual_rect_count = (unsigned)packet->rect_count;
    backend->last_visual_glyph_count = (unsigned)packet->glyph_count;

    for (int i = 0; i < packet->rect_count; ++i) {
        const Rect_Command *r = &packet->rects[i];
        geometry = checksum_mix_u32(geometry, (uint32_t)r->layer);
        geometry = checksum_mix_float_1000(geometry, r->x);
        geometry = checksum_mix_float_1000(geometry, r->y);
        geometry = checksum_mix_float_1000(geometry, r->w);
        geometry = checksum_mix_float_1000(geometry, r->h);
        color = checksum_mix_u32(color, (uint32_t)r->layer);
        color = checksum_mix_float_1000(color, r->r);
        color = checksum_mix_float_1000(color, r->g);
        color = checksum_mix_float_1000(color, r->b);
    }

    for (int i = 0; i < packet->glyph_count; ++i) {
        const Glyph_Command *g = &packet->glyphs[i];
        geometry = checksum_mix_u32(geometry, (uint32_t)g->layer);
        geometry = checksum_mix_float_1000(geometry, g->x);
        geometry = checksum_mix_float_1000(geometry, g->y);
        geometry = checksum_mix_float_1000(geometry, g->w);
        geometry = checksum_mix_float_1000(geometry, g->h);
        geometry = checksum_mix_float_1000(geometry, g->u0);
        geometry = checksum_mix_float_1000(geometry, g->v0);
        geometry = checksum_mix_float_1000(geometry, g->u1);
        geometry = checksum_mix_float_1000(geometry, g->v1);
        color = checksum_mix_u32(color, (uint32_t)g->layer);
        color = checksum_mix_float_1000(color, g->r);
        color = checksum_mix_float_1000(color, g->g);
        color = checksum_mix_float_1000(color, g->b);
    }

    backend->last_visual_geometry_checksum = geometry;
    backend->last_visual_color_checksum = color;
}

/* ============================================================ */
/* Utility                                                      */
/* ============================================================ */

static const char *vk_result_name(VkResult res)
{
    switch (res) {
    case VK_SUCCESS: return "VK_SUCCESS";
    case VK_NOT_READY: return "VK_NOT_READY";
    case VK_TIMEOUT: return "VK_TIMEOUT";
    case VK_EVENT_SET: return "VK_EVENT_SET";
    case VK_EVENT_RESET: return "VK_EVENT_RESET";
    case VK_INCOMPLETE: return "VK_INCOMPLETE";
    case VK_ERROR_OUT_OF_HOST_MEMORY: return "VK_ERROR_OUT_OF_HOST_MEMORY";
    case VK_ERROR_OUT_OF_DEVICE_MEMORY: return "VK_ERROR_OUT_OF_DEVICE_MEMORY";
    case VK_ERROR_INITIALIZATION_FAILED: return "VK_ERROR_INITIALIZATION_FAILED";
    case VK_ERROR_DEVICE_LOST: return "VK_ERROR_DEVICE_LOST";
    case VK_ERROR_MEMORY_MAP_FAILED: return "VK_ERROR_MEMORY_MAP_FAILED";
    case VK_ERROR_LAYER_NOT_PRESENT: return "VK_ERROR_LAYER_NOT_PRESENT";
    case VK_ERROR_EXTENSION_NOT_PRESENT: return "VK_ERROR_EXTENSION_NOT_PRESENT";
    case VK_ERROR_FEATURE_NOT_PRESENT: return "VK_ERROR_FEATURE_NOT_PRESENT";
    case VK_ERROR_INCOMPATIBLE_DRIVER: return "VK_ERROR_INCOMPATIBLE_DRIVER";
    case VK_ERROR_TOO_MANY_OBJECTS: return "VK_ERROR_TOO_MANY_OBJECTS";
    case VK_ERROR_FORMAT_NOT_SUPPORTED: return "VK_ERROR_FORMAT_NOT_SUPPORTED";
    case VK_ERROR_SURFACE_LOST_KHR: return "VK_ERROR_SURFACE_LOST_KHR";
    case VK_ERROR_NATIVE_WINDOW_IN_USE_KHR: return "VK_ERROR_NATIVE_WINDOW_IN_USE_KHR";
    case VK_SUBOPTIMAL_KHR: return "VK_SUBOPTIMAL_KHR";
    case VK_ERROR_OUT_OF_DATE_KHR: return "VK_ERROR_OUT_OF_DATE_KHR";
    default: return "VK_RESULT_UNKNOWN";
    }
}

static int find_memory_type(RenderBackend *backend,
                            uint32_t type_filter,
                            VkMemoryPropertyFlags properties,
                            uint32_t *index_out)
{
    VkPhysicalDeviceMemoryProperties mem_properties;
    vkGetPhysicalDeviceMemoryProperties(backend->physical_device, &mem_properties);

    for (uint32_t i = 0; i < mem_properties.memoryTypeCount; ++i) {
        if ((type_filter & (1u << i)) &&
            (mem_properties.memoryTypes[i].propertyFlags & properties) == properties) {
            *index_out = i;
            return 1;
        }
    }

    fprintf(stderr, "find_memory_type: no suitable memory type\n");
    return 0;
}

static int read_file(const char *path, unsigned char **data_out, size_t *size_out)
{
    FILE *f = fopen(path, "rb");
    if (!f) {
        fprintf(stderr, "Failed to open file: %s\n", path);
        return 0;
    }

    if (fseek(f, 0, SEEK_END) != 0) {
        fclose(f);
        return 0;
    }

    long size = ftell(f);
    if (size < 0) {
        fclose(f);
        return 0;
    }

    rewind(f);

    unsigned char *data = (unsigned char *)malloc((size_t)size);
    if (!data) {
        fclose(f);
        return 0;
    }

    if (fread(data, 1, (size_t)size, f) != (size_t)size) {
        free(data);
        fclose(f);
        return 0;
    }

    fclose(f);

    *data_out = data;
    *size_out = (size_t)size;
    return 1;
}

static int join_path(char *out, size_t out_size, const char *dir, const char *name)
{
    size_t dir_len = strlen(dir);
    size_t name_len = strlen(name);
    int need_slash = dir_len > 0 && dir[dir_len - 1] != '/';
    size_t total = dir_len + (need_slash ? 1u : 0u) + name_len + 1u;

    if (total > out_size) {
        return 0;
    }

    memcpy(out, dir, dir_len);
    if (need_slash) {
        out[dir_len] = '/';
        memcpy(out + dir_len + 1u, name, name_len + 1u);
    } else {
        memcpy(out + dir_len, name, name_len + 1u);
    }

    return 1;
}

static int dirname_of_path(const char *path, char *out, size_t out_size)
{
    const char *last_slash;
    size_t len;

    if (!path || !out || out_size == 0) {
        return 0;
    }

    last_slash = strrchr(path, '/');
    if (!last_slash) {
        return 0;
    }

    len = (size_t)(last_slash - path);
    if (len == 0) {
        len = 1;
    }
    if (len + 1u > out_size) {
        return 0;
    }

    memcpy(out, path, len);
    out[len] = '\0';
    return 1;
}

static int executable_dir(char *out, size_t out_size)
{
#if defined(__linux__)
    char path[1024];
    ssize_t len;

    if (!out || out_size == 0) {
        return 0;
    }

    len = readlink("/proc/self/exe", path, sizeof path - 1u);
    if (len <= 0 || (size_t)len >= sizeof path) {
        return 0;
    }

    path[len] = '\0';
    return dirname_of_path(path, out, out_size);
#else
    (void)out;
    (void)out_size;
    return 0;
#endif
}

static int try_shader_dir(const char *dir,
                          const char *name,
                          unsigned char **data_out,
                          size_t *size_out,
                          char *chosen_path,
                          size_t chosen_path_size)
{
    char path[1024];

    if (!dir || dir[0] == '\0') {
        return 0;
    }

    if (!join_path(path, sizeof path, dir, name)) {
        return 0;
    }

    if (!read_file(path, data_out, size_out)) {
        return 0;
    }

    if (chosen_path && chosen_path_size > 0) {
        snprintf(chosen_path, chosen_path_size, "%s", path);
    }
    return 1;
}

static int read_shader_file(const char *name, unsigned char **data_out, size_t *size_out, char *chosen_path, size_t chosen_path_size)
{
    static const char *fallback_dirs[] = {
        "src/runtime/shaders",
        "./shaders",
        "../share/editor/shaders",
        "/usr/local/share/editor/shaders",
        "/usr/share/editor/shaders"
    };

    const char *env_dir = getenv("EDITOR_SHADER_DIR");
    const char *env_only = getenv("EDITOR_SHADER_DIR_ONLY");
    int shader_dir_only = env_only && env_only[0] != '\0' && env_only[0] != '0';
    char exe_dir[1024];
    char exe_shader_dir[1024];

    if (try_shader_dir(env_dir, name, data_out, size_out, chosen_path, chosen_path_size)) {
        return 1;
    }

    if (shader_dir_only) {
        fprintf(stderr,
                "runtime asset error: shader '%s' not found in EDITOR_SHADER_DIR while EDITOR_SHADER_DIR_ONLY is set; fallback shader lookup disabled for packaging validation\n",
                name);
        return 0;
    }

    if (executable_dir(exe_dir, sizeof exe_dir)) {
        if (try_shader_dir(exe_dir, name, data_out, size_out, chosen_path, chosen_path_size)) {
            return 1;
        }
        if (join_path(exe_shader_dir, sizeof exe_shader_dir, exe_dir, "shaders") &&
            try_shader_dir(exe_shader_dir, name, data_out, size_out, chosen_path, chosen_path_size)) {
            return 1;
        }
        if (join_path(exe_shader_dir, sizeof exe_shader_dir, exe_dir, "../share/editor/shaders") &&
            try_shader_dir(exe_shader_dir, name, data_out, size_out, chosen_path, chosen_path_size)) {
            return 1;
        }
    }

    for (size_t i = 0; i < sizeof fallback_dirs / sizeof fallback_dirs[0]; ++i) {
        if (try_shader_dir(fallback_dirs[i], name, data_out, size_out, chosen_path, chosen_path_size)) {
            return 1;
        }
    }

    fprintf(stderr,
            "runtime asset error: shader '%s' not found; lookup order is EDITOR_SHADER_DIR, executable directory, executable-relative shaders/, executable-relative ../share/editor/shaders, developer checkout src/runtime/shaders, ./shaders, ../share/editor/shaders, /usr/local/share/editor/shaders, /usr/share/editor/shaders\n",
            name);
    return 0;
}

int render_backend_validate_required_shader_assets(void)
{
    static const char *required_shaders[] = {
        "rect.vert.spv",
        "rect.frag.spv",
        "text.vert.spv",
        "text.frag.spv"
    };

    for (size_t i = 0; i < sizeof required_shaders / sizeof required_shaders[0]; ++i) {
        unsigned char *bytes = NULL;
        size_t size = 0;
        char resolved_path[1024];

        if (!read_shader_file(required_shaders[i], &bytes, &size, resolved_path, sizeof resolved_path)) {
            fprintf(stderr,
                    "runtime asset check: required shader asset missing: %s\n",
                    required_shaders[i]);
            return 0;
        }

        if (size == 0) {
            fprintf(stderr,
                    "runtime asset error: shader '%s' resolved to an empty file: %s\n",
                    required_shaders[i],
                    resolved_path);
            free(bytes);
            return 0;
        }

        free(bytes);
    }

    fprintf(stderr, "runtime asset check: required shader assets found\n");
    return 1;
}

static VkShaderModule create_shader_module(RenderBackend *backend, const char *shader_name)
{
    unsigned char *bytes = NULL;
    size_t size = 0;
    char resolved_path[1024];

    if (!read_shader_file(shader_name, &bytes, &size, resolved_path, sizeof resolved_path)) {
        return VK_NULL_HANDLE;
    }

    VkShaderModuleCreateInfo create_info = {0};
    create_info.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    create_info.codeSize = size;
    create_info.pCode = (const uint32_t *)bytes;

    VkShaderModule module = VK_NULL_HANDLE;
    VkResult res = vkCreateShaderModule(backend->device, &create_info, NULL, &module);
    free(bytes);

    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateShaderModule(%s) -> %s\n", resolved_path, vk_result_name(res));
        return VK_NULL_HANDLE;
    }

    return module;
}

static int create_buffer(RenderBackend *backend,
                         VkDeviceSize size,
                         VkBufferUsageFlags usage,
                         VkMemoryPropertyFlags properties,
                         VkBuffer *buffer,
                         VkDeviceMemory *memory)
{
    VkBufferCreateInfo buffer_info = {0};
    buffer_info.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    buffer_info.size = size;
    buffer_info.usage = usage;
    buffer_info.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

    VkResult res = vkCreateBuffer(backend->device, &buffer_info, NULL, buffer);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateBuffer -> %s\n", vk_result_name(res));
        return 0;
    }

    VkMemoryRequirements mem_req;
    vkGetBufferMemoryRequirements(backend->device, *buffer, &mem_req);

    uint32_t memory_type_index = 0;
    if (!find_memory_type(backend,
                          mem_req.memoryTypeBits,
                          properties,
                          &memory_type_index)) {
        return 0;
    }

    VkMemoryAllocateInfo alloc_info = {0};
    alloc_info.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    alloc_info.allocationSize = mem_req.size;
    alloc_info.memoryTypeIndex = memory_type_index;

    res = vkAllocateMemory(backend->device, &alloc_info, NULL, memory);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkAllocateMemory(buffer) -> %s\n", vk_result_name(res));
        return 0;
    }

    res = vkBindBufferMemory(backend->device, *buffer, *memory, 0);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkBindBufferMemory -> %s\n", vk_result_name(res));
        return 0;
    }

    return 1;
}

static int create_image(RenderBackend *backend,
                        uint32_t width,
                        uint32_t height,
                        VkFormat format,
                        VkImageUsageFlags usage,
                        VkImage *image,
                        VkDeviceMemory *memory)
{
    VkImageCreateInfo image_info = {0};
    image_info.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
    image_info.imageType = VK_IMAGE_TYPE_2D;
    image_info.extent.width = width;
    image_info.extent.height = height;
    image_info.extent.depth = 1;
    image_info.mipLevels = 1;
    image_info.arrayLayers = 1;
    image_info.format = format;
    image_info.tiling = VK_IMAGE_TILING_LINEAR;
    image_info.initialLayout = VK_IMAGE_LAYOUT_PREINITIALIZED;
    image_info.usage = usage;
    image_info.samples = VK_SAMPLE_COUNT_1_BIT;
    image_info.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

    VkResult res = vkCreateImage(backend->device, &image_info, NULL, image);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateImage -> %s\n", vk_result_name(res));
        return 0;
    }

    VkMemoryRequirements mem_req;
    vkGetImageMemoryRequirements(backend->device, *image, &mem_req);

    uint32_t memory_type_index = 0;
    if (!find_memory_type(backend,
                          mem_req.memoryTypeBits,
                          VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
                          VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                          &memory_type_index)) {
        return 0;
    }

    VkMemoryAllocateInfo alloc_info = {0};
    alloc_info.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    alloc_info.allocationSize = mem_req.size;
    alloc_info.memoryTypeIndex = memory_type_index;

    res = vkAllocateMemory(backend->device, &alloc_info, NULL, memory);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkAllocateMemory(image) -> %s\n", vk_result_name(res));
        return 0;
    }

    res = vkBindImageMemory(backend->device, *image, *memory, 0);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkBindImageMemory -> %s\n", vk_result_name(res));
        return 0;
    }

    return 1;
}

static int upload_font_atlas_pixels(RenderBackend *backend)
{
    const unsigned char *data = editor_font_atlas_pixels();
    int width  = editor_font_atlas_width();
    int height = editor_font_atlas_height();

    if (!data || width <= 0 || height <= 0) {
        fprintf(stderr, "font atlas not initialized\n");
        return 0;
    }

    size_t atlas_size = (size_t)width * (size_t)height;
    unsigned nonzero_bytes = 0u;
    uint32_t checksum = 2166136261u;

    for (size_t i = 0; i < atlas_size; ++i) {
        unsigned char value = data[i];
        if (value != 0u) {
            nonzero_bytes += 1u;
        }
        checksum ^= (uint32_t)value;
        checksum *= 16777619u;
    }

    VkImageSubresource subresource = {0};
    subresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    subresource.mipLevel = 0;
    subresource.arrayLayer = 0;

    VkSubresourceLayout layout;
    vkGetImageSubresourceLayout(backend->device,
                                backend->atlas_image,
                                &subresource,
                                &layout);

    void *mapped = NULL;
    VkResult res = vkMapMemory(backend->device,
                               backend->atlas_image_memory,
                               0,
                               VK_WHOLE_SIZE,
                               0,
                               &mapped);

    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkMapMemory(atlas update) -> %s\n", vk_result_name(res));
        return 0;
    }

    unsigned char *dst = (unsigned char *)mapped + layout.offset;

    for (int y = 0; y < height; ++y) {
        memcpy(dst + (size_t)y * layout.rowPitch,
               data + (size_t)y * width,
               (size_t)width);
    }

    vkUnmapMemory(backend->device, backend->atlas_image_memory);

    backend->font_atlas_last_upload_width = (unsigned)width;
    backend->font_atlas_last_upload_height = (unsigned)height;
    backend->font_atlas_last_upload_nonzero_bytes = nonzero_bytes;
    backend->font_atlas_last_upload_checksum = checksum;

    return 1;
}
static int load_font_atlas(RenderBackend *backend)
{
    const unsigned char *data = editor_font_atlas_pixels();
    int width  = editor_font_atlas_width();
    int height = editor_font_atlas_height();

    if (!data || width <= 0 || height <= 0) {
        fprintf(stderr, "font atlas not initialized\n");
        return 0;
    }

    size_t size = (size_t)width * (size_t)height;

    if (!create_image(backend,
                      (uint32_t)width,
                      (uint32_t)height,
                      VK_FORMAT_R8_UNORM,
                      VK_IMAGE_USAGE_SAMPLED_BIT,
                      &backend->atlas_image,
                      &backend->atlas_image_memory)) {
        return 0;
    }
    if (!upload_font_atlas_pixels(backend)) {
        return 0;
    }

    VkImageViewCreateInfo view_info = {0};
    view_info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
    view_info.image = backend->atlas_image;
    view_info.viewType = VK_IMAGE_VIEW_TYPE_2D;
    view_info.format = VK_FORMAT_R8_UNORM;
    view_info.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    view_info.subresourceRange.levelCount = 1;
    view_info.subresourceRange.layerCount = 1;


    VkResult res = vkCreateImageView(backend->device, &view_info, NULL, &backend->atlas_image_view);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateImageView(atlas) -> %s\n", vk_result_name(res));
        return 0;
    }

    VkSamplerCreateInfo sampler_info = {0};
    sampler_info.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
    sampler_info.magFilter = VK_FILTER_LINEAR;
    sampler_info.minFilter = VK_FILTER_LINEAR;
    sampler_info.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
    sampler_info.addressModeV = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
    sampler_info.addressModeW = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
    sampler_info.maxAnisotropy = 1.0f;

    res = vkCreateSampler(backend->device, &sampler_info, NULL, &backend->atlas_sampler);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateSampler -> %s\n", vk_result_name(res));
        return 0;
    }

    return 1;
}
static int create_descriptor_objects(RenderBackend *backend)
{
    VkDescriptorSetLayoutBinding binding = {0};
    binding.binding = 0;
    binding.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    binding.descriptorCount = 1;
    binding.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT;

    VkDescriptorSetLayoutCreateInfo layout_info = {0};
    layout_info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    layout_info.bindingCount = 1;
    layout_info.pBindings = &binding;

    VkResult res = vkCreateDescriptorSetLayout(backend->device,
                                               &layout_info,
                                               NULL,
                                               &backend->text_descriptor_set_layout);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateDescriptorSetLayout -> %s\n", vk_result_name(res));
        return 0;
    }

    VkDescriptorPoolSize pool_size = {0};
    pool_size.type = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    pool_size.descriptorCount = 1;

    VkDescriptorPoolCreateInfo pool_info = {0};
    pool_info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    pool_info.poolSizeCount = 1;
    pool_info.pPoolSizes = &pool_size;
    pool_info.maxSets = 1;

    res = vkCreateDescriptorPool(backend->device, &pool_info, NULL, &backend->descriptor_pool);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateDescriptorPool -> %s\n", vk_result_name(res));
        return 0;
    }

    VkDescriptorSetAllocateInfo alloc_info = {0};
    alloc_info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    alloc_info.descriptorPool = backend->descriptor_pool;
    alloc_info.descriptorSetCount = 1;
    alloc_info.pSetLayouts = &backend->text_descriptor_set_layout;

    res = vkAllocateDescriptorSets(backend->device, &alloc_info, &backend->text_descriptor_set);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkAllocateDescriptorSets -> %s\n", vk_result_name(res));
        return 0;
    }

    VkDescriptorImageInfo image_info = {0};
    image_info.sampler = backend->atlas_sampler;
    image_info.imageView = backend->atlas_image_view;
    image_info.imageLayout = VK_IMAGE_LAYOUT_GENERAL;

    VkWriteDescriptorSet write = {0};
    write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
    write.dstSet = backend->text_descriptor_set;
    write.dstBinding = 0;
    write.descriptorCount = 1;
    write.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    write.pImageInfo = &image_info;

    vkUpdateDescriptorSets(backend->device, 1, &write, 0, NULL);

    return 1;
}

/* ============================================================ */
/* Vertex push helpers                                          */
/* ============================================================ */

static int push_rect(RectVertex *verts,
                     uint32_t *count,
                     float x, float y,
                     float w, float h,
                     float r, float g, float b)
{
    if (*count + 6 > MAX_RECT_VERTICES) {
        fprintf(stderr, "rect vertex overflow\n");
        return 0;
    }

    RectVertex rv0 = {{x,     y},     {r, g, b}};
    RectVertex rv1 = {{x + w, y},     {r, g, b}};
    RectVertex rv2 = {{x + w, y + h}, {r, g, b}};
    RectVertex rv3 = {{x,     y + h}, {r, g, b}};

    verts[(*count)++] = rv0;
    verts[(*count)++] = rv1;
    verts[(*count)++] = rv2;

    verts[(*count)++] = rv2;
    verts[(*count)++] = rv3;
    verts[(*count)++] = rv0;

    return 1;
}

static int push_text_quad(TextVertex *verts,
                          uint32_t *count,
                          float x, float y,
                          float w, float h,
                          float u0, float v0,
                          float u1, float v1,
                          float r, float g, float b)
{
    if (*count + 6 > MAX_TEXT_VERTICES) {
        fprintf(stderr, "text vertex overflow\n");
        return 0;
    }

    TextVertex tv0 = {{x,     y},     {u0, v0}, {r, g, b}};
    TextVertex tv1 = {{x + w, y},     {u1, v0}, {r, g, b}};
    TextVertex tv2 = {{x + w, y + h}, {u1, v1}, {r, g, b}};
    TextVertex tv3 = {{x,     y + h}, {u0, v1}, {r, g, b}};

    verts[(*count)++] = tv0;
    verts[(*count)++] = tv1;
    verts[(*count)++] = tv2;

    verts[(*count)++] = tv2;
    verts[(*count)++] = tv3;
    verts[(*count)++] = tv0;

    return 1;
}

/* ============================================================ */
/* Command recording                                            */
/* ============================================================ */

static int record_command_buffer(RenderBackend *backend,
                                 VkCommandBuffer cmd,
                                 uint32_t image_index,
                                 int width,
                                 int height)
{
    VkResult reset_res = vkResetCommandBuffer(cmd, 0);
    if (reset_res != VK_SUCCESS) {
        fprintf(stderr, "vkResetCommandBuffer -> %s\n", vk_result_name(reset_res));
        return 0;
    }

    VkCommandBufferBeginInfo begin_info = {0};
    begin_info.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;

    if (vkBeginCommandBuffer(cmd, &begin_info) != VK_SUCCESS) {
        fprintf(stderr, "vkBeginCommandBuffer failed\n");
        return 0;
    }

    /* Phase 15: clear colour remains runtime-owned; keep it in sync with
       Editor.Theme.Editor_Background until the Ada/runtime colour bridge exists. */
    VkClearValue clear;
    clear.color.float32[0] = 0.10f;
    clear.color.float32[1] = 0.10f;
    clear.color.float32[2] = 0.12f;
    clear.color.float32[3] = 1.0f;

    VkRenderPassBeginInfo rp_begin = {0};
    rp_begin.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
    rp_begin.renderPass = backend->render_pass;
    rp_begin.framebuffer = backend->framebuffers[image_index];
    rp_begin.renderArea.offset.x = 0;
    rp_begin.renderArea.offset.y = 0;
    rp_begin.renderArea.extent.width = (uint32_t)width;
    rp_begin.renderArea.extent.height = (uint32_t)height;
    rp_begin.clearValueCount = 1;
    rp_begin.pClearValues = &clear;

    vkCmdBeginRenderPass(cmd, &rp_begin, VK_SUBPASS_CONTENTS_INLINE);

    VkViewport viewport = {0};
    viewport.x = 0;
    viewport.y = 0;
    viewport.width = (float)width;
    viewport.height = (float)height;
    viewport.minDepth = 0.0f;
    viewport.maxDepth = 1.0f;

    VkRect2D scissor = {0};
    scissor.offset.x = 0;
    scissor.offset.y = 0;
    scissor.extent.width = (uint32_t)width;
    scissor.extent.height = (uint32_t)height;

    vkCmdSetViewport(cmd, 0, 1, &viewport);
    vkCmdSetScissor(cmd, 0, 1, &scissor);

    PushConstants pc;
    pc.framebuffer_size[0] = (float)width;
    pc.framebuffer_size[1] = (float)height;

    Render_Packet packet;
    memset(&packet, 0, sizeof(packet));
    editor_get_render_packet(&packet);

    /*
    * editor_get_render_packet may cause Ada/Textrender to rasterize
    * previously unseen glyphs into the atlas.
    *
    * Therefore atlas synchronization must happen after packet construction
    * and before drawing.
    */
    if (editor_font_atlas_dirty()) {
        if (!upload_font_atlas_pixels(backend)) {
            fprintf(stderr, "failed to upload dirty font atlas\n");
            return 0;
        }

        editor_font_clear_atlas_dirty();
        backend->font_atlas_upload_count += 1u;
    }

    if (packet.rect_count < 0 || packet.rect_count > MAX_RECTANGLES) {
        fprintf(stderr, "Invalid rect_count: %d\n", packet.rect_count);
        return 0;
    }

    if (packet.glyph_count < 0 || packet.glyph_count > MAX_GLYPHS) {
        fprintf(stderr, "Invalid glyph_count: %d\n", packet.glyph_count);
        return 0;
    }

    for (int i = 0; i < packet.rect_count; ++i) {
        if (packet.rects[i].layer < LAYER_FIRST ||
            packet.rects[i].layer > LAYER_LAST) {
            fprintf(stderr, "Invalid rect layer: %d\n", packet.rects[i].layer);
            return 0;
        }
    }

    for (int i = 0; i < packet.glyph_count; ++i) {
        if (packet.glyphs[i].layer < LAYER_FIRST ||
            packet.glyphs[i].layer > LAYER_LAST) {
            fprintf(stderr, "Invalid glyph layer: %d\n", packet.glyphs[i].layer);
            return 0;
        }
    }

    capture_visual_contract(backend, &packet);

    for (int layer = LAYER_FIRST; layer <= LAYER_LAST; ++layer) {
        {
            RectVertex verts[MAX_RECT_VERTICES];
            uint32_t vert_count = 0;

            for (int i = 0; i < packet.rect_count; ++i) {
                if (packet.rects[i].layer != layer) {
                    continue;
                }

                if (!push_rect(verts,
                               &vert_count,
                               packet.rects[i].x,
                               packet.rects[i].y,
                               packet.rects[i].w,
                               packet.rects[i].h,
                               packet.rects[i].r,
                               packet.rects[i].g,
                               packet.rects[i].b)) {
                    return 0;
                }
            }

            if (vert_count > 0) {
                void *mapped = NULL;
                VkResult res = vkMapMemory(backend->device,
                                           backend->vertex_buffer_memory,
                                           0,
                                           sizeof(RectVertex) * vert_count,
                                           0,
                                           &mapped);

                if (res != VK_SUCCESS) {
                    fprintf(stderr, "vkMapMemory(rect vertices) -> %s\n", vk_result_name(res));
                    return 0;
                }

                memcpy(mapped, verts, sizeof(RectVertex) * vert_count);
                vkUnmapMemory(backend->device, backend->vertex_buffer_memory);

                    VkBuffer vbs[] = { backend->vertex_buffer };
                    VkDeviceSize offsets[] = { 0 };

                    vkCmdBindPipeline(cmd,
                                      VK_PIPELINE_BIND_POINT_GRAPHICS,
                                      backend->rect_pipeline);

                    vkCmdBindVertexBuffers(cmd, 0, 1, vbs, offsets);

                    vkCmdPushConstants(cmd,
                                       backend->rect_pipeline_layout,
                                       VK_SHADER_STAGE_VERTEX_BIT,
                                       0,
                                       sizeof(PushConstants),
                                       &pc);

                    vkCmdDraw(cmd, vert_count, 1, 0, 0);
                }
            }

        {
            TextVertex verts[MAX_TEXT_VERTICES];
            uint32_t vert_count = 0;

            for (int i = 0; i < packet.glyph_count; ++i) {
                if (packet.glyphs[i].layer != layer) {
                    continue;
                }

                if (!push_text_quad(verts,
                                    &vert_count,
                                    packet.glyphs[i].x,
                                    packet.glyphs[i].y,
                                    packet.glyphs[i].w,
                                    packet.glyphs[i].h,
                                    packet.glyphs[i].u0,
                                    packet.glyphs[i].v0,
                                    packet.glyphs[i].u1,
                                    packet.glyphs[i].v1,
                                    packet.glyphs[i].r,
                                    packet.glyphs[i].g,
                                    packet.glyphs[i].b)) {
                    return 0;
                }
            }

            if (vert_count > 0) {
                void *mapped = NULL;
                VkResult res = vkMapMemory(backend->device,
                                           backend->text_vertex_buffer_memory,
                                           0,
                                           sizeof(TextVertex) * vert_count,
                                           0,
                                           &mapped);

                if (res != VK_SUCCESS) {
                    fprintf(stderr, "vkMapMemory(text vertices) -> %s\n", vk_result_name(res));
                    return 0;
                }

                memcpy(mapped, verts, sizeof(TextVertex) * vert_count);
                vkUnmapMemory(backend->device, backend->text_vertex_buffer_memory);

                    VkBuffer text_vb[] = { backend->text_vertex_buffer };
                    VkDeviceSize text_offsets[] = { 0 };

                    vkCmdBindPipeline(cmd,
                                      VK_PIPELINE_BIND_POINT_GRAPHICS,
                                      backend->text_pipeline);

                    vkCmdBindVertexBuffers(cmd, 0, 1, text_vb, text_offsets);

                    vkCmdBindDescriptorSets(cmd,
                                            VK_PIPELINE_BIND_POINT_GRAPHICS,
                                            backend->text_pipeline_layout,
                                            0,
                                            1,
                                            &backend->text_descriptor_set,
                                            0,
                                            NULL);

                    vkCmdPushConstants(cmd,
                                       backend->text_pipeline_layout,
                                       VK_SHADER_STAGE_VERTEX_BIT,
                                       0,
                                       sizeof(PushConstants),
                                       &pc);

                    vkCmdDraw(cmd, vert_count, 1, 0, 0);
                }
            }
        }

    vkCmdEndRenderPass(cmd);

    if (vkEndCommandBuffer(cmd) != VK_SUCCESS) {
        fprintf(stderr, "vkEndCommandBuffer failed\n");
        return 0;
    }

    return 1;
}

/* ============================================================ */
/* Public API                                                   */
/* ============================================================ */


static void destroy_swapchain_frame_resources(RenderBackend *backend)
{
    if (!backend || backend->device == VK_NULL_HANDLE) {
        return;
    }

    if (backend->command_pool && backend->command_buffers && backend->image_count > 0) {
        vkFreeCommandBuffers(backend->device,
                             backend->command_pool,
                             backend->image_count,
                             backend->command_buffers);
    }
    free(backend->command_buffers);
    backend->command_buffers = NULL;

    if (backend->framebuffers) {
        for (uint32_t i = 0; i < backend->image_count; ++i) {
            if (backend->framebuffers[i]) {
                vkDestroyFramebuffer(backend->device, backend->framebuffers[i], NULL);
            }
        }
    }
    free(backend->framebuffers);
    backend->framebuffers = NULL;

    if (backend->image_views) {
        for (uint32_t i = 0; i < backend->image_count; ++i) {
            if (backend->image_views[i]) {
                vkDestroyImageView(backend->device, backend->image_views[i], NULL);
            }
        }
    }
    free(backend->image_views);
    backend->image_views = NULL;

    free(backend->images);
    backend->images = NULL;
}

static int choose_swapchain_extent(RenderBackend *backend,
                                   const VkSurfaceCapabilitiesKHR *caps,
                                   VkExtent2D *extent_out)
{
    if (caps->currentExtent.width != UINT32_MAX) {
        if (caps->currentExtent.width == 0 || caps->currentExtent.height == 0) {
            return 0;
        }
        *extent_out = caps->currentExtent;
        return 1;
    }

    int fb_width = 0;
    int fb_height = 0;
    glfwGetFramebufferSize(backend->window, &fb_width, &fb_height);

    if (fb_width <= 0 || fb_height <= 0) {
        return 0;
    }

    VkExtent2D extent = {(uint32_t)fb_width, (uint32_t)fb_height};

    if (extent.width < caps->minImageExtent.width) {
        extent.width = caps->minImageExtent.width;
    }
    if (extent.height < caps->minImageExtent.height) {
        extent.height = caps->minImageExtent.height;
    }
    if (caps->maxImageExtent.width > 0 && extent.width > caps->maxImageExtent.width) {
        extent.width = caps->maxImageExtent.width;
    }
    if (caps->maxImageExtent.height > 0 && extent.height > caps->maxImageExtent.height) {
        extent.height = caps->maxImageExtent.height;
    }

    *extent_out = extent;
    return 1;
}

static int create_swapchain_frame_resources(RenderBackend *backend,
                                            VkSwapchainKHR old_swapchain)
{
    VkSurfaceCapabilitiesKHR caps;
    VkResult res = vkGetPhysicalDeviceSurfaceCapabilitiesKHR(backend->physical_device,
                                                             backend->surface,
                                                             &caps);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR -> %s\n", vk_result_name(res));
        return 0;
    }

    VkExtent2D extent;
    if (!choose_swapchain_extent(backend, &caps, &extent)) {
        return 0;
    }

    uint32_t image_count = caps.minImageCount + 1;
    if (caps.maxImageCount > 0 && image_count > caps.maxImageCount) {
        image_count = caps.maxImageCount;
    }

    VkSwapchainCreateInfoKHR swapchain_info = {0};
    swapchain_info.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
    swapchain_info.surface = backend->surface;
    swapchain_info.minImageCount = image_count;
    swapchain_info.imageFormat = backend->swapchain_format;
    swapchain_info.imageColorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
    swapchain_info.imageExtent = extent;
    swapchain_info.imageArrayLayers = 1;
    swapchain_info.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
    swapchain_info.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
    swapchain_info.preTransform = caps.currentTransform;
    swapchain_info.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
    swapchain_info.presentMode = VK_PRESENT_MODE_FIFO_KHR;
    swapchain_info.clipped = VK_TRUE;
    swapchain_info.oldSwapchain = old_swapchain;

    VkSwapchainKHR new_swapchain = VK_NULL_HANDLE;
    res = vkCreateSwapchainKHR(backend->device, &swapchain_info, NULL, &new_swapchain);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateSwapchainKHR(recreate) -> %s\n", vk_result_name(res));
        return 0;
    }

    backend->swapchain = new_swapchain;
    backend->swapchain_extent = extent;

    res = vkGetSwapchainImagesKHR(backend->device, backend->swapchain, &image_count, NULL);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkGetSwapchainImagesKHR(count) -> %s\n", vk_result_name(res));
        return 0;
    }

    backend->image_count = image_count;
    backend->images = (VkImage *)malloc(sizeof(VkImage) * backend->image_count);
    backend->image_views = (VkImageView *)calloc(backend->image_count, sizeof(VkImageView));
    backend->framebuffers = (VkFramebuffer *)calloc(backend->image_count, sizeof(VkFramebuffer));
    backend->command_buffers = (VkCommandBuffer *)calloc(backend->image_count, sizeof(VkCommandBuffer));

    if (!backend->images || !backend->image_views || !backend->framebuffers || !backend->command_buffers) {
        fprintf(stderr, "create_swapchain_frame_resources: allocation failure\n");
        return 0;
    }

    res = vkGetSwapchainImagesKHR(backend->device,
                                  backend->swapchain,
                                  &backend->image_count,
                                  backend->images);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkGetSwapchainImagesKHR(images) -> %s\n", vk_result_name(res));
        return 0;
    }

    for (uint32_t i = 0; i < backend->image_count; ++i) {
        VkImageViewCreateInfo view_info = {0};
        view_info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
        view_info.image = backend->images[i];
        view_info.viewType = VK_IMAGE_VIEW_TYPE_2D;
        view_info.format = backend->swapchain_format;
        view_info.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        view_info.subresourceRange.levelCount = 1;
        view_info.subresourceRange.layerCount = 1;

        res = vkCreateImageView(backend->device, &view_info, NULL, &backend->image_views[i]);
        if (res != VK_SUCCESS) {
            fprintf(stderr, "vkCreateImageView(swapchain recreate) -> %s\n", vk_result_name(res));
            return 0;
        }
    }

    for (uint32_t i = 0; i < backend->image_count; ++i) {
        VkImageView attachments[] = { backend->image_views[i] };

        VkFramebufferCreateInfo fb_info = {0};
        fb_info.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
        fb_info.renderPass = backend->render_pass;
        fb_info.attachmentCount = 1;
        fb_info.pAttachments = attachments;
        fb_info.width = backend->swapchain_extent.width;
        fb_info.height = backend->swapchain_extent.height;
        fb_info.layers = 1;

        res = vkCreateFramebuffer(backend->device, &fb_info, NULL, &backend->framebuffers[i]);
        if (res != VK_SUCCESS) {
            fprintf(stderr, "vkCreateFramebuffer(recreate) -> %s\n", vk_result_name(res));
            return 0;
        }
    }

    if (backend->command_pool) {
        VkCommandBufferAllocateInfo cmd_alloc = {0};
        cmd_alloc.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
        cmd_alloc.commandPool = backend->command_pool;
        cmd_alloc.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
        cmd_alloc.commandBufferCount = backend->image_count;

        res = vkAllocateCommandBuffers(backend->device,
                                       &cmd_alloc,
                                       backend->command_buffers);
        if (res != VK_SUCCESS) {
            fprintf(stderr, "vkAllocateCommandBuffers(recreate) -> %s\n", vk_result_name(res));
            return 0;
        }
    }

    if (old_swapchain != VK_NULL_HANDLE) {
        vkDestroySwapchainKHR(backend->device, old_swapchain, NULL);
    }

    return 1;
}

static int recreate_swapchain(RenderBackend *backend)
{
    if (!backend || backend->device == VK_NULL_HANDLE) {
        return 0;
    }

    vkDeviceWaitIdle(backend->device);

    VkSwapchainKHR old_swapchain = backend->swapchain;
    destroy_swapchain_frame_resources(backend);

    if (!create_swapchain_frame_resources(backend, old_swapchain)) {
        VkSwapchainKHR failed_swapchain = backend->swapchain;

        if (failed_swapchain != VK_NULL_HANDLE && failed_swapchain != old_swapchain) {
            vkDestroySwapchainKHR(backend->device, failed_swapchain, NULL);
        }
        if (old_swapchain != VK_NULL_HANDLE) {
            vkDestroySwapchainKHR(backend->device, old_swapchain, NULL);
        }

        backend->swapchain = VK_NULL_HANDLE;
        destroy_swapchain_frame_resources(backend);
        backend->swapchain_needs_recreate = 1;
        return 0;
    }

    backend->swapchain_needs_recreate = 0;
    backend->swapchain_recreate_count += 1u;
    fprintf(stderr, "runtime: swapchain recreated (%ux%u)\n",
            backend->swapchain_extent.width,
            backend->swapchain_extent.height);
    return 1;
}

static int backend_framebuffer_is_zero(RenderBackend *backend)
{
    int width = 0;
    int height = 0;

    if (!backend || !backend->window) {
        return 0;
    }

    glfwGetFramebufferSize(backend->window, &width, &height);
    return width <= 0 || height <= 0;
}

RenderBackend *render_backend_create(GLFWwindow *window)
{
    RenderBackend *backend = (RenderBackend *)calloc(1, sizeof(RenderBackend));
    if (!backend) {
        return NULL;
    }

    backend->window = window;

    /* -------------------------------------------------- */
    /* Instance                                           */
    /* -------------------------------------------------- */
    uint32_t extension_count = 0;
    const char **extensions = glfwGetRequiredInstanceExtensions(&extension_count);

    VkApplicationInfo app_info = {0};
    app_info.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    app_info.pApplicationName = "Editor";
    app_info.apiVersion = VK_API_VERSION_1_0;

    VkInstanceCreateInfo instance_info = {0};
    instance_info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    instance_info.pApplicationInfo = &app_info;
    instance_info.enabledExtensionCount = extension_count;
    instance_info.ppEnabledExtensionNames = extensions;

    VkResult res = vkCreateInstance(&instance_info, NULL, &backend->instance);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateInstance -> %s\n", vk_result_name(res));
        free(backend);
        return NULL;
    }

    /* -------------------------------------------------- */
    /* Surface                                            */
    /* -------------------------------------------------- */
    res = glfwCreateWindowSurface(backend->instance, window, NULL, &backend->surface);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "glfwCreateWindowSurface -> %s\n", vk_result_name(res));
        render_backend_destroy(backend);
        return NULL;
    }

    /* -------------------------------------------------- */
    /* Physical device                                    */
    /* -------------------------------------------------- */
    uint32_t device_count = 0;
    vkEnumeratePhysicalDevices(backend->instance, &device_count, NULL);
    if (device_count == 0) {
        fprintf(stderr, "No Vulkan physical devices found\n");
        render_backend_destroy(backend);
        return NULL;
    }

    VkPhysicalDevice *devices =
        (VkPhysicalDevice *)malloc(sizeof(VkPhysicalDevice) * device_count);
    vkEnumeratePhysicalDevices(backend->instance, &device_count, devices);
    backend->physical_device = devices[0];
    free(devices);

    /* -------------------------------------------------- */
    /* Queue family                                       */
    /* -------------------------------------------------- */
    uint32_t queue_family_count = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(backend->physical_device,
                                             &queue_family_count,
                                             NULL);

    VkQueueFamilyProperties *queue_families =
        (VkQueueFamilyProperties *)malloc(sizeof(VkQueueFamilyProperties) *
                                          queue_family_count);

    vkGetPhysicalDeviceQueueFamilyProperties(backend->physical_device,
                                             &queue_family_count,
                                             queue_families);

    backend->graphics_queue_family = UINT32_MAX;

    for (uint32_t i = 0; i < queue_family_count; ++i) {
        VkBool32 present_supported = VK_FALSE;
        vkGetPhysicalDeviceSurfaceSupportKHR(backend->physical_device,
                                             i,
                                             backend->surface,
                                             &present_supported);

        if ((queue_families[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) &&
            present_supported) {
            backend->graphics_queue_family = i;
            break;
        }
    }

    free(queue_families);

    if (backend->graphics_queue_family == UINT32_MAX) {
        fprintf(stderr, "No suitable graphics/present queue family\n");
        render_backend_destroy(backend);
        return NULL;
    }

    /* -------------------------------------------------- */
    /* Device                                             */
    /* -------------------------------------------------- */
    float queue_priority = 1.0f;

    VkDeviceQueueCreateInfo queue_info = {0};
    queue_info.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queue_info.queueFamilyIndex = backend->graphics_queue_family;
    queue_info.queueCount = 1;
    queue_info.pQueuePriorities = &queue_priority;

    const char *device_extensions[] = {
        VK_KHR_SWAPCHAIN_EXTENSION_NAME
    };

    VkDeviceCreateInfo device_info = {0};
    device_info.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    device_info.queueCreateInfoCount = 1;
    device_info.pQueueCreateInfos = &queue_info;
    device_info.enabledExtensionCount = 1;
    device_info.ppEnabledExtensionNames = device_extensions;

    res = vkCreateDevice(backend->physical_device, &device_info, NULL, &backend->device);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateDevice -> %s\n", vk_result_name(res));
        render_backend_destroy(backend);
        return NULL;
    }

    vkGetDeviceQueue(backend->device,
                     backend->graphics_queue_family,
                     0,
                     &backend->graphics_queue);

    /* -------------------------------------------------- */
    /* Swapchain                                          */
    /* -------------------------------------------------- */
    VkSurfaceCapabilitiesKHR caps;
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR(backend->physical_device,
                                              backend->surface,
                                              &caps);

    uint32_t format_count = 0;
    vkGetPhysicalDeviceSurfaceFormatsKHR(backend->physical_device,
                                         backend->surface,
                                         &format_count,
                                         NULL);

    VkSurfaceFormatKHR *formats =
        (VkSurfaceFormatKHR *)malloc(sizeof(VkSurfaceFormatKHR) * format_count);

    vkGetPhysicalDeviceSurfaceFormatsKHR(backend->physical_device,
                                         backend->surface,
                                         &format_count,
                                         formats);

    backend->swapchain_format = formats[0].format;
    free(formats);

    if (caps.currentExtent.width != UINT32_MAX) {
        backend->swapchain_extent = caps.currentExtent;
    } else {
        backend->swapchain_extent.width = 800;
        backend->swapchain_extent.height = 600;
    }

    backend->image_count = caps.minImageCount + 1;
    if (caps.maxImageCount > 0 && backend->image_count > caps.maxImageCount) {
        backend->image_count = caps.maxImageCount;
    }

    VkSwapchainCreateInfoKHR swapchain_info = {0};
    swapchain_info.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
    swapchain_info.surface = backend->surface;
    swapchain_info.minImageCount = backend->image_count;
    swapchain_info.imageFormat = backend->swapchain_format;
    swapchain_info.imageColorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
    swapchain_info.imageExtent = backend->swapchain_extent;
    swapchain_info.imageArrayLayers = 1;
    swapchain_info.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
    swapchain_info.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
    swapchain_info.preTransform = caps.currentTransform;
    swapchain_info.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
    swapchain_info.presentMode = VK_PRESENT_MODE_FIFO_KHR;
    swapchain_info.clipped = VK_TRUE;

    res = vkCreateSwapchainKHR(backend->device, &swapchain_info, NULL, &backend->swapchain);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateSwapchainKHR -> %s\n", vk_result_name(res));
        render_backend_destroy(backend);
        return NULL;
    }

    vkGetSwapchainImagesKHR(backend->device, backend->swapchain, &backend->image_count, NULL);
    backend->images =
        (VkImage *)malloc(sizeof(VkImage) * backend->image_count);
    backend->image_views =
        (VkImageView *)calloc(backend->image_count, sizeof(VkImageView));
    backend->framebuffers =
        (VkFramebuffer *)calloc(backend->image_count, sizeof(VkFramebuffer));
    backend->command_buffers =
        (VkCommandBuffer *)calloc(backend->image_count, sizeof(VkCommandBuffer));

    vkGetSwapchainImagesKHR(backend->device,
                            backend->swapchain,
                            &backend->image_count,
                            backend->images);

    for (uint32_t i = 0; i < backend->image_count; ++i) {
        VkImageViewCreateInfo view_info = {0};
        view_info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
        view_info.image = backend->images[i];
        view_info.viewType = VK_IMAGE_VIEW_TYPE_2D;
        view_info.format = backend->swapchain_format;
        view_info.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        view_info.subresourceRange.levelCount = 1;
        view_info.subresourceRange.layerCount = 1;

        res = vkCreateImageView(backend->device, &view_info, NULL, &backend->image_views[i]);
        if (res != VK_SUCCESS) {
            fprintf(stderr, "vkCreateImageView(swapchain) -> %s\n", vk_result_name(res));
            render_backend_destroy(backend);
            return NULL;
        }
    }

    /* -------------------------------------------------- */
    /* Render pass                                        */
    /* -------------------------------------------------- */
    VkAttachmentDescription color_attachment = {0};
    color_attachment.format = backend->swapchain_format;
    color_attachment.samples = VK_SAMPLE_COUNT_1_BIT;
    color_attachment.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
    color_attachment.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
    color_attachment.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    color_attachment.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

    VkAttachmentReference color_ref = {0};
    color_ref.attachment = 0;
    color_ref.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

    VkSubpassDescription subpass = {0};
    subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
    subpass.colorAttachmentCount = 1;
    subpass.pColorAttachments = &color_ref;

    VkRenderPassCreateInfo render_pass_info = {0};
    render_pass_info.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
    render_pass_info.attachmentCount = 1;
    render_pass_info.pAttachments = &color_attachment;
    render_pass_info.subpassCount = 1;
    render_pass_info.pSubpasses = &subpass;

    res = vkCreateRenderPass(backend->device, &render_pass_info, NULL, &backend->render_pass);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateRenderPass -> %s\n", vk_result_name(res));
        render_backend_destroy(backend);
        return NULL;
    }

    /* -------------------------------------------------- */
    /* Framebuffers                                       */
    /* -------------------------------------------------- */
    for (uint32_t i = 0; i < backend->image_count; ++i) {
        VkImageView attachments[] = { backend->image_views[i] };

        VkFramebufferCreateInfo fb_info = {0};
        fb_info.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
        fb_info.renderPass = backend->render_pass;
        fb_info.attachmentCount = 1;
        fb_info.pAttachments = attachments;
        fb_info.width = backend->swapchain_extent.width;
        fb_info.height = backend->swapchain_extent.height;
        fb_info.layers = 1;

        res = vkCreateFramebuffer(backend->device, &fb_info, NULL, &backend->framebuffers[i]);
        if (res != VK_SUCCESS) {
            fprintf(stderr, "vkCreateFramebuffer -> %s\n", vk_result_name(res));
            render_backend_destroy(backend);
            return NULL;
        }
    }

    /* -------------------------------------------------- */
    /* Buffers                                            */
    /* -------------------------------------------------- */
    if (!create_buffer(backend,
                       MAX_VERTEX_BYTES,
                       VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
                       VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
                       VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                       &backend->vertex_buffer,
                       &backend->vertex_buffer_memory)) {
        render_backend_destroy(backend);
        return NULL;
    }

    if (!create_buffer(backend,
                       MAX_TEXT_VERTEX_BYTES,
                       VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
                       VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
                       VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                       &backend->text_vertex_buffer,
                       &backend->text_vertex_buffer_memory)) {
        render_backend_destroy(backend);
        return NULL;
    }

    /* -------------------------------------------------- */
    /* Atlas + descriptors                                */
    /* -------------------------------------------------- */
    if (!load_font_atlas(backend)) {
        render_backend_destroy(backend);
        return NULL;
    }

    if (!create_descriptor_objects(backend)) {
        render_backend_destroy(backend);
        return NULL;
    }

    /* -------------------------------------------------- */
    /* Command pool + buffers                             */
    /* -------------------------------------------------- */
    VkCommandPoolCreateInfo pool_info = {0};
    pool_info.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    pool_info.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
    pool_info.queueFamilyIndex = backend->graphics_queue_family;

    res = vkCreateCommandPool(backend->device, &pool_info, NULL, &backend->command_pool);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkCreateCommandPool -> %s\n", vk_result_name(res));
        render_backend_destroy(backend);
        return NULL;
    }

    VkCommandBufferAllocateInfo cmd_alloc = {0};
    cmd_alloc.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    cmd_alloc.commandPool = backend->command_pool;
    cmd_alloc.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    cmd_alloc.commandBufferCount = backend->image_count;

    res = vkAllocateCommandBuffers(backend->device,
                                   &cmd_alloc,
                                   backend->command_buffers);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkAllocateCommandBuffers -> %s\n", vk_result_name(res));
        render_backend_destroy(backend);
        return NULL;
    }

    /* -------------------------------------------------- */
    /* Sync                                               */
    /* -------------------------------------------------- */
    VkSemaphoreCreateInfo sem_info = {0};
    sem_info.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;

    VkFenceCreateInfo fence_info = {0};
    fence_info.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    fence_info.flags = VK_FENCE_CREATE_SIGNALED_BIT;

    res = vkCreateSemaphore(backend->device, &sem_info, NULL, &backend->image_available_semaphore);
    if (res != VK_SUCCESS) {
        render_backend_destroy(backend);
        return NULL;
    }

    res = vkCreateSemaphore(backend->device, &sem_info, NULL, &backend->render_finished_semaphore);
    if (res != VK_SUCCESS) {
        render_backend_destroy(backend);
        return NULL;
    }

    res = vkCreateFence(backend->device, &fence_info, NULL, &backend->in_flight_fence);
    if (res != VK_SUCCESS) {
        render_backend_destroy(backend);
        return NULL;
    }

    /* -------------------------------------------------- */
    /* Pipelines                                          */
    /* -------------------------------------------------- */

    /* Rect pipeline */
    {
        VkShaderModule vert = create_shader_module(backend, "rect.vert.spv");
        VkShaderModule frag = create_shader_module(backend, "rect.frag.spv");

        if (vert == VK_NULL_HANDLE || frag == VK_NULL_HANDLE) {
            fprintf(stderr, "runtime asset error: failed to load required rectangle shaders\n");
            if (vert) vkDestroyShaderModule(backend->device, vert, NULL);
            if (frag) vkDestroyShaderModule(backend->device, frag, NULL);
            render_backend_destroy(backend);
            return NULL;
        }

        VkPushConstantRange push_range = {0};
        push_range.stageFlags = VK_SHADER_STAGE_VERTEX_BIT;
        push_range.size = sizeof(PushConstants);

        VkPipelineLayoutCreateInfo layout_info = {0};
        layout_info.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
        layout_info.pushConstantRangeCount = 1;
        layout_info.pPushConstantRanges = &push_range;

        res = vkCreatePipelineLayout(backend->device,
                                     &layout_info,
                                     NULL,
                                     &backend->rect_pipeline_layout);
        if (res != VK_SUCCESS) {
            fprintf(stderr, "vkCreatePipelineLayout(rect) -> %s\n", vk_result_name(res));
            if (vert) vkDestroyShaderModule(backend->device, vert, NULL);
            if (frag) vkDestroyShaderModule(backend->device, frag, NULL);
            render_backend_destroy(backend);
            return NULL;
        }

        VkPipelineShaderStageCreateInfo stages[2] = {0};

        stages[0].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
        stages[0].stage = VK_SHADER_STAGE_VERTEX_BIT;
        stages[0].module = vert;
        stages[0].pName = "main";

        stages[1].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
        stages[1].stage = VK_SHADER_STAGE_FRAGMENT_BIT;
        stages[1].module = frag;
        stages[1].pName = "main";

        VkVertexInputBindingDescription binding = {0};
        binding.binding = 0;
        binding.stride = sizeof(RectVertex);
        binding.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;

        VkVertexInputAttributeDescription attrs[2] = {0};

        attrs[0].binding = 0;
        attrs[0].location = 0;
        attrs[0].format = VK_FORMAT_R32G32_SFLOAT;
        attrs[0].offset = offsetof(RectVertex, pos);

        attrs[1].binding = 0;
        attrs[1].location = 1;
        attrs[1].format = VK_FORMAT_R32G32B32_SFLOAT;
        attrs[1].offset = offsetof(RectVertex, color);

        VkPipelineVertexInputStateCreateInfo vertex_input = {0};
        vertex_input.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
        vertex_input.vertexBindingDescriptionCount = 1;
        vertex_input.pVertexBindingDescriptions = &binding;
        vertex_input.vertexAttributeDescriptionCount = 2;
        vertex_input.pVertexAttributeDescriptions = attrs;

        VkPipelineInputAssemblyStateCreateInfo ia = {0};
        ia.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
        ia.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;

        VkPipelineViewportStateCreateInfo viewport_state = {0};
        viewport_state.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
        viewport_state.viewportCount = 1;
        viewport_state.scissorCount = 1;

        VkPipelineRasterizationStateCreateInfo raster = {0};
        raster.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
        raster.polygonMode = VK_POLYGON_MODE_FILL;
        raster.cullMode = VK_CULL_MODE_NONE;
        raster.frontFace = VK_FRONT_FACE_CLOCKWISE;
        raster.lineWidth = 1.0f;

        VkPipelineMultisampleStateCreateInfo msaa = {0};
        msaa.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
        msaa.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;

        VkPipelineColorBlendAttachmentState blend_attachment = {0};
        blend_attachment.colorWriteMask =
            VK_COLOR_COMPONENT_R_BIT |
            VK_COLOR_COMPONENT_G_BIT |
            VK_COLOR_COMPONENT_B_BIT |
            VK_COLOR_COMPONENT_A_BIT;

        VkPipelineColorBlendStateCreateInfo blend = {0};
        blend.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
        blend.attachmentCount = 1;
        blend.pAttachments = &blend_attachment;

        VkDynamicState dyn_states[] = {
            VK_DYNAMIC_STATE_VIEWPORT,
            VK_DYNAMIC_STATE_SCISSOR
        };

        VkPipelineDynamicStateCreateInfo dynamic = {0};
        dynamic.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
        dynamic.dynamicStateCount = 2;
        dynamic.pDynamicStates = dyn_states;

        VkGraphicsPipelineCreateInfo pipeline_info = {0};
        pipeline_info.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
        pipeline_info.stageCount = 2;
        pipeline_info.pStages = stages;
        pipeline_info.pVertexInputState = &vertex_input;
        pipeline_info.pInputAssemblyState = &ia;
        pipeline_info.pViewportState = &viewport_state;
        pipeline_info.pRasterizationState = &raster;
        pipeline_info.pMultisampleState = &msaa;
        pipeline_info.pColorBlendState = &blend;
        pipeline_info.pDynamicState = &dynamic;
        pipeline_info.layout = backend->rect_pipeline_layout;
        pipeline_info.renderPass = backend->render_pass;

        res = vkCreateGraphicsPipelines(backend->device,
                                        VK_NULL_HANDLE,
                                        1,
                                        &pipeline_info,
                                        NULL,
                                        &backend->rect_pipeline);

        vkDestroyShaderModule(backend->device, vert, NULL);
        vkDestroyShaderModule(backend->device, frag, NULL);

        if (res != VK_SUCCESS) {
            fprintf(stderr, "vkCreateGraphicsPipelines(rect) -> %s\n", vk_result_name(res));
            render_backend_destroy(backend);
            return NULL;
        }
    }

    /* Text pipeline */
    {
        VkShaderModule vert = create_shader_module(backend, "text.vert.spv");
        VkShaderModule frag = create_shader_module(backend, "text.frag.spv");

        if (vert == VK_NULL_HANDLE || frag == VK_NULL_HANDLE) {
            fprintf(stderr, "runtime asset error: failed to load required text shaders\n");
            if (vert) vkDestroyShaderModule(backend->device, vert, NULL);
            if (frag) vkDestroyShaderModule(backend->device, frag, NULL);
            render_backend_destroy(backend);
            return NULL;
        }

        VkPushConstantRange push_range = {0};
        push_range.stageFlags = VK_SHADER_STAGE_VERTEX_BIT;
        push_range.size = sizeof(PushConstants);

        VkPipelineLayoutCreateInfo layout_info = {0};
        layout_info.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
        layout_info.setLayoutCount = 1;
        layout_info.pSetLayouts = &backend->text_descriptor_set_layout;
        layout_info.pushConstantRangeCount = 1;
        layout_info.pPushConstantRanges = &push_range;

        res = vkCreatePipelineLayout(backend->device,
                                     &layout_info,
                                     NULL,
                                     &backend->text_pipeline_layout);
        if (res != VK_SUCCESS) {
            fprintf(stderr, "vkCreatePipelineLayout(text) -> %s\n", vk_result_name(res));
            if (vert) vkDestroyShaderModule(backend->device, vert, NULL);
            if (frag) vkDestroyShaderModule(backend->device, frag, NULL);
            render_backend_destroy(backend);
            return NULL;
        }

        VkPipelineShaderStageCreateInfo stages[2] = {0};

        stages[0].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
        stages[0].stage = VK_SHADER_STAGE_VERTEX_BIT;
        stages[0].module = vert;
        stages[0].pName = "main";

        stages[1].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
        stages[1].stage = VK_SHADER_STAGE_FRAGMENT_BIT;
        stages[1].module = frag;
        stages[1].pName = "main";

        VkVertexInputBindingDescription binding = {0};
        binding.binding = 0;
        binding.stride = sizeof(TextVertex);
        binding.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;

        VkVertexInputAttributeDescription attrs[3] = {0};

        attrs[0].binding = 0;
        attrs[0].location = 0;
        attrs[0].format = VK_FORMAT_R32G32_SFLOAT;
        attrs[0].offset = offsetof(TextVertex, pos);

        attrs[1].binding = 0;
        attrs[1].location = 1;
        attrs[1].format = VK_FORMAT_R32G32_SFLOAT;
        attrs[1].offset = offsetof(TextVertex, uv);

        attrs[2].binding = 0;
        attrs[2].location = 2;
        attrs[2].format = VK_FORMAT_R32G32B32_SFLOAT;
        attrs[2].offset = offsetof(TextVertex, color);

        VkPipelineVertexInputStateCreateInfo vertex_input = {0};
        vertex_input.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
        vertex_input.vertexBindingDescriptionCount = 1;
        vertex_input.pVertexBindingDescriptions = &binding;
        vertex_input.vertexAttributeDescriptionCount = 3;
        vertex_input.pVertexAttributeDescriptions = attrs;

        VkPipelineInputAssemblyStateCreateInfo ia = {0};
        ia.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
        ia.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;

        VkPipelineViewportStateCreateInfo viewport_state = {0};
        viewport_state.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
        viewport_state.viewportCount = 1;
        viewport_state.scissorCount = 1;

        VkPipelineRasterizationStateCreateInfo raster = {0};
        raster.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
        raster.polygonMode = VK_POLYGON_MODE_FILL;
        raster.cullMode = VK_CULL_MODE_NONE;
        raster.frontFace = VK_FRONT_FACE_CLOCKWISE;
        raster.lineWidth = 1.0f;

        VkPipelineMultisampleStateCreateInfo msaa = {0};
        msaa.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
        msaa.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;

        VkPipelineColorBlendAttachmentState blend_attachment = {0};
        blend_attachment.blendEnable = VK_TRUE;
        blend_attachment.srcColorBlendFactor = VK_BLEND_FACTOR_SRC_ALPHA;
        blend_attachment.dstColorBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
        blend_attachment.colorBlendOp = VK_BLEND_OP_ADD;
        blend_attachment.srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE;
        blend_attachment.dstAlphaBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
        blend_attachment.alphaBlendOp = VK_BLEND_OP_ADD;
        blend_attachment.colorWriteMask =
            VK_COLOR_COMPONENT_R_BIT |
            VK_COLOR_COMPONENT_G_BIT |
            VK_COLOR_COMPONENT_B_BIT |
            VK_COLOR_COMPONENT_A_BIT;

        VkPipelineColorBlendStateCreateInfo blend = {0};
        blend.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
        blend.attachmentCount = 1;
        blend.pAttachments = &blend_attachment;

        VkDynamicState dyn_states[] = {
            VK_DYNAMIC_STATE_VIEWPORT,
            VK_DYNAMIC_STATE_SCISSOR
        };

        VkPipelineDynamicStateCreateInfo dynamic = {0};
        dynamic.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
        dynamic.dynamicStateCount = 2;
        dynamic.pDynamicStates = dyn_states;

        VkGraphicsPipelineCreateInfo pipeline_info = {0};
        pipeline_info.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
        pipeline_info.stageCount = 2;
        pipeline_info.pStages = stages;
        pipeline_info.pVertexInputState = &vertex_input;
        pipeline_info.pInputAssemblyState = &ia;
        pipeline_info.pViewportState = &viewport_state;
        pipeline_info.pRasterizationState = &raster;
        pipeline_info.pMultisampleState = &msaa;
        pipeline_info.pColorBlendState = &blend;
        pipeline_info.pDynamicState = &dynamic;
        pipeline_info.layout = backend->text_pipeline_layout;
        pipeline_info.renderPass = backend->render_pass;

        res = vkCreateGraphicsPipelines(backend->device,
                                        VK_NULL_HANDLE,
                                        1,
                                        &pipeline_info,
                                        NULL,
                                        &backend->text_pipeline);

        vkDestroyShaderModule(backend->device, vert, NULL);
        vkDestroyShaderModule(backend->device, frag, NULL);

        if (res != VK_SUCCESS) {
            fprintf(stderr, "vkCreateGraphicsPipelines(text) -> %s\n", vk_result_name(res));
            render_backend_destroy(backend);
            return NULL;
        }
    }

    return backend;
}

int render_backend_begin_frame(RenderBackend *backend,
                               int width,
                               int height)
{
    if (!backend) {
        fprintf(stderr, "render_backend_begin_frame: backend is null\n");
        return 0;
    }

    backend->frame_active = 0;
    backend->frame_rendered = 0;

    if (width <= 0 || height <= 0) {
        backend->swapchain_needs_recreate = 1;
        return 1;
    }

    if (backend->swapchain_needs_recreate || backend->swapchain == VK_NULL_HANDLE) {
        if (!recreate_swapchain(backend)) {
            if (backend_framebuffer_is_zero(backend)) {
                return 1;
            }
            fprintf(stderr, "render_backend_begin_frame: swapchain recreation failed\n");
            return 0;
        }
    }

    VkResult res = vkWaitForFences(backend->device, 1, &backend->in_flight_fence, VK_TRUE, UINT64_MAX);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkWaitForFences -> %s\n", vk_result_name(res));
        return 0;
    }

    res = vkAcquireNextImageKHR(backend->device,
                                backend->swapchain,
                                UINT64_MAX,
                                backend->image_available_semaphore,
                                VK_NULL_HANDLE,
                                &backend->current_image_index);
    if (res == VK_ERROR_OUT_OF_DATE_KHR) {
        fprintf(stderr, "vkAcquireNextImageKHR -> VK_ERROR_OUT_OF_DATE_KHR; recreating swapchain\n");
        backend->swapchain_needs_recreate = 1;
        if (!recreate_swapchain(backend) && !backend_framebuffer_is_zero(backend)) {
            fprintf(stderr, "render_backend_begin_frame: out-of-date swapchain recovery failed\n");
            return 0;
        }
        return 1;
    }

    if (res == VK_SUBOPTIMAL_KHR) {
        backend->swapchain_needs_recreate = 1;
    } else if (res != VK_SUCCESS) {
        fprintf(stderr, "vkAcquireNextImageKHR -> %s\n", vk_result_name(res));
        return 0;
    }

    backend->frame_active = 1;
    return 1;
}

int render_backend_draw_editor(RenderBackend *backend)
{
    if (!backend) {
        fprintf(stderr, "render_backend_draw_editor: backend is null\n");
        return 0;
    }

    if (!backend->frame_active) {
        return 1;
    }

    uint32_t image_index = backend->current_image_index;

    if (!record_command_buffer(backend,
                               backend->command_buffers[image_index],
                               image_index,
                               (int)backend->swapchain_extent.width,
                               (int)backend->swapchain_extent.height)) {
        backend->frame_active = 0;
        return 0;
    }

    return 1;
}

int render_backend_end_frame(RenderBackend *backend)
{
    if (!backend) {
        fprintf(stderr, "render_backend_end_frame: backend is null\n");
        return 0;
    }

    if (!backend->frame_active) {
        return 1;
    }

    uint32_t image_index = backend->current_image_index;

    VkPipelineStageFlags wait_stage = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;

    VkSubmitInfo submit = {0};
    submit.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    submit.waitSemaphoreCount = 1;
    submit.pWaitSemaphores = &backend->image_available_semaphore;
    submit.pWaitDstStageMask = &wait_stage;
    submit.commandBufferCount = 1;
    submit.pCommandBuffers = &backend->command_buffers[image_index];
    submit.signalSemaphoreCount = 1;
    submit.pSignalSemaphores = &backend->render_finished_semaphore;

    VkResult res = vkResetFences(backend->device, 1, &backend->in_flight_fence);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkResetFences -> %s\n", vk_result_name(res));
        backend->frame_active = 0;
        return 0;
    }

    res = vkQueueSubmit(backend->graphics_queue, 1, &submit, backend->in_flight_fence);
    if (res != VK_SUCCESS) {
        fprintf(stderr, "vkQueueSubmit -> %s\n", vk_result_name(res));
        backend->frame_active = 0;
        return 0;
    }

    VkPresentInfoKHR present = {0};
    present.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
    present.waitSemaphoreCount = 1;
    present.pWaitSemaphores = &backend->render_finished_semaphore;
    present.swapchainCount = 1;
    present.pSwapchains = &backend->swapchain;
    present.pImageIndices = &image_index;

    res = vkQueuePresentKHR(backend->graphics_queue, &present);
    if (res == VK_ERROR_OUT_OF_DATE_KHR || res == VK_SUBOPTIMAL_KHR) {
        fprintf(stderr, "vkQueuePresentKHR -> %s; recreating swapchain before the next frame\n",
                vk_result_name(res));
        backend->swapchain_needs_recreate = 1;
    } else if (res != VK_SUCCESS) {
        fprintf(stderr, "vkQueuePresentKHR -> %s\n", vk_result_name(res));
        backend->frame_active = 0;
        return 0;
    }

    backend->frame_active = 0;
    backend->frame_rendered = 1;
    return 1;
}

void render_backend_request_swapchain_recreate(RenderBackend *backend)
{
    if (backend) {
        backend->swapchain_needs_recreate = 1;
    }
}

int render_backend_frame_was_rendered(const RenderBackend *backend)
{
    return backend && backend->frame_rendered;
}

unsigned render_backend_swapchain_recreate_count(const RenderBackend *backend)
{
    return backend ? backend->swapchain_recreate_count : 0u;
}

unsigned render_backend_font_atlas_upload_count(const RenderBackend *backend)
{
    return backend ? backend->font_atlas_upload_count : 0u;
}

unsigned render_backend_font_atlas_last_upload_width(const RenderBackend *backend)
{
    return backend ? backend->font_atlas_last_upload_width : 0u;
}

unsigned render_backend_font_atlas_last_upload_height(const RenderBackend *backend)
{
    return backend ? backend->font_atlas_last_upload_height : 0u;
}

unsigned render_backend_font_atlas_last_upload_nonzero_bytes(const RenderBackend *backend)
{
    return backend ? backend->font_atlas_last_upload_nonzero_bytes : 0u;
}

uint32_t render_backend_font_atlas_last_upload_checksum(const RenderBackend *backend)
{
    return backend ? backend->font_atlas_last_upload_checksum : 0u;
}

int render_backend_font_atlas_dirty(const RenderBackend *backend)
{
    (void)backend;
    return editor_font_atlas_dirty();
}

unsigned render_backend_last_visual_rect_count(const RenderBackend *backend)
{
    return backend ? backend->last_visual_rect_count : 0u;
}

unsigned render_backend_last_visual_glyph_count(const RenderBackend *backend)
{
    return backend ? backend->last_visual_glyph_count : 0u;
}

uint32_t render_backend_last_visual_geometry_checksum(const RenderBackend *backend)
{
    return backend ? backend->last_visual_geometry_checksum : 0u;
}

uint32_t render_backend_last_visual_color_checksum(const RenderBackend *backend)
{
    return backend ? backend->last_visual_color_checksum : 0u;
}

void render_backend_destroy(RenderBackend *backend)
{
    if (!backend) {
        return;
    }

    if (backend->device != VK_NULL_HANDLE) {
        vkDeviceWaitIdle(backend->device);
    }

    if (backend->in_flight_fence) {
        vkDestroyFence(backend->device, backend->in_flight_fence, NULL);
    }

    if (backend->image_available_semaphore) {
        vkDestroySemaphore(backend->device, backend->image_available_semaphore, NULL);
    }

    if (backend->render_finished_semaphore) {
        vkDestroySemaphore(backend->device, backend->render_finished_semaphore, NULL);
    }

    destroy_swapchain_frame_resources(backend);

    if (backend->swapchain) {
        vkDestroySwapchainKHR(backend->device, backend->swapchain, NULL);
        backend->swapchain = VK_NULL_HANDLE;
    }

    if (backend->command_pool) {
        vkDestroyCommandPool(backend->device, backend->command_pool, NULL);
    }

    if (backend->vertex_buffer) {
        vkDestroyBuffer(backend->device, backend->vertex_buffer, NULL);
    }

    if (backend->vertex_buffer_memory) {
        vkFreeMemory(backend->device, backend->vertex_buffer_memory, NULL);
    }

    if (backend->text_vertex_buffer) {
        vkDestroyBuffer(backend->device, backend->text_vertex_buffer, NULL);
    }

    if (backend->text_vertex_buffer_memory) {
        vkFreeMemory(backend->device, backend->text_vertex_buffer_memory, NULL);
    }

    if (backend->atlas_sampler) {
        vkDestroySampler(backend->device, backend->atlas_sampler, NULL);
    }

    if (backend->atlas_image_view) {
        vkDestroyImageView(backend->device, backend->atlas_image_view, NULL);
    }

    if (backend->atlas_image) {
        vkDestroyImage(backend->device, backend->atlas_image, NULL);
    }

    if (backend->atlas_image_memory) {
        vkFreeMemory(backend->device, backend->atlas_image_memory, NULL);
    }

    if (backend->descriptor_pool) {
        vkDestroyDescriptorPool(backend->device, backend->descriptor_pool, NULL);
    }

    if (backend->text_descriptor_set_layout) {
        vkDestroyDescriptorSetLayout(backend->device,
                                     backend->text_descriptor_set_layout,
                                     NULL);
    }

    if (backend->rect_pipeline) {
        vkDestroyPipeline(backend->device, backend->rect_pipeline, NULL);
    }

    if (backend->rect_pipeline_layout) {
        vkDestroyPipelineLayout(backend->device, backend->rect_pipeline_layout, NULL);
    }

    if (backend->text_pipeline) {
        vkDestroyPipeline(backend->device, backend->text_pipeline, NULL);
    }

    if (backend->text_pipeline_layout) {
        vkDestroyPipelineLayout(backend->device, backend->text_pipeline_layout, NULL);
    }

    if (backend->render_pass) {
        vkDestroyRenderPass(backend->device, backend->render_pass, NULL);
    }

    if (backend->device) {
        vkDestroyDevice(backend->device, NULL);
    }

    if (backend->surface) {
        vkDestroySurfaceKHR(backend->instance, backend->surface, NULL);
    }

    if (backend->instance) {
        vkDestroyInstance(backend->instance, NULL);
    }

    free(backend);
}
