//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ENBSeries effect file
// visit http://enbdev.com for updates
// Copyright (c) 2007-2011 Boris Vorontsov
// SkyrimEnhancedShadersFX - Pure ENB 
// http://skyrimnexus.com/downloads/file.php?id=822
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//+++++++++++++++++++++++++++++
// Internal parameters, can be modified
//+++++++++++++++++++++++++++++

//#define USE_MANUAL_APERTURE	1		// comment it to disable manual aperture size (focal distance)
//#define USE_MANUAL_BLUR_SCALE	1		// comment it to disable manual DOF blur scale
//#define USE_SWITCHABLE_MODE		1		// comment it to disable DOF switchable mode (switching between bokeh and gaussian)

float	EBlurSamplingRange = 4.0;
float	EApertureScale = 1.0;		// Matso - base size of the manually changable aperture size (use keys to change the value of 'tempF1' to vary the actual aperture)

//+++++++++++++++++++++++++++++
// External parameters, do not modify
//+++++++++++++++++++++++++++++
// Keyboard controlled temporary variables (in some versions exists in the config file). Press and hold key 1,2,3...8 together with PageUp or PageDown to modify.
// By default all set to 1.0
float4	tempF1; //0,1,2,3
float4	tempF2; //5,6,7,8
float4	tempF3; //9,0
// x=Width, y=1/Width, z=ScreenScaleY, w=1/ScreenScaleY
float4	ScreenSize;
// x=generic timer in range 0..1, period of 16777216 ms (4.6 hours), w=frame time elapsed (in seconds)
float4	Timer;
// Adaptation delta time for focusing
float	FadeFactor;

// textures
texture2D texColor;
texture2D texDepth;
texture2D texNoise;
texture2D texPalette;
texture2D texFocus; // computed focusing depth
texture2D texCurr; // 4*4 texture for focusing
texture2D texPrev; // 4*4 texture for focusing

sampler2D SamplerColor = sampler_state
{
	Texture   = <texColor>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = Mirror;
	AddressV  = Mirror;
	SRGBTexture = FALSE;
	MaxMipLevel = 9;
	MipMapLodBias = 0;
};

sampler2D SamplerDepth = sampler_state
{
	Texture   = <texDepth>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture = FALSE;
	MaxMipLevel = 0;
	MipMapLodBias = 0;
};

sampler2D SamplerNoise = sampler_state
{
	Texture   = <texNoise>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = Wrap;
	AddressV  = Wrap;
	SRGBTexture = FALSE;
	MaxMipLevel = 0;
	MipMapLodBias = 0;
};

sampler2D SamplerPalette = sampler_state
{
	Texture   = <texPalette>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture = FALSE;
	MaxMipLevel = 0;
	MipMapLodBias = 0;
};

// for focus computation
sampler2D SamplerCurr = sampler_state
{
	Texture   = <texCurr>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture = FALSE;
	MaxMipLevel = 0;
	MipMapLodBias = 0;
};

// for focus computation
sampler2D SamplerPrev = sampler_state
{
	Texture   = <texPrev>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture = FALSE;
	MaxMipLevel = 0;
	MipMapLodBias = 0;
};
// for dof only in PostProcess techniques
sampler2D SamplerFocus = sampler_state
{
	Texture   = <texFocus>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture = FALSE;
	MaxMipLevel = 0;
	MipMapLodBias = 0;
};

struct VS_OUTPUT_POST
{
	float4 vpos  : POSITION;
	float2 txcoord : TEXCOORD0;
};

struct VS_INPUT_POST
{
	float3 pos  : POSITION;
	float2 txcoord : TEXCOORD0;
};

////////////////////////////////////////////////////////////////////
// Begin focusing (by Boris Vorontsov)
////////////////////////////////////////////////////////////////////
VS_OUTPUT_POST VS_Focus(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST OUT;

	float4 pos = float4(IN.pos.x,IN.pos.y,IN.pos.z,1.0);

	OUT.vpos = pos;
	OUT.txcoord.xy = IN.txcoord.xy;

	return OUT;
}

//SRCpass1X=ScreenWidth;
//SRCpass1Y=ScreenHeight;
//DESTpass2X=4;
//DESTpass2Y=4;
float4 PS_ReadFocus(VS_OUTPUT_POST IN) : COLOR
{
#ifndef USE_MANUAL_APERTURE
	float res = tex2D(SamplerDepth, 0.5).x;
#else
	float res = EApertureScale * tempF1.x;
#endif
	return res;
}

//SRCpass1X=4;
//SRCpass1Y=4;
//DESTpass2X=4;
//DESTpass2Y=4;
float4 PS_WriteFocus(VS_OUTPUT_POST IN) : COLOR
{
	float res = 0.0;
	float curr = tex2D(SamplerCurr, 0.5).x;
	float prev = tex2D(SamplerPrev, 0.5).x;

	res = lerp(prev, curr, saturate(FadeFactor));// time elapsed factor
	res = max(res, 0.0);

	return res;
}

technique ReadFocus
{
	pass P0
	{
		VertexShader = compile vs_3_0 VS_Focus();
		PixelShader  = compile ps_3_0 PS_ReadFocus();

		ZEnable = FALSE;
		CullMode = NONE;
		ALPHATESTENABLE = FALSE;
		SEPARATEALPHABLENDENABLE = FALSE;
		AlphaBlendEnable = FALSE;
		FogEnable = FALSE;
		SRGBWRITEENABLE = FALSE;
	}
}

technique WriteFocus
{
	pass P0
	{
		VertexShader = compile vs_3_0 VS_Focus();
		PixelShader  = compile ps_3_0 PS_WriteFocus();

		ZEnable = FALSE;
		CullMode = NONE;
		ALPHATESTENABLE = FALSE;
		SEPARATEALPHABLENDENABLE = FALSE;
		AlphaBlendEnable = FALSE;
		FogEnable = FALSE;
		SRGBWRITEENABLE = FALSE;
	}
}
////////////////////////////////////////////////////////////////////
// End focusing code
////////////////////////////////////////////////////////////////////

/*------------------------------------------------------------------------------
				 ENB prepass modifications 4.0.0 by Matso
					   Credits to Boris Vorontsov
------------------------------------------------------------------------------*/
// Effects enabling options
#define ENABLE_DOF	1				// comment to disable depth of field
//#define ENABLE_CHROMA	1			// comment to disable chromatic aberration (additional chromatic aberration applied beyond depth of field)
//#define ENABLE_PREPASS	1			// comment to disable prepass effects
#define ENABLE_POSTPASS	1			// comment to disable postpass effects

// Methods enabling options
//#define USE_CHROMA_DOF	1			// comment it to disable chromatic aberration sampling in DoF
#define USE_SMOOTH_DOF	1			// comment it to disable smooth DoF
#define USE_BOKEH_DOF	1			// comment it to disable bokeh DoF
#define USE_DOUBLE_BLUR 1			// comment it to disable additional blur
//#define USE_SHARPENING	1			// comment it to disable sharpening
//#define USE_ANAMFLARE	1			// comment it to disable anamorphic lens flare
#define USE_IMAGEGRAIN	0			// comment it to disable image grain
//#define USE_CLOSE_DOF_ONLY	1		// comment it to disable close-DoF-only effect

// Useful constants
#define SEED			1.0 //Timer.x
#define PI				3.1415926535897932384626433832795
#define CHROMA_POW		65.0								// the bigger the value, the more visible chomatic aberration effect in DoF

// DoF constants
#define DOF_SCALE		2356.1944901923449288469825374596	// PI * 750
// Set those below for diffrent blur shapes
#define FIRST_PASS		0	// only 0, 1, 2, or 3
#define SECOND_PASS		1	// only 0, 1, 2, or 3
#define THIRD_PASS		2	// only 0, 1, 2, or 3
#define FOURTH_PASS		3	// only 0, 1, 2, or 3

#ifndef USE_MANUAL_APERTURE
 #define DOF(sd,sf)		fBlurScale * smoothstep(fDofBias, fDofCutoff, abs(sd - sf))
#else
 #define DOF(sd,sf)		fBlurScale * smoothstep(fDofBias * tempF1.y, fDofCutoff * tempF1.z, abs(sd - sf))
#endif
//#define DOF(sd,sf)		fBlurScale * pow(abs(sd - sf), 2.0) * 10.0
#define BOKEH_DOWNBLUR	0.3		// the default blur scale is too big for bokeh

// Bokeh flags
#define USE_NATURAL_BOKEH	1			// diffrent, more natural bokeh shape (comment to disable)
#define USE_BRIGHTNESS_LIMITING		1	// bokeh brightness limiting (comment to disable)
//#define USE_WEIGHT_CLAMP	1			// bokeh weight clamping (comment to disable)
#define USE_ENHANCED_BOKEH	1			// more pronounced bokeh blur (comment to disable)

// Chromatic aberration parameters
float3 fvChroma = float3(0.9995, 1.000, 1.0005);// displacement scales of red, green and blue respectively
#define fBaseRadius 0.9							// below this radius the effect is less visible
#define fFalloffRadius 1.8						// over this radius the effect is max
#define fChromaPower 10.0						// power of the chromatic displacement (curve of the 'fvChroma' vector)

// Sharpen parameters
#define fSharpScale 0.032						// intensity of sharpening
float2 fvTexelSize = float2(1.0 / 1920.0, 1.0 / 1080.0);	// set your resolution sizes

// Depth of field parameters
#define fFocusBias 0.05						// bigger values for nearsightedness, smaller for farsightedness (lens focal point distance)
#define fDofCutoff 0.25							// manages the smoothness of the DoF (bigger value results in wider depth of field)
#define fDofBias 0.08							// distance not taken into account in DoF (all closer then the distance is in focus)
#define fBlurScale 0.005						// governs image blur scale (the bigger value, the stronger blur)
#define fBlurCutoff 0.1						// bluring tolerance depending on the pixel and sample depth (smaller causes objects edges to be preserved)
#define fCloseDofDistance 1.0					// only to this distance DoF will be applied
#define fStepScale 0.00018

// Bokeh parameters
#define fBokehCurve 5.0							// the larger the value, the more visible the bokeh effect is (not used with brightness limiting)
#define fBokehIntensity 0.95					// governs bokeh brightness (not used with brightness limiting)
#define fBokehConstant 0.1						// constant value of the bokeh weighting
#define fBokehMaxLevel 45.0						// bokeh max brightness level (scale factor for bokeh samples)
#define fBokehMin 0.001							// min input cutoff (anything below is 0)
#define fBokehMax 1.925							// max input cutoff (anything above is 1)
#define fBokehMaxWeight 25.0					// any weight above will be clamped

#define fBokehLuminance	0.956					// bright pass of the bokeh weight used with radiant version of the bokeh
#define BOKEH_RADIANT	float3 bct = ct.rgb;float b = GrayScale(bct) + fBokehConstant + length(bct)
#define BOKEH_PASTEL	float3 bct = BrightBokeh(ct.rgb);float b = dot(bct, bct) + fBokehConstant
#define BOKEH_VIBRANT	float3 bct = BrightBokeh(ct.rgb);float b = GrayScale(ct.rgb) + dot(bct, bct) + fBokehConstant
#define BOKEH_FORMULA	BOKEH_PASTEL//BOKEH_RADIANT //			// choose one of the above

// Grain parameters
#define fGrainFreq 4000.0						// image grain frequency
#define fGrainScale 0.0						// grain effect scale

// Anamorphic flare parameters
#define fFlareLuminance 2.0						// bright pass luminance value 
#define fFlareBlur 200.0						// manages the size of the flare
#define fFlareIntensity 0.07					// effect intensity

// Bokeh shape offset weights
#define DEFAULT_OFFSETS	{ -1.282, -0.524, 0.524, 1.282 }

// Sampling vectors	
float offset[4] = DEFAULT_OFFSETS;
#ifndef USE_NATURAL_BOKEH
float2 tds[4] = { float2(1.0, 0.0), float2(0.0, 1.0), float2(0.707, 0.707), float2(-0.707, 0.707) };
#else
float2 tds[16] = { 
	float2(0.2007, 0.9796),
	float2(-0.2007, 0.9796), 
	float2(0.2007, 0.9796),
	float2(-0.2007, 0.9796), 
		
	float2(0.8240, 0.5665),
	float2(0.5665, 0.8240),
	float2(0.8240, 0.5665),
	float2(0.5665, 0.8240),

	float2(0.9796, 0.2007),
	float2(0.9796, -0.2007),
	float2(0.9796, 0.2007),
	float2(0.9796, -0.2007),
		
	float2(-0.8240, 0.5665),
	float2(-0.5665, 0.8240),
	float2(-0.8240, 0.5665),
	float2(-0.5665, 0.8240)
};			// Natural bokeh sampling directions

float2 rnds[16] = {
	float2(0.326212, 0.40581),
    float2(0.840144, 0.07358),
    float2(0.695914, 0.457137),
    float2(0.203345, 0.620716),
    float2(0.96234, 0.194983),
    float2(0.473434, 0.480026),
    float2(0.519456, 0.767022),
    float2(0.185461, 0.893124),
    float2(0.507431, 0.064425),
    float2(0.89642, 0.412458),
    float2(0.32194, 0.932615),
    float2(0.791559, 0.59771),
	float2(0.979602, 0.10275),
	float2(0.56653, 0.82401),
	float2(0.20071, 0.97966),
	float2(0.98719, 0.12231)
};
#endif

// External parameters (Help needed - how to pass a game parameter value to the shader?)
extern float fWaterLevel = 1.0;					// DO NOT CHANGE - must be 1.0 for now! (under water will be set to lower value)

/**
 * Chromatic aberration function - given texture coordinate and a focus value
 * retrieves chromatically distorted color of the pixel. Each of the color
 * channels are displaced according to the pixel coordinate and its distance
 * from the center of the image. Also the DoF out-of-focus value is applied.
 * (http://en.wikipedia.org/wiki/Chromatic_aberration)
 */
float4 ChromaticAberration(float2 tex)
{
	float d = distance(tex, float2(0.5, 0.5));
	float f = smoothstep(fBaseRadius, fFalloffRadius, d);
	float3 chroma = pow(f + fvChroma, fChromaPower);
	
	float2 tr = ((2.0 * tex - 1.0) * chroma.r) * 0.5 + 0.5;
	float2 tg = ((2.0 * tex - 1.0) * chroma.g) * 0.5 + 0.5;
	float2 tb = ((2.0 * tex - 1.0) * chroma.b) * 0.5 + 0.5;
	
	float3 color = float3(tex2D(SamplerColor, tr).r, tex2D(SamplerColor, tg).g, tex2D(SamplerColor, tb).b) * (1.0 - f);
	
	return float4(color, 1.0);
}

/**
 * Chromatic aberration done accoriding to the focus factor provided.
 */
float4 ChromaticAberration(float2 tex, float outOfFocus)
{
	float d = distance(tex, float2(0.5, 0.5));
	float f = smoothstep(fBaseRadius, fFalloffRadius, d);
	float3 chroma = pow(f + fvChroma, CHROMA_POW * outOfFocus * fChromaPower);

	float2 tr = ((2.0 * tex - 1.0) * chroma.r) * 0.5 + 0.5;
	float2 tg = ((2.0 * tex - 1.0) * chroma.g) * 0.5 + 0.5;
	float2 tb = ((2.0 * tex - 1.0) * chroma.b) * 0.5 + 0.5;
	
	float3 color = float3(tex2D(SamplerColor, tr).r, tex2D(SamplerColor, tg).g, tex2D(SamplerColor, tb).b) * (1.0 - outOfFocus);
	
	return float4(color, 1.0);
}

/**
 * Pseudo-random number generator - returns a number generated according to the provided vector.
 */
float Random(float2 co)
{
    return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}


float2 Random2(float2 coord)
{
	float noiseX = ((frac(1.0-coord.x*(1920.0/2.0))*0.25)+(frac(coord.y*(1080.0/2.0))*0.75))*2.0-1.0;
	float noiseY = ((frac(1.0-coord.x*(1920.0/2.0))*0.75)+(frac(coord.y*(1080.0/2.0))*0.25))*2.0-1.0;
	
	noiseX = clamp(frac(sin(dot(coord ,float2(12.9898,78.233))) * 43758.5453),0.0,1.0)*2.0-1.0;
	noiseY = clamp(frac(sin(dot(coord ,float2(12.9898,78.233)*2.0)) * 43758.5453),0.0,1.0)*2.0-1.0;
	
	return float2(noiseX, noiseY);
}

/**
 * Movie grain function - returns a random, time scaled value for the given pixel coordinate.
 */
float Grain(float3 tex)
{
	float r = Random(tex.xy);
	float grain = sin(PI * tex.z * r * fGrainFreq) * fGrainScale * r;
	return grain;
}

/**
 * Bright pass - rescales sampled pixel to emboss bright enough value.
 */
float3 BrightPass(float2 tex)
{
	float3 c = tex2D(SamplerColor, tex).rgb;
    float3 bC = max(c - float3(fFlareLuminance, fFlareLuminance, fFlareLuminance), 0.0);
    float bright = dot(bC, 1.0);
    bright = smoothstep(0.0f, 0.5, bright);
    return lerp(0.0, c, bright);
}

/**
 * Bright pass - rescales given color to emboss bright enough value.
 */
float3 BrightColor(float3 c)
{
    float3 bC = max(c - float3(fFlareLuminance, fFlareLuminance, fFlareLuminance), 0.0);
    float bright = dot(bC, 1.0);
    bright = smoothstep(0.0f, 0.5, bright);
    return lerp(0.0, c, bright);
}

float3 BrightBokeh(float3 c)
{
    float3 bC = max(c - float3(fBokehLuminance, fBokehLuminance, fBokehLuminance), 0.0);
    float bright = dot(bC, 1.0);
    bright = smoothstep(0.0f, 0.5, bright);
    return lerp(0.0, c, bright);
}

/**
 * Anamorphic sampling function - scales pixel coordinate
 * to stratch the image along one of the axels.
 * (http://en.wikipedia.org/wiki/Anamorphosis)
 */
float3 AnamorphicSample(int axis, float2 tex, float blur)
{
	tex = 2.0 * tex - 1.0;
	if (!axis) tex.x /= -blur;
	else tex.y /= -blur;
	tex = 0.5 * tex + 0.5;
	return BrightPass(tex);
}

/**
 * Converts pixel color to gray-scale.
 */
float GrayScale(float3 sample)
{
	return dot(sample, float3(0.3, 0.59, 0.11));
}

/**
 * Returns an under water distortion according to the given coordinate and time factor. [WIP]
 */
float2 UnderWaterDistortion(float2 coord)
{
	if (fWaterLevel > 1.0) {
		float2 tap = tex2D(SamplerNoise, coord.xy * 2.0).rg;	// add 'fWaveFreq'
		float2 dist = normalize(coord - tap) * smoothstep(0.0, 1.0, distance(coord, tap) * 0.05);	// add 'fWaveScale'
		float scale = smoothstep(0.0, 6.0, distance(coord, float2(0.5, 0.5))) * 0.99 + 0.96;	// add 'fFishEyeScale' and 'fFishEyeBias'
		
		coord += dist;
		coord = ((2.0 * coord - 1.0) * scale) * 0.5 + 0.5;
	}
	return coord;
}

///// Shaders ////////////////////////////////////////////////////////////////////////////////
// Vertex shader (Boris code)
VS_OUTPUT_POST VS_PostProcess(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST OUT;

	float4 pos = float4(IN.pos.x, IN.pos.y, IN.pos.z, 1.0);

	OUT.vpos = pos;
	OUT.txcoord.xy = IN.txcoord.xy;

	return OUT;
}

// Sharpen pixel shader (Matso code)
float4 PS_ProcessPass_Sharpen(VS_OUTPUT_POST IN, float2 vPos : VPOS) : COLOR
{
	float2 coord = IN.txcoord.xy;
	float4 Color = 9.0 * tex2D(SamplerColor, coord.xy);
	
	Color -= tex2D(SamplerColor, coord.xy + float2(-fvTexelSize.x, fvTexelSize.y) * fSharpScale);
	Color -= tex2D(SamplerColor, coord.xy + float2(0.0, fvTexelSize.y) * fSharpScale);
	Color -= tex2D(SamplerColor, coord.xy + float2(fvTexelSize.x, fvTexelSize.y) * fSharpScale);
	Color -= tex2D(SamplerColor, coord.xy + float2(fvTexelSize.x, 0.0) * fSharpScale);
	Color -= tex2D(SamplerColor, coord.xy + float2(fvTexelSize.x, -fvTexelSize.y) * fSharpScale);
	Color -= tex2D(SamplerColor, coord.xy + float2(0.0, -fvTexelSize.y) * fSharpScale);
	Color -= tex2D(SamplerColor, coord.xy + float2(-fvTexelSize.x, -fvTexelSize.y) * fSharpScale);
	Color -= tex2D(SamplerColor, coord.xy + float2(-fvTexelSize.x, 0.0) * fSharpScale);
	
	Color.a = 1.0;
	return Color;
}

// Anamorphic lens flare pixel shader (Matso code)
float4 PS_ProcessPass_Anamorphic(VS_OUTPUT_POST IN, float2 vPos : VPOS) : COLOR
{
	float4 res;
	float2 coord = IN.txcoord.xy;
	float3 anamFlare = AnamorphicSample(0, coord.xy, fFlareBlur) * float3(0.0, 0.0, 1.0);
	
	res.rgb = anamFlare * fFlareIntensity;
	res.a = 1.0;

#if !defined(USE_SHARPENING)
	res.rgb += tex2D(SamplerColor, coord.xy).rgb;
#endif
	
	return res;
}

// Image grain pixel shader (Matso code)
float4 PS_ProcessPass_ImageGrain(VS_OUTPUT_POST IN, float2 vPos : VPOS) : COLOR
{
	float4 res;
	float2 coord = IN.txcoord.xy;
	res.rgb = tex2D(SamplerColor, coord.xy).rgb;
	res.rgb += tex2D(SamplerNoise, coord.xy * 1024).rgb * Grain(float3(coord.xy, SEED));
	res.a = 1.0;
	return res;
}

// Simple pass through shader (Matso code)
float4 PS_ProcessPass_None(VS_OUTPUT_POST IN, float2 vPos : VPOS) : COLOR
{
	float4 res;
	float2 coord = IN.txcoord.xy;
	res.rgb = tex2D(SamplerColor, coord.xy).rgb;
	res.a = 1.0;
	return res;
}

// Depth of field pixel shader (Matso code)
float4 PS_ProcessPass_DepthOfField(VS_OUTPUT_POST IN, float2 vPos : VPOS, uniform int axis) : COLOR
{
	float4 res;
	float2 base = IN.txcoord.xy;
	float4 tcol = tex2D(SamplerColor, base.xy);
	float sd = tex2D(SamplerDepth, base).x;					// acquire scene depth for the pixel
	res = tcol;

#ifndef USE_SMOOTH_DOF										// sample focus value
	float sf = tex2D(SamplerDepth, 0.5).x - fFocusBias * fWaterLevel;
#else
	float sf = tex2D(SamplerFocus, 0.5).x - fFocusBias * 2.0 * fWaterLevel;
#endif
	float outOfFocus = DOF(sd, sf);
	float blur = DOF_SCALE * outOfFocus;
	float wValue = 1.0;

#ifdef USE_MANUAL_BLUR_SCALE
	blur *= tempF1.w;
#endif

#ifndef USE_CLOSE_DOF_ONLY
 #ifdef USE_BOKEH_DOF
	blur *= BOKEH_DOWNBLUR;									// should bokeh be used, decrease blur a bit
 #endif
#else	
	blur *= (smoothstep(fCloseDofDistance, 0.0, sf) * 2.0);
	if (blur > 0.001)
#endif

	for (int i = 0; i < 4; i++)
	{
#ifndef USE_NATURAL_BOKEH
		float2 tdir = tds[axis] * fvTexelSize * blur * offset[i];
#else
		float2 tdir = tds[axis * 4 + i] * fvTexelSize * blur * offset[i];
#endif
		
		float2 coord = base + tdir.xy;
#ifdef USE_CHROMA_DOF
		float4 ct = ChromaticAberration(coord, outOfFocus);			// chromatic aberration sampling
#else
		float4 ct = tex2D(SamplerColor, coord);
#endif
		float sds = tex2D(SamplerDepth, coord).x;
		
		if ((abs(sds - sd) / sd) <= fBlurCutoff) {							// blur 'bleeding' control
#ifndef USE_BOKEH_DOF
			float w = 1.0 + abs(offset[i]);							// weight blur for better effect
#else		
  #if USE_BOKEH_DOF == 1
  			BOKEH_FORMULA;
    #ifndef USE_BRIGHTNESS_LIMITING									// all samples above max input will be limited to max level
			float w = pow(b * fBokehIntensity, fBokehCurve);
    #else
	 #ifdef USE_ENHANCED_BOKEH
			float w = smoothstep(fBokehMin, fBokehMax, b * b) * fBokehMaxLevel;
	 #else
	 		float w = smoothstep(fBokehMin, fBokehMax, b) * fBokehMaxLevel;
	 #endif
    #endif
	#ifdef USE_WEIGHT_CLAMP
			w = min(w, fBokehMaxWeight);
	#endif
			w += abs(offset[i]) + blur;
  #endif
  #ifdef USE_SWITCHABLE_MODE
  			float w = 1.0 + abs(offset[i]);
  			
			if (tempF2.z > 0.99f) {
				BOKEH_FORMULA;
				w += smoothstep(fBokehMin, fBokehMax, b * b) * fBokehMaxLevel + blur;
			}
  #endif
#endif	
			tcol += ct * w;
			wValue += w;
		}
	}

	tcol /= wValue;
	
	res.rgb = tcol.rgb;
	res.w = 1.0;
	return res;
}

// Chromatic abrration with no DoF (Matso code)
float4 PS_ProcessPass_Chroma(VS_OUTPUT_POST IN, float2 vPos : VPOS) : COLOR
{
	float2 coord = IN.txcoord.xy;
	float4 result = ChromaticAberration(coord.xy);
	result.a = 1.0;
	return result;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifdef ENABLE_PREPASS
	technique PostProcess
	{
	#ifdef USE_SHARPENING
		pass P0
		{
			VertexShader = compile vs_3_0 VS_PostProcess();
			PixelShader  = compile ps_3_0 PS_ProcessPass_Sharpen();

			DitherEnable = FALSE;
			ZEnable = FALSE;
			CullMode = NONE;
			ALPHATESTENABLE = FALSE;
			SEPARATEALPHABLENDENABLE = FALSE;
			AlphaBlendEnable = FALSE;
			StencilEnable = FALSE;
			FogEnable = FALSE;
			SRGBWRITEENABLE = FALSE;
		}
	#endif
	#ifdef USE_ANAMFLARE
		pass P1
		{
		#if defined(USE_SHARPENING)
			AlphaBlendEnable = true;
			SrcBlend = One;
			DestBlend = One;
			
			PixelShader = compile ps_3_0 PS_ProcessPass_Anamorphic();
		#else
		
			VertexShader = compile vs_3_0 VS_PostProcess();
			PixelShader  = compile ps_3_0 PS_ProcessPass_Anamorphic();
		
			DitherEnable = FALSE;
			ZEnable = FALSE;
			CullMode = NONE;
			ALPHATESTENABLE = FALSE;
			SEPARATEALPHABLENDENABLE = FALSE;
			AlphaBlendEnable = FALSE;
			StencilEnable = FALSE;
			FogEnable = FALSE;
			SRGBWRITEENABLE = FALSE;
		#endif
		}
	#endif
	}
#endif

#ifndef ENABLE_DOF
	#ifdef ENABLE_CHROMA
		#ifndef ENABLE_PREPASS
			technique PostProcess
		#else
			technique PostProcess2
		#endif
		{
			pass P0
			{
				VertexShader = compile vs_3_0 VS_PostProcess();
				PixelShader  = compile ps_3_0 PS_ProcessPass_Chroma();

				DitherEnable = FALSE;
				ZEnable = FALSE;
				CullMode = NONE;
				ALPHATESTENABLE = FALSE;
				SEPARATEALPHABLENDENABLE = FALSE;
				AlphaBlendEnable = FALSE;
				StencilEnable = FALSE;
				FogEnable = FALSE;
				SRGBWRITEENABLE = FALSE;
			}
		}
	#endif
#endif

#ifndef ENABLE_CHROMA
	#ifdef ENABLE_DOF
		#ifndef ENABLE_PREPASS
			technique PostProcess
		#else
			technique PostProcess2
		#endif
		{
			pass P0
			{
				VertexShader = compile vs_3_0 VS_PostProcess();
				PixelShader  = compile ps_3_0 PS_ProcessPass_DepthOfField(FIRST_PASS);

				DitherEnable = FALSE;
				ZEnable = FALSE;
				CullMode = NONE;
				ALPHATESTENABLE = FALSE;
				SEPARATEALPHABLENDENABLE = FALSE;
				AlphaBlendEnable = FALSE;
				StencilEnable = FALSE;
				FogEnable = FALSE;
				SRGBWRITEENABLE = FALSE;
			}
		}

		#ifndef ENABLE_PREPASS
			technique PostProcess2
		#else
			technique PostProcess3
		#endif
		{
			pass P0
			{
				VertexShader = compile vs_3_0 VS_PostProcess();
				PixelShader  = compile ps_3_0 PS_ProcessPass_DepthOfField(SECOND_PASS);

				DitherEnable = FALSE;
				ZEnable = FALSE;
				CullMode = NONE;
				ALPHATESTENABLE = FALSE;
				SEPARATEALPHABLENDENABLE = FALSE;
				AlphaBlendEnable = FALSE;
				StencilEnable = FALSE;
				FogEnable = FALSE;
				SRGBWRITEENABLE = FALSE;
			}
		}

		#ifndef ENABLE_PREPASS
			technique PostProcess3
		#else
			technique PostProcess4
		#endif
		{
			pass P0
			{
				VertexShader = compile vs_3_0 VS_PostProcess();
				PixelShader  = compile ps_3_0 PS_ProcessPass_DepthOfField(THIRD_PASS);

				DitherEnable = FALSE;
				ZEnable = FALSE;
				CullMode = NONE;
				ALPHATESTENABLE = FALSE;
				SEPARATEALPHABLENDENABLE = FALSE;
				AlphaBlendEnable = FALSE;
				StencilEnable = FALSE;
				FogEnable = FALSE;
				SRGBWRITEENABLE = FALSE;
			}
		}

		#ifndef ENABLE_PREPASS
			technique PostProcess4
		#else
			technique PostProcess5
		#endif
		{
			pass P0
			{
				VertexShader = compile vs_3_0 VS_PostProcess();
				PixelShader  = compile ps_3_0 PS_ProcessPass_DepthOfField(FOURTH_PASS);

				DitherEnable = FALSE;
				ZEnable = FALSE;
				CullMode = NONE;
				ALPHATESTENABLE = FALSE;
				SEPARATEALPHABLENDENABLE = FALSE;
				AlphaBlendEnable = FALSE;
				StencilEnable = FALSE;
				FogEnable = FALSE;
				SRGBWRITEENABLE = FALSE;
			}
		}
	#endif
#endif

#ifdef ENABLE_POSTPASS
	#ifndef ENABLE_PREPASS
		technique PostProcess5
	#else
		technique PostProcess6
	#endif
	{				
	#ifdef USE_IMAGEGRAIN
		pass P0
		{
			VertexShader = compile vs_3_0 VS_PostProcess();
			PixelShader = compile ps_3_0 PS_ProcessPass_ImageGrain();
					
			DitherEnable = FALSE;
			ZEnable = FALSE;
			CullMode = NONE;
			ALPHATESTENABLE = FALSE;
			SEPARATEALPHABLENDENABLE = FALSE;
			AlphaBlendEnable = FALSE;
			StencilEnable = FALSE;
			FogEnable = FALSE;
			SRGBWRITEENABLE = FALSE;
		}
	#endif
	}
#endif
