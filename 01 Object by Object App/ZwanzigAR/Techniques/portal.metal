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

//float4 sepia(float4 in) {
////	float3 yellow = float3(1, 0.8627, 0.5059);
////	float3 darkBrown = float3(0.5765, 0.4118, 0.0078);
////	float3 darkPurple = float3(0.2118, 0.0157, 0.1333);
////	float3 orange = float3(1, 0.6510, 0.1294);
//
//	half3 mediumOrange = half3(0.78, 0.47, 0);
//	half3 darkNavy = half3(0.07, 0.01, 0.16);
//
//	half3 colStart = mediumOrange;
//	half3 colEnd = darkNavy;
//
//	half lum = 0.2 * in.r + 0.7 * in.g + 0.07 * in.b; // Luminance
//
//	half sepiaR = colEnd.r + (colStart.r - colEnd.r) * lum;
//	half sepiaG = colEnd.g + (colStart.g - colEnd.g) * lum;
//	half sepiaB = colStart.b + (colEnd.b - colStart.b) * lum;
//
//	return float4(sepiaR, sepiaG, sepiaB, 1.0);
//}


float4 sepia(float4 in) {
//	float3 yellow = float3(1, 0.8627, 0.5059);
//	float3 darkBrown = float3(0.5765, 0.4118, 0.0078);
//	float3 darkPurple = float3(0.2118, 0.0157, 0.1333);
//	float3 orange = float3(1, 0.6510, 0.1294);

	float3 mediumOrange = float3(0.78, 0.47, 0);
	float3 darkNavy = float3(0.07, 0.01, 0.16);

	float3 colStart = mediumOrange;
	float3 colEnd = darkNavy;

	float lum = 0.2 * in.r + 0.7 * in.g + 0.07 * in.b; // Luminance

	float sepiaR = colEnd.r + (colStart.r - colEnd.r) * lum;
	float sepiaG = colEnd.g + (colStart.g - colEnd.g) * lum;
	float sepiaB = colStart.b + (colEnd.b - colStart.b) * lum;

	return float4(sepiaR, sepiaG, sepiaB, 1.0);
}

float4 sepiaRed(float4 in) {
	return float4(0.8, in.g, in.b, 1.0);
}

float4 sepiaBlue(float4 in) {
	return float4(in.r, in.g, 0.8, 1.0);
}

float4 sepiaGreen(float4 in) {
	return float4(in.r, 0.8, in.b, 1.0);
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

	if (0 < portalDepth && abs(portalDepth-objectsDepth) < 0.00001) {
		return half4(float4(colorSampler.sample(s, vert.uv).rgb, 1.0));
	}

	if (outside) {
		if (portalDepth == 0) {
			// Everything outside portal (gate and frame) gets cut out
			return half4(0.0);
		}
		
		if (0 < portalDepth && portalDepth < objectsDepth) {
			// Objects in front of portal (gate and frame) get cut out
			return half4(0.0);
		}

		if (0 < objectsDepth && objectsDepth < portalDepth) {
			// Of the rest, leave objects behind the portal unchanged
			return half4(float4(colorSampler.sample(s, vert.uv).rgb, 1.0));
		}
	}
	
	else {
		if (portalDepth < objectsDepth) {
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

