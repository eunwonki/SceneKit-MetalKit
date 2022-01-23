#include <metal_stdlib>
using namespace metal;

struct NodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewProjectionTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float2x3 boundingBox;
    float depthBufferZ;
};

struct VertexInput {
    float3 position[[attribute(0)]];
    float3 normal[[attribute(1)]];
    float2 uv[[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
}; // = FragmentIn

struct FragmentOut {
    float4 color [[color(0)]];
    float depth [[depth(any)]];
};

vertex VertexOut textureSamplerVertex
(
 VertexInput in [[stage_in]],
 constant NodeBuffer& node [[buffer(1)]]
)
{
    VertexOut out;
    out.position = node.modelViewProjectionTransform * float4(in.position, 1.0);
    out.uv = in.uv;
    return out;
}

fragment FragmentOut textureSamplerFragment
(
 VertexOut in [[ stage_in ]],
 texture2d<float, access::sample> customTexture [[texture(0)]],
 constant NodeBuffer& node [[buffer(1)]]
)
{
    FragmentOut out;
    constexpr sampler textureSampler(coord::normalized, filter::linear, address::repeat);
    out.color = customTexture.sample(textureSampler, in.uv );
    out.depth = node.depthBufferZ;
    return out;
}
