// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "CYF/BlendModes"
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

        BlendMode("Active Blend Mode", Int) = 1

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

        GrabPass{}

        Pass
        {
            Name "CoreShadersBlendModesPass"
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
                float2 grabPos : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;

            int BlendMode;

            sampler2D _GrabTexture;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                OUT.grabPos = ComputeGrabScreenPos(OUT.vertex);

                OUT.color = v.color;
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                half4 src = (tex2D(_MainTex, IN.uv) + _TextureSampleAdd) * IN.color;

                half4 dst = (tex2D(_GrabTexture, IN.grabPos) + _TextureSampleAdd);

                half4 res = half4(1, 0, 1, src.a);
                half alpha= IN.color.a;


                res.rgb = BlendMode == 1 ? dst.rgb + src.rgb : /* Add */
                          BlendMode == 2 ? dst.rgb - src.rgb : /* Subtract */
                          BlendMode == 3 ? dst.rgb * src.rgb : /* Multiply */
                          BlendMode == 4 ? max(dst.rgb, src.rgb) : /* Lighten */
                          BlendMode == 5 ? min(dst.rgb, src.rgb) : /* Darken */
                          BlendMode == 6 ? abs(src.rgb - dst.rgb) : /* Difference */
                          BlendMode == 7 ? 1 - dst.rgb * src.rgb : /* Invert */
                          src.rgb; /* Fallback */


                #ifdef UNITY_UI_CLIP_RECT
                res.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip(res.a - 0.001);
                #endif

                return res;
            }
        ENDCG
        }
    }
}