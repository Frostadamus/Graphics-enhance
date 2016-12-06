/*------------------------------------------------------------------------------
						FXAA SHADER
------------------------------------------------------------------------------*/

// Includes the user settings
#include "injFX_Shaders\injFXaaSettings.h"
 // Defines the API to use it with
#define FXAA_HLSL_3 1
// NOTE: This version uses a modified FXAA_GREEN_AS_LUMA 1
#define FXAA_GREEN_AS_LUMA 1
// Includes the Main shader, FXAA 3.11
#include "injFX_Shaders\Fxaa3_11.h"

uniform extern texture gScreenTexture;
uniform extern texture gLumaTexture;

//Definitions: BUFFER_WIDTH, BUFFER_HEIGHT, BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT
sampler screenSampler = sampler_state
{
    Texture = <gScreenTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU = BORDER;
    AddressV = BORDER;
    SRGBTexture = FALSE;
};
sampler lumaSampler = sampler_state
{
    Texture = <gLumaTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU = BORDER;
    AddressV = BORDER;
    SRGBTexture = FALSE;
};

// Includes additional shaders, like Sharpen, Bloom, Tonemap etc.
#include "injFX_Shaders\Post.h"

// FXAA Shader Function
float4 LumaShader( float2 Tex : TEXCOORD0 ) : COLOR0
{
#if(USE_ANTI_ALIASING == 1)
    float4 c0 = FxaaPixelShader(
		// pos, Output color texture
		Tex,
		// tex, Input color texture
		screenSampler,
		// fxaaQualityRcpFrame, gets coordinates for screen width and height, xy
		float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT),
		//fxaaConsoleRcpFrameOpt2, gets coordinates for screen width and height, xyzw
		float4(-2.0*BUFFER_RCP_WIDTH,-2.0*BUFFER_RCP_HEIGHT,2.0*BUFFER_RCP_WIDTH,2.0*BUFFER_RCP_HEIGHT),
		// Choose the amount of sub-pixel aliasing removal
		fxaaQualitySubpix,
		// The minimum amount of local contrast required to apply algorithm
		fxaaQualityEdgeThreshold,
		// Trims the algorithm from processing darks
		fxaaQualityEdgeThresholdMin
	);
#else
	float4 c0 = tex2D(screenSampler,Tex);
#endif
    return c0;
}

float4 MyShader( float2 Tex : TEXCOORD0 ) : COLOR0
{
	float4 c0 = main(Tex);
	c0.w = 1;
    return saturate(c0);
}

technique PostProcess1
{
    pass p1
    {
        PixelShader = compile ps_3_0 LumaShader();
    }
}
technique PostProcess2
{
    pass p1
    {
        PixelShader = compile ps_3_0 MyShader();
    }
}