#version 450

layout(set = 0, binding = 0) uniform sampler2D atlas_sampler;

//  Colour glyphs, packed into a sheet of their own. Separate from the atlas
//  above because that one is R8: a single coverage value per pixel, which a
//  picture cannot be squeezed into.
layout(set = 0, binding = 1) uniform sampler2D colour_sampler;

layout(location = 0) in vec2 frag_uv;
layout(location = 1) in vec3 frag_color;
layout(location = 2) in float frag_texture;

layout(location = 0) out vec4 out_color;

void main() {
    if (frag_texture > 0.5) {
        //  A picture carries its own colour and its own alpha; the vertex
        //  colour says nothing about it.
        out_color = texture(colour_sampler, frag_uv);
    } else {
        float alpha = texture(atlas_sampler, frag_uv).r;
        out_color = vec4(frag_color, alpha);
    }
}
