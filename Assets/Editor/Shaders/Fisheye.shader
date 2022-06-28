﻿// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "CYF/Fisheye"
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


        Strength("Strength", Float) = 0.125
        XPivot("Horiontal Pivot", Float) = 0.5
        YPivot("Vertical Pivot", Float) = 0.5
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
            Name "CoreShadersFisheyePass"
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP
            #pragma multi_compile __ NO_PIXEL_SNAP
            #pragma multi_compile __ WRAP

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

            float Strength;
            float XPivot;
            float YPivot;

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

                float xdist = IN.uv.x - XPivot;
                float ydist = IN.uv.y - YPivot;
                float distToCenter = sqrt(xdist*xdist+ydist*ydist);

                float2 convertedUV = IN.uv;
                convertedUV.x -= XPivot;
                convertedUV.y -= YPivot;

                convertedUV /= (1 - distToCenter * Strength);

                IN.uv.x = convertedUV.x + XPivot;
                IN.uv.y = convertedUV.y + YPivot;

                #ifndef NO_PIXEL_SNAP
                IN.uv.x = (floor(IN.uv.x * _MainTex_TexelSize.z) + 0.5) / _MainTex_TexelSize.z;
                IN.uv.y = (floor(IN.uv.y * _MainTex_TexelSize.w) + 0.5) / _MainTex_TexelSize.w;
                #endif

                half4 color = (tex2D(_MainTex, IN.uv) + _TextureSampleAdd) * IN.color;

                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip(color.a - 0.001);
                #endif

                #ifndef WRAP
                color.a = (IN.uv.x < 0 || IN.uv.x > 1) || (IN.uv.y < 0 || IN.uv.y > 1) ? 0 : color.a;
                #endif

                return color;
            }
        ENDCG
        }
    }
}