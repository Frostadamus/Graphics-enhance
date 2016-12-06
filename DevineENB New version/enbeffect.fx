//++++++++++++++++++++++++++++++++++++++++++++
// ENBSeries effect file
// visit http://enbdev.com for updates
// Copyright (c) 2007-2011 Boris Vorontsov
// Modified for SkyrimEnhancedShadersFX 1.1 Preview 12 - PureENB 
// For ENBseries TESV 0.119
// http://skyrimnexus.com/downloads/file.php?id=822
//++++++++++++++++++++++++++++++++++++++++++++



//post processing mode. Change value (could be 1, 2, 3, 4). Every mode have own internal parameters, look below
#ifndef POSTPROCESS
 #define POSTPROCESS	2
#endif

//use original game processing first, then mine
//#define APPLYGAMECOLORCORRECTION

//use original game processing only, with vanilla bloom
//#define ENB_FLIPTECHNIQUE



//+++++++++++++++++++++++++++++
//internal parameters, can be modified
//+++++++++++++++++++++++++++++
//float3	EColorFilter=float3(1.0, 0.9, 0.9);

//modify these values to tweak various color processing
//POSTPROCESS 1
float	EAdaptationMinV1=0.01;
float	EAdaptationMaxV1=0.07;
float	EContrastV1=0.95;
float	EColorSaturationV1=1.0;
float	EToneMappingCurveV1=6.0;

//POSTPROCESS 2
							
float	EBrightnessV2Night=1.0;
float	EBrightnessV2Day=1.0;
float	EBrightnessV2Interior=1.0;

float	EAdaptationMinV2Day=0.05;
float	EAdaptationMinV2Night=0.05;
float	EAdaptationMinV2Interior=0.0575;

float	EAdaptationMaxV2Day=0.13;
float	EAdaptationMaxV2Night=0.13;
float	EAdaptationMaxV2Interior=0.1;
							
float	EToneMappingCurveV2Day=7.5;
float	EToneMappingCurveV2Night=7.0;
float	EToneMappingCurveV2Interior=5.5;

float	EIntensityContrastV2Day=1.475;
float	EIntensityContrastV2Night=1.375;
float	EIntensityContrastV2Interior=1.4;
							
float	EColorSaturationV2Day=1.1;
float	EColorSaturationV2Night=1.0;
float	EColorSaturationV2Interior=1.25;
							
float	EToneMappingOversaturationV2Day=150.0;
float	EToneMappingOversaturationV2Night=50.0;
float	EToneMappingOversaturationV2Interior=60.0;


//POSTPROCESS 3
float	EAdaptationMinV3=0.05;
float	EAdaptationMaxV3=0.125;
float	EToneMappingCurveV3=4.0;
float	EToneMappingOversaturationV3=60.0;

//POSTPROCESS 4
float	EAdaptationMinV4=0.2;
float	EAdaptationMaxV4=0.125;
float	EBrightnessCurveV4=0.7;
float	EBrightnessMultiplierV4=0.45;
float	EBrightnessToneMappingCurveV4=0.5;



//+++++++++++++++++++++++++++++
//external parameters, do not modify
//+++++++++++++++++++++++++++++
//keyboard controlled temporary variables (in some versions exists in the config file). Press and hold key 1,2,3...8 together with PageUp or PageDown to modify. By default all set to 1.0
float4	tempF1; //0,1,2,3
float4	tempF2; //5,6,7,8
float4	tempF3; //9,0
//x=generic timer in range 0..1, period of 16777216 ms (4.6 hours), w=frame time elapsed (in seconds)
float4	Timer;
//x=Width, y=1/Width, z=ScreenScaleY, w=1/ScreenScaleY
float4	ScreenSize;
//changes in range 0..1, 0 means that night time, 1 - day time
float	ENightDayFactor;
//changes 0 or 1. 0 means that exterior, 1 - interior
float	EInteriorFactor;
//enb version of bloom applied, ignored if original post processing used
float	EBloomAmount;



texture2D texs0;//color
texture2D texs1;//bloom skyrim
texture2D texs2;//adaptation skyrim
texture2D texs3;//bloom enb
texture2D texs4;//adaptation enb
texture2D texs7;//palette enb

sampler2D _s0 = sampler_state
{
	Texture   = <texs0>;
	MinFilter = POINT;//
	MagFilter = POINT;//
	MipFilter = NONE;//LINEAR;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D _s1 = sampler_state
{
	Texture   = <texs1>;
	MinFilter = LINEAR;//
	MagFilter = LINEAR;//
	MipFilter = NONE;//LINEAR;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D _s2 = sampler_state
{
	Texture   = <texs2>;
	MinFilter = LINEAR;//
	MagFilter = LINEAR;//
	MipFilter = NONE;//LINEAR;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D _s3 = sampler_state
{
	Texture   = <texs3>;
	MinFilter = LINEAR;//
	MagFilter = LINEAR;//
	MipFilter = NONE;//LINEAR;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D _s4 = sampler_state
{
	Texture   = <texs4>;
	MinFilter = LINEAR;//
	MagFilter = LINEAR;//
	MipFilter = NONE;//LINEAR;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D _s7 = sampler_state
{
	Texture   = <texs7>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

struct VS_OUTPUT_POST
{
	float4 vpos  : POSITION;
	float2 txcoord0 : TEXCOORD0;
};
struct VS_INPUT_POST
{
	float3 pos  : POSITION;
	float2 txcoord0 : TEXCOORD0;
};



//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
VS_OUTPUT_POST VS_Quad(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST OUT;

	OUT.vpos=float4(IN.pos.x,IN.pos.y,IN.pos.z,1.0);

	OUT.txcoord0.xy=IN.txcoord0.xy;

	return OUT;
}


//skyrim shader specific externals, do not modify
float4	_c1 : register(c1);
float4	_c2 : register(c2);
float4	_c3 : register(c3);
float4	_c4 : register(c4);
float4	_c5 : register(c5);

float4 PS_D6EC7DD1(VS_OUTPUT_POST IN, float2 vPos : VPOS) : COLOR
{
	float4 _oC0=0.0; //output

	float4 _c6=float4(0, 0, 0, 0);
	float4 _c7=float4(0.212500006, 0.715399981, 0.0720999986, 1.0);

	float4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	float4 r5;
	float4 r6;
	float4 r7;
	float4 r8;
	float4 r9;
	float4 r10;
	float4 r11;


	float4 _v0=0.0;

	_v0.xy=IN.txcoord0.xy;
	r1=tex2D(_s0, _v0.xy); //color

	//apply bloom
	float4	xcolorbloom=tex2D(_s3, _v0.xy);

	xcolorbloom.xyz=xcolorbloom-r1;
	xcolorbloom.xyz=max(xcolorbloom, 0.0);
	r1.xyz+=xcolorbloom*EBloomAmount;

	r11=r1; //my bypass
	_oC0.xyz=r1.xyz; //for future use without game color corrections

#ifdef APPLYGAMECOLORCORRECTION
	//apply original
    r0.x=1.0/_c2.y;
    r1=tex2D(_s2, _v0);
    r0.yz=r1.xy * _c1.y;
    r0.w=1.0/r0.y;
    r0.z=r0.w * r0.z;
    r1=tex2D(_s0, _v0);
    r1.xyz=r1 * _c1.y;
    r0.w=dot(_c7.xyz, r1.xyz);
    r1.w=r0.w * r0.z;
    r0.z=r0.z * r0.w + _c7.w;
    r0.z=1.0/r0.z;
    r0.x=r1.w * r0.x + _c7.w;
    r0.x=r0.x * r1.w;
    r0.x=r0.z * r0.x;
    if (r0.w<0) r0.x=_c6.x;
    r0.z=1.0/r0.w;
    r0.z=r0.z * r0.x;
    r0.x=saturate(-r0.x + _c2.x);
//    r2=tex2D(_s3, _v0);//enb bloom
    r2=tex2D(_s1, _v0);//skyrim bloom
    r2.xyz=r2 * _c1.y;
    r2.xyz=r0.x * r2;
    r1.xyz=r1 * r0.z + r2;
    r0.x=dot(r1.xyz, _c7.xyz);
    r1.w=_c7.w;
    r2=lerp(r0.x, r1, _c3.x);
    r1=r0.x * _c4 - r2;
    r1=_c4.w * r1 + r2;
    r1=_c3.w * r1 - r0.y; //khajiit night vision _c3.w
    r0=_c3.z * r1 + r0.y;
    r1=-r0 + _c5;
    _oC0=_c5.w * r1 + r0;

#endif //APPLYGAMECOLORCORRECTION

/*
#ifndef APPLYGAMECOLORCORRECTION
//temporary fix for khajiit night vision, but it also degrade colors.
//	r1=tex2D(_s2, _v0);
//	r0.y=r1.xy * _c1.y;
	r1=_oC0;
	r1.xyz=r1 * _c1.y;
	r0.x=dot(r1.xyz, _c7.xyz);
	r2=lerp(r0.x, r1, _c3.x);
	r1=r0.x * _c4 - r2;
	r1=_c4.w * r1 + r2;
	r1=_c3.w * r1;// - r0.y;
	r0=_c3.z * r1;// + r0.y;
	r1=-r0 + _c5;
	_oC0=_c5.w * r1 + r0;
#endif //!APPLYGAMECOLORCORRECTION
*/

	float4 color=_oC0;


	//adaptation in time
	float4	Adaptation=tex2D(_s4, 0.5);
	float	grayadaptation=max(max(Adaptation.x, Adaptation.y), Adaptation.z);

#if (POSTPROCESS==1)

	grayadaptation=max(grayadaptation, 0.0);
	grayadaptation=min(grayadaptation, 50.0);
	color.xyz=color.xyz/(grayadaptation*EAdaptationMaxV1+EAdaptationMinV1);//*tempF1.x

	float cgray=dot(color.xyz, float3(0.27, 0.67, 0.06));
	cgray=pow(cgray, EContrastV1);
	float3 poweredcolor=pow(color.xyz, EColorSaturationV1);
	float newgray=dot(poweredcolor.xyz, float3(0.27, 0.67, 0.06));
	color.xyz=poweredcolor.xyz*cgray/(newgray+0.0001);

	float3	luma=color.xyz;
	float	lumamax=300.0;
	color.xyz=(color.xyz * (1.0 + color.xyz/lumamax))/(color.xyz + EToneMappingCurveV1);

#endif



#if (POSTPROCESS==2)

	float newEAdaptationMax=lerp(EAdaptationMaxV2Interior, (lerp(EAdaptationMaxV2Night, EAdaptationMaxV2Day, ENightDayFactor) ), EInteriorFactor ); 
	float newEAdaptationMin=lerp(EAdaptationMinV2Interior, (lerp(EAdaptationMinV2Night, EAdaptationMinV2Day, ENightDayFactor) ), EInteriorFactor );
	float newEBrightnessV2=lerp(EBrightnessV2Interior, (lerp(EBrightnessV2Night, EBrightnessV2Day, ENightDayFactor) ), EInteriorFactor);
	float newEToneMappingCurve=lerp(EToneMappingCurveV2Interior, (lerp(EToneMappingCurveV2Night,EToneMappingCurveV2Day,ENightDayFactor) ), EInteriorFactor );	
	float newEIntensityContrastV2=lerp(EIntensityContrastV2Interior, (lerp(EIntensityContrastV2Night,EIntensityContrastV2Day,ENightDayFactor) ), EInteriorFactor );
	float newEColorSaturationV2=lerp(EColorSaturationV2Interior, (lerp(EColorSaturationV2Night,EColorSaturationV2Day,ENightDayFactor) ),EInteriorFactor );
	float newEToneMappingOversaturationV2=lerp(EToneMappingOversaturationV2Interior, (lerp(EToneMappingOversaturationV2Night,EToneMappingOversaturationV2Day,ENightDayFactor) ), EInteriorFactor); 
	

	grayadaptation=max(grayadaptation, 0.0);
	grayadaptation=min(grayadaptation, 50.0);
	color.xyz=color.xyz/(grayadaptation*newEAdaptationMax+newEAdaptationMin);//*tempF1.x

	color.xyz*=(newEBrightnessV2);
	color.xyz+=0.000001;
	float3 xncol=normalize(color.xyz);
	float3 scl=color.xyz/xncol.xyz;
	scl=pow(scl, newEIntensityContrastV2);
	xncol.xyz=pow(xncol.xyz, newEColorSaturationV2);
	color.xyz=scl*xncol.xyz;

	float	lumamax=newEToneMappingOversaturationV2;
	color.xyz=(color.xyz * (1.0 + color.xyz/lumamax))/(color.xyz + newEToneMappingCurve);
	
#endif


#if (POSTPROCESS==3)

	grayadaptation=max(grayadaptation, 0.0);
	grayadaptation=min(grayadaptation, 50.0);
	color.xyz=color.xyz/(grayadaptation*EAdaptationMaxV3+EAdaptationMinV3);//*tempF1.x

	float	lumamax=EToneMappingOversaturationV3;
	color.xyz=(color.xyz * (1.0 + color.xyz/lumamax))/(color.xyz + EToneMappingCurveV3);

#endif

//color.xyz=tex2D(_s0, _v0.xy) + xcolorbloom.xyz*float3(0.7, 0.6, 1.0)*0.5;
//color.xyz=tex2D(_s0, _v0.xy) + xcolorbloom.xyz*float3(0.7, 0.6, 1.0)*0.5;
//color.xyz*=0.7;


#if (POSTPROCESS==4)

	grayadaptation=max(grayadaptation, 0.0);
	grayadaptation=min(grayadaptation, 50.0);
	color.xyz=color.xyz/(grayadaptation*EAdaptationMaxV4+EAdaptationMinV4);

	float Y = dot(color.xyz, float3(0.299, 0.587, 0.114)); //0.299 * R + 0.587 * G + 0.114 * B;
	float U = dot(color.xyz, float3(-0.14713, -0.28886, 0.436)); //-0.14713 * R - 0.28886 * G + 0.436 * B;
	float V = dot(color.xyz, float3(0.615, -0.51499, -0.10001)); //0.615 * R - 0.51499 * G - 0.10001 * B;
	Y=pow(Y, EBrightnessCurveV4);
	Y=Y*EBrightnessMultiplierV4;
//	Y=Y/(Y+EBrightnessToneMappingCurveV4);
//	float	desaturatefact=saturate(Y*Y*Y*1.7);
//	U=lerp(U, 0.0, desaturatefact);
//	V=lerp(V, 0.0, desaturatefact);
	color.xyz=V * float3(1.13983, -0.58060, 0.0) + U * float3(0.0, -0.39465, 2.03211) + Y;

	color.xyz=max(color.xyz, 0.0);
	color.xyz=color.xyz/(color.xyz+EBrightnessToneMappingCurveV4);

#endif



	//pallete texture (0.082+ version feature)
#ifdef E_CC_PALETTE
	color.rgb=saturate(color.rgb);
	float3	brightness=Adaptation.xyz;//tex2D(_s4, 0.5);//adaptation luminance
//	brightness=saturate(brightness);//old version from ldr games
	brightness=(brightness/(brightness+1.0));//new version
	brightness=max(brightness.x, max(brightness.y, brightness.z));//new version
	float3	palette;
	float4	uvsrc=0.0;
	uvsrc.y=brightness.r;
	uvsrc.x=color.r;
	palette.r=tex2Dlod(_s7, uvsrc).r;
	uvsrc.x=color.g;
	uvsrc.y=brightness.g;
	palette.g=tex2Dlod(_s7, uvsrc).g;
	uvsrc.x=color.b;
	uvsrc.y=brightness.b;
	palette.b=tex2Dlod(_s7, uvsrc).b;
	color.rgb=palette.rgb;
#endif //E_CC_PALETTE

	_oC0.w=1.0;
	_oC0.xyz=color.xyz;
	return _oC0;
}



//switch between vanilla and mine post processing
#ifndef ENB_FLIPTECHNIQUE
technique Shader_D6EC7DD1
#else
technique Shader_ORIGINALPOSTPROCESS
#endif
{
	pass p0
	{
		VertexShader  = compile vs_3_0 VS_Quad();
		PixelShader  = compile ps_3_0 PS_D6EC7DD1();

		ColorWriteEnable=ALPHA|RED|GREEN|BLUE;
		ZEnable=FALSE;
		ZWriteEnable=FALSE;
		CullMode=NONE;
		AlphaTestEnable=FALSE;
		AlphaBlendEnable=FALSE;
		SRGBWRITEENABLE=FALSE;
	}
}



//original shader of post processing
#ifndef ENB_FLIPTECHNIQUE
technique Shader_ORIGINALPOSTPROCESS
#else
technique Shader_D6EC7DD1
#endif
{
	pass p0
	{
		VertexShader  = compile vs_3_0 VS_Quad();
		PixelShader=
	asm
	{
// Parameters:
//   sampler2D Avg;
//   sampler2D Blend;
//   float4 Cinematic;
//   float4 ColorRange;
//   float4 Fade;
//   sampler2D Image;
//   float4 Param;
//   float4 Tint;
// Registers:
//   Name         Reg   Size
//   ------------ ----- ----
//   ColorRange   c1       1
//   Param        c2       1
//   Cinematic    c3       1
//   Tint         c4       1
//   Fade         c5       1
//   Image        s0       1
//   Blend        s1       1
//   Avg          s2       1
//s0 bloom result
//s1 color
//s2 is average color

    ps_3_0
    def c6, 0, 0, 0, 0
    //was c0 originally
    def c7, 0.212500006, 0.715399981, 0.0720999986, 1
    dcl_texcoord v0.xy
    dcl_2d s0
    dcl_2d s1
    dcl_2d s2
    rcp r0.x, c2.y
    texld r1, v0, s2
    mul r0.yz, r1.xxyw, c1.y
    rcp r0.w, r0.y
    mul r0.z, r0.w, r0.z
    texld r1, v0, s1
    mul r1.xyz, r1, c1.y
    dp3 r0.w, c7, r1
    mul r1.w, r0.w, r0.z
    mad r0.z, r0.z, r0.w, c7.w
    rcp r0.z, r0.z
    mad r0.x, r1.w, r0.x, c7.w
    mul r0.x, r0.x, r1.w
    mul r0.x, r0.z, r0.x
    cmp r0.x, -r0.w, c6.x, r0.x
    rcp r0.z, r0.w
    mul r0.z, r0.z, r0.x
    add_sat r0.x, -r0.x, c2.x
    texld r2, v0, s0
    mul r2.xyz, r2, c1.y
    mul r2.xyz, r0.x, r2
    mad r1.xyz, r1, r0.z, r2
    dp3 r0.x, r1, c7
    mov r1.w, c7.w
    lrp r2, c3.x, r1, r0.x
    mad r1, r0.x, c4, -r2
    mad r1, c4.w, r1, r2
    mad r1, c3.w, r1, -r0.y
    mad r0, c3.z, r1, r0.y
    add r1, -r0, c5
    mad oC0, c5.w, r1, r0
	};
		ColorWriteEnable=ALPHA|RED|GREEN|BLUE;
		ZEnable=FALSE;
		ZWriteEnable=FALSE;
		CullMode=NONE;
		AlphaTestEnable=FALSE;
		AlphaBlendEnable=FALSE;
		SRGBWRITEENABLE=FALSE;
    }
}

