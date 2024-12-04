Shader "Custom/Water"
{
	Properties
	{
		_Color("Color", Color) = (0.6745283,0.8794996,1,0.1411765)
		_Noise("Noise", 2D) = "white" {}
		_NoiseAmount("NoiseAmount", Float) = 0.23
		_NoiseScale("NoiseScale", Vector) = (1,1,0,0)
		_NoiseSpeed("NoiseSpeed", Float) = 0.055
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" }
		Cull Back
		GrabPass{ }
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
		#define DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex);
		#else
		#define DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
		#endif
		#pragma surface surf Standard alpha:fade keepalpha 
		struct Input
		{
			float4 screenPos;
			float2 uv_texcoord;
		};

		DECLARE_SCREENSPACE_TEXTURE( _GrabTexture )
		uniform sampler2D _Noise;
		uniform float _NoiseSpeed;
		uniform float2 _NoiseScale;
		uniform float _NoiseAmount;
		uniform float4 _Color;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float4 screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 screenPosNorm = screenPos / screenPos.w;
			screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;
			float2 uv_TexCoord19 = i.uv_texcoord * _NoiseScale;
			float2 panner18 = ( _Time.y * ( _NoiseSpeed * float2( 0,1 ) ) + uv_TexCoord19);
			float4 screenColor26 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,( screenPosNorm + ( (float4( 0,0,0,0 ) + (tex2D( _Noise, panner18 ) - float4( 0,0,0,0 )) * (float4( 1,1,1,1 ) - float4( 0,0,0,0 )) / (float4( 1,1,1,1 ) - float4( 0,0,0,0 ))) * _NoiseAmount ) ).xy);
			float4 lerpResult51 = lerp( screenColor26 , _Color , _Color.a);
			o.Albedo = lerpResult51.rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
}