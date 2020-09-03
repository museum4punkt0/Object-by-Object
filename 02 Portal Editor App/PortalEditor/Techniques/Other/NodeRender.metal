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


vertex out_vertex_t mask_vertex(custom_vertex_t in [[stage_in]],
                                        constant custom_node_t3& scn_node [[buffer(0)]])
{
    out_vertex_t out;
    out.position = scn_node.modelViewProjectionTransform * float4(in.position.xyz, 1.0);
    return out;
};

fragment half4 mask_fragment(out_vertex_t in [[stage_in]],
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

vertex out_vertex_t combine_vertex(custom_vertex_t in [[stage_in]])
{
    out_vertex_t out;
    out.position = in.position;
    out.uv = float2( (in.position.x + 1.0) * 0.5, 1.0 - (in.position.y + 1.0) * 0.5 );
    return out;
};


fragment half4 combine_fragment(out_vertex_t vert [[stage_in]],
                                          texture2d<float, access::sample> colorSampler [[texture(0)]],
                                          texture2d<float, access::sample> maskSampler [[texture(1)]])
{
    
    float4 fragmentColor = colorSampler.sample( s, vert.uv);
    float4 maskColor = maskSampler.sample(s, vert.uv);
    
    // Don't render glow on top of the object itself
    if ( maskColor.g > 0.5 ) {
        return half4(fragmentColor);
    }
    
    float3 glowColor = float3(1.0, 1.0, 0.0);
    
    float alpha = maskColor.r;
    float3 out = fragmentColor.rgb * ( 1.0 - alpha ) + alpha * glowColor;
    return half4( float4(out.rgb, 1.0) );
    
}

fragment half4 combine_sepia_fragment(out_vertex_t vert [[stage_in]],
                                          texture2d<float, access::sample> colorSampler [[texture(0)]],
                                          texture2d<float, access::sample> maskSampler [[texture(1)]])
{
    
//    float4 fragmentColor = colorSampler.sample( s, vert.uv);
    float mask = maskSampler.sample(s, vert.uv).r;
    
	float4 in = colorSampler.sample( s, vert.uv);
	
	float sepiaR = (in.r * 0.393 + in.g * 0.769 + in.b * 0.189);
	float sepiaG = (in.r * 0.349 + in.g * 0.686 + in.b * 0.168);
	float sepiaB = (in.r * 0.272 + in.g * 0.534 + in.b * 0.131);
    float4 sepia = float4(sepiaR, sepiaG, sepiaB, 1.0);
	
	float4 out = float4();
	if (mask == 0) {
		out = in;
	}
	else if (mask == 1) {
		out = sepia;
	}
	else {
		out = float4(mask*sepia + (1-mask)*in);
	}
	
    return half4( float4(out.rgb, 1.0) );
    
}


///// Blur //////

vertex out_vertex_t blur_vertex(custom_vertex_t in [[stage_in]])
{
    out_vertex_t out;
    out.position = in.position;
    out.uv = float2( (in.position.x + 1.0) * 0.5, 1.0 - (in.position.y + 1.0) * 0.5 );
    return out;
};

// http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
//constant float offset[] = { 0.0, 1.0, 2.0, 3.0, 4.0 };
//constant float weight[] = { 0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162 };
//constant float weight[] = { 0.212958111335951, 0.202805100815117, 0.187475596412411, 0.166595782613354, 0.140939625926176, 0.1125, 0.0840603740738243, 0.0584042173866457, 0.0375244035875892, 0.0221948991848835, 0.0120418886640485 };
constant float weight[] = { 0.0471977247974987, 0.0462032527297711, 0.044947521725062, 0.0434024643724845, 0.041550056723414, 0.0393859807142219, 0.036922481378532, 0.0341898793219914, 0.0312363292282968, 0.0281256422928348, 0.0249332791618453, 0.0217409160308557, 0.0186302290953938, 0.0156766790016991, 0.0129440769451585, 0.0104805776094686, 0.00831650160027653, 0.00646409395120602, 0.00491903659862855, 0.00366330559391941, 0.00266883352619184 };
constant int weightSize = 21;

constant float bufferSize = 1024.0;

fragment half4 blur_fragment_h(out_vertex_t vert [[stage_in]],
                                          texture2d<float, access::sample> maskSampler [[texture(0)]])
{
    
    float4 fragmentColor = maskSampler.sample( s, vert.uv);
    float FragmentR = fragmentColor.r * weight[0];
    
    
    for (int i=0; i<weightSize; i++) {
        FragmentR += maskSampler.sample( s, ( vert.uv + float2(float(i), 0.0)/bufferSize ) ).r * weight[i];
        FragmentR += maskSampler.sample( s, ( vert.uv - float2(float(i), 0.0)/bufferSize ) ).r * weight[i];
    }
    return half4(FragmentR, fragmentColor.g, fragmentColor.b, 1.0);
}

fragment half4 blur_fragment_v(out_vertex_t vert [[stage_in]],
                               texture2d<float, access::sample> maskSampler [[texture(0)]])
{
    
    float4 fragmentColor = maskSampler.sample( s, vert.uv);
    float FragmentR = fragmentColor.r * weight[0];
    
    for (int i=0; i<weightSize; i++) {
        FragmentR += maskSampler.sample( s, ( vert.uv + float2(0.0, float(i))/bufferSize ) ).r * weight[i];
        FragmentR += maskSampler.sample( s, ( vert.uv - float2(0.0, float(i))/bufferSize ) ).r * weight[i];
    }
    
    return half4(FragmentR, fragmentColor.g, fragmentColor.b, 1.0);
    
};



vertex out_vertex_t sepia_vertex(custom_vertex_t in [[stage_in]])
{
    out_vertex_t out;
    out.position = in.position;
    out.uv = float2( (in.position.x + 1.0) * 0.5, 1.0 - (in.position.y + 1.0) * 0.5 );
    return out;
};

fragment half4 sepia_fragment(out_vertex_t vert [[stage_in]],
                               texture2d<float, access::sample> maskSampler [[texture(0)]])
{
    
    float4 in = maskSampler.sample( s, vert.uv);
	
	float outR = (in.r * 0.393 + in.g * 0.769 + in.b * 0.189);
	float outG = (in.r * 0.349 + in.g * 0.686 + in.b * 0.168);
	float outB = (in.r * 0.272 + in.g * 0.534 + in.b * 0.131);
	
    return half4(outR, outG, outB, 1.0);
};
