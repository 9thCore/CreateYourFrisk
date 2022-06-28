// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "CYF/FisheyeAberration"
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


        RedStrength("Red Channel Strength", Float) = 0.125
        GreenStrength("Green Channel Strength", Float) = 0.125
        BlueStrength("Blue Channel Strength", Float) = 0.125

        RedXPivot("Red Channel XPivot", Float) = 0.5
        RedYPivot("Red Channel YPivot", Float) = 0.5
        BlueXPivot("Blue Channel XPivot", Float) = 0.5
        BlueYPivot("Blue Channel YPivot", Float) = 0.5
        GreenXPivot("Green Channel XPivot", Float) = 0.5
        GreenYPivot("Green Channel YPivot", Float) = 0.5
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
            Name "CoreShadersFisheyeAberrationPass"
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP
            #pragma multi_compile __ NO_PIXEL_SNAP

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

            float RedStrength;
            float GreenStrength;
            float BlueStrength;

            float RedXPivot;
            float RedYPivot;
            float BlueXPivot;
            float BlueYPivot;
            float GreenXPivot;
            float GreenYPivot;

            float2 applyTransformation(float2 input, float px, float py, float str, float dist){
                float2 convertedUV = input;

                convertedUV.x -= px;
                convertedUV.y -= py;
                convertedUV /= (1 - dist*str);
                input.x = convertedUV.x + px;
                input.y = convertedUV.y + py;

                #ifndef NO_PIXEL_SNAP
                input.x = (floor(input.x * _MainTex_TexelSize.z) + 0.5) / _MainTex_TexelSize.z;
                input.y = (floor(input.y * _MainTex_TexelSize.w) + 0.5) / _MainTex_TexelSize.w;
                #endif

                return input;
            }

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

                float xdist = IN.uv.x - 0.5;
                float ydist = IN.uv.y - 0.5;
                float distToCenter = sqrt(xdist*xdist+ydist*ydist);

                float2 convertedUV;

                convertedUV = applyTransformation(IN.uv, RedXPivot, RedYPivot, RedStrength, distToCenter);
                half4 red = (tex2D(_MainTex, convertedUV) + _TextureSampleAdd) * IN.color;

                convertedUV = applyTransformation(IN.uv, GreenXPivot, GreenYPivot, GreenStrength, distToCenter);
                half4 green = (tex2D(_MainTex, convertedUV) + _TextureSampleAdd) * IN.color;

                convertedUV = applyTransformation(IN.uv, BlueXPivot, BlueYPivot, BlueStrength, distToCenter);
                half4 blue = (tex2D(_MainTex, convertedUV) + _TextureSampleAdd) * IN.color;

                half4 color = half4(red.r, green.g, blue.b, 1);

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