// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "CYF/CylinderMask"
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

        XStrength("X Strength", Float) = 0
        YStrength("Y Strength", Float) = 0.25
        XPos("X Position", Float) = 320
        YPos("Y Position", Float) = 240
        Width("Width", Float) = 640
        Height("Height", Float) = 480

        WrapModeHorizontal("WMH", Int) = 1
        WrapModeVertical("WMV", Int) = 1

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
            Name "CoreShadersCylinderPass"
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP
            #pragma multi_compile __ NO_PIXEL_SNAP
            #pragma multi_compile __ GLOBAL_CYLINDER

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
                float2 screenPos : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;

            uniform float4 _MainTex_TexelSize;

            float XStrength;
            float YStrength;
            float XPos;
            float YPos;
            float Width;
            float Height;

            int WrapModeHorizontal;
            int WrapModeVertical;

            float4 VoidColor;

            sampler2D _GrabTexture;

            uniform float4 _GrabTexture_TexelSize;

            static const float divBy480 = 0.002083;
            static const float divBy640 = 0.0015625;

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

            v2f vert(appdata_t v, uint vid : SV_VertexID)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;

                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.screenPos = ComputeScreenPos(OUT.vertex);

                OUT.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                OUT.color = v.color;
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float2 usedUV = IN.uv;
                #ifdef GLOBAL_CYLINDER
                usedUV = IN.screenPos;
                usedUV.y = 1-usedUV.y;
                #endif

                float CurrentSinStep = usedUV.x*3.1415;
                float CurrentCosStep = (usedUV.y-0.5)*3.1415;

                half4 color = half4(1,1,1,1);

                // Vertical
                float CurrentHeight = sin(CurrentSinStep);

                float finalY = lerp(-(0.5 - CurrentHeight*0.5), (0.5 - CurrentHeight*0.5), usedUV.y);

                // Horizontal
                float CurrentWidth = cos(CurrentCosStep);

                float finalX = lerp(-(0.5 - CurrentWidth*0.5), (0.5 - CurrentWidth*0.5), usedUV.x);

                float2 grabUV = IN.screenPos;
                grabUV.y = 1-grabUV.y;

                #ifndef GLOBAL_CYLINDER
                grabUV = IN.uv;

                grabUV.x = grabUV.x * divBy640 * Width;
                grabUV.y = grabUV.y * divBy480 * Height;

                grabUV.x += XPos * divBy640 - Width * divBy640 * 0.5;
                grabUV.y += -YPos * divBy480 + 1 - Height * divBy480 * 0.5;
                #endif

                // Final combination
                grabUV.x -= finalX * XStrength * Width * divBy640;
                grabUV.y -= finalY * YStrength * Height * divBy480;

                #ifndef NO_PIXEL_SNAP
                grabUV.x = (floor(grabUV.x * _GrabTexture_TexelSize.z) + 0.5) / _GrabTexture_TexelSize.z;
                grabUV.y = (floor(grabUV.y * _GrabTexture_TexelSize.w) + 0.5) / _GrabTexture_TexelSize.w;
                #endif

                bool usingVoid = (WrapModeHorizontal == 5 && (grabUV.x < 0 || grabUV.x > 1) ) ? 1 :
                                 (WrapModeVertical == 5 && (grabUV.y < 0 || grabUV.y > 1) ) ? 1 :
                                 0;

                grabUV.x = WrapModeHorizontal == 1 ? (clamp(grabUV.x, 0, 1)) :
                           WrapModeHorizontal == 2 ? (tile(grabUV.x)) :
                           WrapModeHorizontal == 3 ? (mirror(grabUV.x)) :
                           WrapModeHorizontal == 4 ? (mirroronce(grabUV.x)) :
                           grabUV.x;

                grabUV.y = WrapModeVertical == 1 ? (clamp(grabUV.y, 0, 1)) :
                           WrapModeVertical == 2 ? (tile(grabUV.y)) :
                           WrapModeVertical == 3 ? (mirror(grabUV.y)) :
                           WrapModeVertical == 4 ? (mirroronce(grabUV.y)) :
                           grabUV.y;

                color = usingVoid ? VoidColor : (tex2D(_GrabTexture, grabUV) + _TextureSampleAdd) * IN.color;

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