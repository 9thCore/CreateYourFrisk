// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "CYF/CopyScreen"
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

        CopyX("Copy X", Float) = 320
        CopyY("Copy Y", Float) = 240
        CopyWidth("Copy Width", Float) = 640
        CopyHeight("Copy Height", Float) = 480

        WrapModeHorizontal("Wrap Mode H", Int) = 1
        WrapModeVertical("Wrap Mode V", Int) = 1

        VoidColor("Void Color", Color) = (0, 0, 0, 1)

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
            Name "CoreShadersCopyScreenPass"
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
                float2 origUV : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _TextureSampleAdd;
            float4 _ClipRect;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _GrabTexture;
            float4 _GrabTexture_ST;
            uniform float4 _GrabTexture_TexelSize;

            static const float divBy640 = (float)1/640;
            static const float divBy480 = (float)1/480;

            float CopyX;
            float CopyY;
            float CopyWidth;
            float CopyHeight;

            int WrapModeHorizontal;
            int WrapModeVertical;

            float4 VoidColor;

            float tile(float coord){
                return coord<0 ? coord-floor(coord) : coord%1;
            }

            float mirror(float coord){
                return floor(coord)%2==0 ? (coord<0 ? coord-floor(coord) : coord%1) : (coord<0 ? -coord%1 : 1 - coord%1);
            }

            float mirroronce(float coord){
                return
                (coord >= 0 && coord < 1)
                ? coord
                : coord < 0
                    ? ((coord >= -1 && coord < 0)
                        ? mirror(coord)
                        : 1)
                    : ((coord >= 1 && coord < 2)
                        ? mirror(coord)
                        : 0); 
            }

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.uv = TRANSFORM_TEX(v.texcoord, _GrabTexture);
                OUT.origUV = TRANSFORM_TEX(v.texcoord, _MainTex);

                OUT.color = v.color;
                return OUT;
            }

                fixed4 frag(v2f IN) : SV_Target
                {
                    bool usingVoid = 0;

                    CopyY = 240-(CopyY-240);

                    IN.uv.x = lerp(CopyX - CopyWidth/2, CopyX + CopyWidth/2, IN.uv.x)*divBy640;
                    IN.uv.y = lerp(CopyY - CopyHeight/2, CopyY + CopyHeight/2, IN.uv.y)*divBy480;

                    #ifndef NO_PIXEL_SNAP
                    IN.uv.x = (floor(IN.uv.x * _GrabTexture_TexelSize.z) + 0.5) / _GrabTexture_TexelSize.z;
                    IN.uv.y = (floor(IN.uv.y * _GrabTexture_TexelSize.w) + 0.5) / _GrabTexture_TexelSize.w;
                    #endif

                    usingVoid = (WrapModeHorizontal == 5 && (IN.uv.x < 0 || IN.uv.x > 1) ) ? 1 :
                                (WrapModeVertical == 5 && (IN.uv.y < 0 || IN.uv.y > 1) ) ? 1 :
                                0;

                    IN.uv.x = WrapModeHorizontal == 1 ? (clamp(IN.uv.x, 0, 1)) :
                              WrapModeHorizontal == 2 ? (tile(IN.uv.x)) :
                              WrapModeHorizontal == 3 ? (mirror(IN.uv.x)) :
                              WrapModeHorizontal == 4 ? (mirroronce(IN.uv.x)) :
                              IN.uv.x;

                    IN.uv.y = WrapModeVertical == 1 ? (clamp(IN.uv.y, 0, 1)) :
                              WrapModeVertical == 2 ? (tile(IN.uv.y)) :
                              WrapModeVertical == 3 ? (mirror(IN.uv.y)) :
                              WrapModeVertical == 4 ? (mirroronce(IN.uv.y)) :
                              IN.uv.y;

                    half4 color = usingVoid ? VoidColor : (tex2D(_GrabTexture, IN.uv) + _TextureSampleAdd) * (tex2D(_MainTex, IN.origUV) + _TextureSampleAdd) * IN.color;

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