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

constexpr sampler s = sampler(coord::normalized,
r_address::clamp_to_edge,
t_address::repeat,
filter::linear);


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

vertex out_vertex_t depthVertex(custom_vertex_t in [[stage_in]],
                                        constant custom_node_t3& scn_node [[buffer(0)]])
{
    out_vertex_t out;
    out.position = scn_node.modelViewProjectionTransform * float4(in.position.xyz, 1.0);
    return out;
};

fragment half4 depthFragment(out_vertex_t in [[stage_in]],
                                          depth2d<float, access::sample> depthSampler [[texture(0)]])
{
//    constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
	
	return half4(depthSampler.sample(s, in.uv));
};


////////////

float4 sepia(float4 in) {
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
	return float4(sepia.rgb, 1.0);
}

vertex out_vertex_t combineVertex(custom_vertex_t in [[stage_in]])
{
    out_vertex_t out;
    out.position = in.position;
    out.uv = float2( (in.position.x + 1.0) * 0.5, 1.0 - (in.position.y + 1.0) * 0.5 );
    return out;
};


half4 combineFragment(out_vertex_t vert [[stage_in]],
					  texture2d<float, access::sample> colorSampler [[texture(0)]],
//					  texture2d<float, access::sample> colorBackgroundSampler [[texture(1)]],
					  depth2d<float, access::sample> portalDepthSampler [[texture(2)]],
					  depth2d<float, access::sample> objectsDepthSampler [[texture(3)]],
					  bool outside)
{

	
	float objectsDepth = objectsDepthSampler.sample(s, vert.uv);
	float portalDepth = portalDepthSampler.sample(s, vert.uv);
	if (outside) {
		if (portalDepth == 0) {
			// Everything outside portal (gate and frame) gets cut out
			return half4(0.0);
		}
		
		if (0 < portalDepth && portalDepth < objectsDepth) {
			// Objects in front of portal (gate and frame) get cut out
			return half4(0.0);
//			return half4(sepia(colorSampler.sample(s, vert.uv)));
		}

		if (0 < objectsDepth && objectsDepth < portalDepth) {
			// Of the rest, leave objects behind the portal unchanged
			return half4(float4(colorSampler.sample(s, vert.uv).rgb, 1.0));
		}
	}
	
	else {
		if (objectsDepth > portalDepth) {
			// Leave objects (objects and frame) in front of portal unchanged
			return half4(float4(colorSampler.sample(s, vert.uv).rgb, 1.0));
		}
		
		if (objectsDepth < portalDepth) {
			// Cut out portal (gate) including objects that are behind portal (0 < objectsDepth < portalDepth)
			return half4(0.0);
		}
	}
	
    return half4(sepia(colorSampler.sample(s, vert.uv)));
}

fragment half4 combineFragmentInside(out_vertex_t vert [[stage_in]],
									 texture2d<float, access::sample> colorSampler [[texture(0)]],
//									 texture2d<float, access::sample> colorBackgroundSampler [[texture(1)]],
									 depth2d<float, access::sample> portalDepthSampler [[texture(2)]],
									 depth2d<float, access::sample> objectsDepthSampler [[texture(3)]])
{
	return combineFragment(vert, colorSampler//, colorBackgroundSampler
						   , portalDepthSampler, objectsDepthSampler, false);
}

fragment half4 combineFragmentOutside(out_vertex_t vert [[stage_in]],
									  texture2d<float, access::sample> colorSampler [[texture(0)]],
//									  texture2d<float, access::sample> colorBackgroundSampler [[texture(1)]],
									  depth2d<float, access::sample> portalDepthSampler [[texture(2)]],
									  depth2d<float, access::sample> objectsDepthSampler [[texture(3)]])
{
	return combineFragment(vert, colorSampler//, colorBackgroundSampler
						   , portalDepthSampler, objectsDepthSampler, true);
}

