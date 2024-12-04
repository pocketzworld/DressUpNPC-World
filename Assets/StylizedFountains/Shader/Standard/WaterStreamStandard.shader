Shader "Custom/WaterStreamStandard"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_FresnelPower("Fresnel Power", Float) = 1
		_NoiseTexture("Noise Texture", 2D) = "white" {}
		_NoiseTiling("Noise Tiling", Vector) = (3,0.2,0,0)
		_NoiseSpeed("Noise Speed", Float) = 1
		_Noise2Texture("Noise 2 Texture", 2D) = "white" {}
		_Noise2Tiling("Noise 2 Tiling", Vector) = (1,0.2,0,0)
		_Noise2Speed("Noise 2 Speed", Float) = 0
		_NoiseBlendAmount("Noise Blend Amount", Range( 0 , 1)) = 0.5
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma surface surf Unlit alpha:fade keepalpha 
		struct Input
		{
			float2 uv_texcoord;
			float4 vertexColor : COLOR;
			float3 worldPos;
			float3 worldNormal;
		};

		uniform float4 _Color;
		uniform sampler2D _NoiseTexture;
		uniform float _NoiseSpeed;
		uniform float2 _NoiseTiling;
		uniform sampler2D _Noise2Texture;
		uniform float _Noise2Speed;
		uniform float2 _Noise2Tiling;
		uniform float _NoiseBlendAmount;
		uniform float _FresnelPower;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			o.Emission = _Color.rgb;
			float2 uv_TexCoord19 = i.uv_texcoord * _NoiseTiling;
			float2 panner18 = ( _Time.y * ( _NoiseSpeed * float2( 0,1 ) ) + uv_TexCoord19);
			float2 uv_TexCoord75 = i.uv_texcoord * _Noise2Tiling;
			float2 panner74 = ( _Time.y * ( _Noise2Speed * float2( 0,1 ) ) + uv_TexCoord75);
			float4 lerpResult112 = lerp( tex2D( _NoiseTexture, panner18 ) , tex2D( _Noise2Texture, panner74 ) , _NoiseBlendAmount);
			float3 worldPos = i.worldPos;
			float3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
			float3 worldNormal = i.worldNormal;
			float fresnelNdotV57 = dot( worldNormal, worldViewDir );
			float fresnelNode57 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV57, _FresnelPower ) );
			o.Alpha = ( ( _Color.a * ( lerpResult112 * i.vertexColor ) ) * ( 1.0 - fresnelNode57 ) ).r;
		}

		ENDCG
	}
	Fallback "Diffuse"
}