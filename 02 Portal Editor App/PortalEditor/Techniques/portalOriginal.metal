#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct custom_node_t3 {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
};

struct custom_vertex_t
{
    float4 position [[attribute(SCNVertexSemanticPosition)]];
    float4 normal [[attribute(SCNVertexSemanticNormal)]];
};

struct out_vertex_t
{
    float4 position [[position]];
    float2 uv;
};



vertex out_vertex_t maskVertex(custom_vertex_t in [[stage_in]],
                                        constant custom_node_t3& scn_node [[buffer(0)]])
{
    out_vertex_t out;
    out.position = scn_node.modelViewProjectionTransform * float4(in.position.xyz, 1.0);
    return out;
};

fragment half4 maskFragment(out_vertex_t in [[stage_in]],
                                          texture2d<float, access::sample> colorSampler [[texture(0)]])
{
//    constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
    return half4(1.0);
};

////////////

constexpr sampler s = sampler(coord::normalized,
r_address::clamp_to_edge,
t_address::repeat,
filter::linear);

vertex out_vertex_t combineVertex(custom_vertex_t in [[stage_in]])
{
    out_vertex_t out;
    out.position = in.position;
    out.uv = float2( (in.position.x + 1.0) * 0.5, 1.0 - (in.position.y + 1.0) * 0.5 );
    return out;
};


half4 combineFragment(out_vertex_t vert [[stage_in]],
					  texture2d<float, access::sample> colorSampler [[texture(0)]],
					  texture2d<float, access::sample> portalMaskSampler [[texture(1)]],
					  texture2d<float, access::sample> objectsMaskSampler [[texture(2)]],
					  bool outside)
{

	
	if (outside) {
		if (portalMaskSampler.sample(s, vert.uv).r == 0) {
			// Everything outside portal (gate and frame) gets cut out
			return half4(0.0);
		}
		
		if (objectsMaskSampler.sample(s, vert.uv).r == 1) {
			// Of the rest, leave objects unchanged
			return half4(float4(colorSampler.sample(s, vert.uv).rgb, 1.0));
		}
	}
	
	else {
		if (objectsMaskSampler.sample(s, vert.uv).r == 1) {
			// Leave objects (objects and frame) unchanged
			return half4(float4(colorSampler.sample(s, vert.uv).rgb, 1.0));
		}
		
		if (portalMaskSampler.sample(s, vert.uv).r == 1) {
			// Of the rest, cut out portal (gate only)
			return half4(0.0);
		}
	}
	
//
//
//    float portalMask = portalMaskSampler.sample(s, vert.uv).r;
//	float objectsMask = objectsMaskSampler.sample(s, vert.uv).r;
//
//	if (outside) {
//		if (portalMask < 1) {
//			return half4(0.0);
//		}
//	}
//
//
//	if (!outside) {
//		portalMask = 1 - portalMask;
//	}
//
//	if (!outside) {
//		if (portalMask < 1 && objectsMask < 1) {
//			return half4(0.0);
//		}
//	}
//
	float4 in = colorSampler.sample( s, vert.uv);
	
//	float sepiaR = (in.r * 0.393 + in.g * 0.769 + in.b * 0.189);
//	float sepiaG = (in.r * 0.349 + in.g * 0.686 + in.b * 0.168);
//	float sepiaB = (in.r * 0.272 + in.g * 0.534 + in.b * 0.131);
	
	float sepiaR = (in.r * 0.3588 + in.g * 0.7044 + in.b * 0.1368);
	float sepiaG = (in.r * 0.2990 + in.g * 0.5870 + in.b * 0.1140);
	float sepiaB = (in.r * 0.2392 + in.g * 0.4696 + in.b * 0.0912);

//	float sepiaR = (in.r * 0.45 + in.g * 0.825 + in.b * 0.225);
//	float sepiaG = (in.r * 0.35 + in.g * 0.725 + in.b * 0.175);
//	float sepiaB = (in.r * 0.2 + in.g * 0.45 + in.b * 0.1);

	float4 sepia = float4(sepiaR, sepiaG, sepiaB, 1.0);

	
	
	
	
    return half4( float4(sepia.rgb, 1.0) );
}

fragment half4 combineFragmentInside(out_vertex_t vert [[stage_in]],
									 texture2d<float, access::sample> colorSampler [[texture(0)]],
									 texture2d<float, access::sample> portalMaskSampler [[texture(1)]],
									 texture2d<float, access::sample> objectsMaskSampler [[texture(2)]])
{
	return combineFragment(vert, colorSampler, portalMaskSampler, objectsMaskSampler, false);
}

fragment half4 combineFragmentOutside(out_vertex_t vert [[stage_in]],
									  texture2d<float, access::sample> colorSampler [[texture(0)]],
									  texture2d<float, access::sample> portalMaskSampler [[texture(1)]],
									  texture2d<float, access::sample> objectsMaskSampler [[texture(2)]])
{
	return combineFragment(vert, colorSampler, portalMaskSampler, objectsMaskSampler, true);
}

