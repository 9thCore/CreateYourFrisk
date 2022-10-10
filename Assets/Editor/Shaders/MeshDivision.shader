// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "CYF/MeshDivision"
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

		DivX("DivX", Float) = 1
		DivY("DivY", Float) = 1

		DivOffsetX("DivOffsetX", Float) = 0
		DivOffsetY("DivOffsetY", Float) = 0

		V1X("V1X", Float) = 0
		V1Y("V1Y", Float) = 0
        V2X("V2X", Float) = 0
		V2Y("V2Y", Float) = 0
        V3X("V3X", Float) = 0
		V3Y("V3Y", Float) = 0
        V4X("V4X", Float) = 0
		V4Y("V4Y", Float) = 0

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
			Name "Default"
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			#pragma multi_compile __ UNITY_UI_CLIP_RECT
			#pragma multi_compile __ UNITY_UI_ALPHACLIP

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
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;
			float4 _MainTex_ST;

			float DivX;
			float DivY;

			float DivOffsetX;
			float DivOffsetY;

			float V1X;
			float V1Y;
			float V2X;
			float V2Y;
			float V3X;
			float V3Y;
			float V4X;
			float V4Y;

			v2f vert(appdata_t v, uint vid : SV_VertexID)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

				OUT.worldPosition = v.vertex;

				fixed isv1 = vid == 0;
                fixed isv2 = vid == 1;
                fixed isv3 = vid == 2;
                fixed isv4 = vid == 3;

                OUT.worldPosition.x += V1X*isv1 + V2X*isv2 + V3X*isv3 + V4X*isv4;
                OUT.worldPosition.y += V1Y*isv1 + V2Y*isv2 + V3Y*isv3 + V4Y*isv4;

				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				OUT.color = v.color;
				return OUT;

			}

			fixed4 frag(v2f IN) : SV_Target
			{

				IN.uv.x *= DivX;
				IN.uv.y *= DivY;

				IN.uv.x += DivOffsetX * DivX;
				IN.uv.y += DivOffsetY * DivY;

				half4 color = (tex2D(_MainTex, IN.uv) + _TextureSampleAdd) * IN.color;

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