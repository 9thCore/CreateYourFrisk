// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "CYF/Slicer"
{
	Properties
	{
		_MainTex("Sprite Texture", 2D) = "white" {}

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255

		_ColorMask("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0

		XScale("The sprite's horizontal scaling. MUST BE SET TO THE SPRITE'S xscale OR THE SHADER WON'T WORK!", Float) = 1
		YScale("The sprite's vertical scaling. MUST BE SET TO THE SPRITE'S yscale OR THE SHADER WON'T WORK!", Float) = 1
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}

		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask[_ColorMask]

		Pass
		{
			Name "CoreShadersSlicerPass"
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			#pragma multi_compile __ UNITY_UI_CLIP_RECT
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma multi_compile __ TILE_CENTER

			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				float2 uv : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			sampler2D _MainTex;
            uniform float4 _MainTex_TexelSize;
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;
			float4 _MainTex_ST;

			float XScale;
			float YScale;

			v2f vert(appdata_t v)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = v.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				OUT.color = v.color;
				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{

				float2 actualUV = 0;

				half oneThird = float(1)/float(3);
				half idk = 1/oneThird;
				half calculation;
				half stepper;
				half stepper2;
				half formula;
				half scaler;

				// step(a,b) returns 0 if a is smaller than b and 1 otherwise
				// this makes it perfect for 9-slicing

				// X slicing
				scaler = max(abs(XScale),1);
				calculation = oneThird/scaler;
				stepper = step(1-calculation, IN.uv.x);
				stepper2 = step(calculation, IN.uv.x) * step(IN.uv.x, 1-calculation);
				formula = min(max(IN.uv.x, oneThird+_MainTex_TexelSize.x), oneThird*2);
				#if TILE_CENTER
					formula = (IN.uv.x*scaler + (oneThird+_MainTex_TexelSize.x)/2 - scaler/2%oneThird) % oneThird + oneThird;
				#endif

				actualUV.x = (IN.uv.x * scaler + ((IN.uv.x-(1-calculation)-IN.uv.x)*scaler + oneThird*2) * stepper) * (1-stepper2) + formula * stepper2;

				// Y slicing
				scaler = max(abs(YScale),1);
				calculation = oneThird/scaler;
				stepper = step(1-calculation, IN.uv.y);
				stepper2 = step(calculation, IN.uv.y) * step(IN.uv.y, 1-calculation);
				formula = min(max(IN.uv.y, oneThird+_MainTex_TexelSize.y), oneThird*2);
				#if TILE_CENTER
					formula = (IN.uv.y*scaler + (oneThird+_MainTex_TexelSize.y)/2 - scaler/2%oneThird) % oneThird + oneThird;
				#endif

				actualUV.y = (IN.uv.y * scaler + ((IN.uv.y-(1-calculation)-IN.uv.y)*scaler + oneThird*2) * stepper) * (1-stepper2) + formula * stepper2;

				half4 color = (tex2D(_MainTex, actualUV) + _TextureSampleAdd) * IN.color;

				#ifdef UNITY_UI_CLIP_RECT
				color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
				#endif

				#ifdef UNITY_UI_ALPHACLIP
				clip(color.a - 0.001);
				#endif

				return color;
			}
		ENDCG
		}
	}
}