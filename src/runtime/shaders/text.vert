#version 450

layout(push_constant) uniform PushConstants {
    vec2 framebuffer_size;
} pc;

layout(location = 0) in vec2 in_pos;
layout(location = 1) in vec2 in_uv;
layout(location = 2) in vec3 in_color;

layout(location = 0) out vec2 frag_uv;
layout(location = 1) out vec3 frag_color;

void main() {
    vec2 ndc;
    ndc.x = (in_pos.x / pc.framebuffer_size.x) * 2.0 - 1.0;
    ndc.y = (in_pos.y / pc.framebuffer_size.y) * 2.0 - 1.0;

    gl_Position = vec4(ndc, 0.0, 1.0);
    frag_uv = in_uv;
    frag_color = in_color;
}