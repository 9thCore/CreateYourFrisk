// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "CYF/VertexOffset"
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


        Vertex1X("The horizontal offset of the 1st vertex, in pixels.", Float) = 0
        Vertex1Y("The vertical offset of the 1st vertex, in pixels.", Float) = 0

        Vertex2X("The horizontal offset of the 2nd vertex, in pixels.", Float) = 0
        Vertex2Y("The vertical offset of the 2nd vertex, in pixels.", Float) = 0

        Vertex3X("The horizontal offset of the 3rd vertex, in pixels.", Float) = 0
        Vertex3Y("The vertical offset of the 3rd vertex, in pixels.", Float) = 0

        Vertex4X("The horizontal offset of the 4th vertex, in pixels.", Float) = 0
        Vertex4Y("The vertical offset of the 4th vertex, in pixels.", Float) = 0

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
            Name "CoreShadersVertexOffsetPass"
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

            fixed Vertex1X;
            fixed Vertex1Y;
            fixed Vertex2X;
            fixed Vertex2Y;
            fixed Vertex3X;
            fixed Vertex3Y;
            fixed Vertex4X;
            fixed Vertex4Y;

            // vid is the id of the vertex
            // ids are as follows
            //
            //  1      2
            //
            //
            //  0      3
            //
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

                OUT.worldPosition.x += Vertex1X*isv1 + Vertex2X*isv2 + Vertex3X*isv3 + Vertex4X*isv4;
                OUT.worldPosition.y += Vertex1Y*isv1 + Vertex2Y*isv2 + Vertex3Y*isv3 + Vertex4Y*isv4;

                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                OUT.color = v.color;
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {

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