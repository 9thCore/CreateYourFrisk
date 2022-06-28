// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "CYF/Cylinder"
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
        XScale("X Scale", Float) = 1
        YScale("Y Scale", Float) = 1
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
            Name "CoreShadersCylinderPass"
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
            float XScale;
            float YPos;
            float YScale;

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

                float CurrentSinStep = IN.screenPos.x*3.1415;
                float CurrentCosStep = (IN.screenPos.y-0.5)*3.1415;

                half4 color = half4(1,1,1,1);
                float divBy480 = 0.002083;
                float divBy640 = 0.0015625;

                // Vertical
                float YOffset = YPos - 240;

                float CurrentHeight = sin(CurrentSinStep);

                float additionalOffset = -CurrentHeight * YOffset*divBy480;

                float finalY = lerp(-(0.5 - CurrentHeight*0.5), (0.5 - CurrentHeight*0.5), IN.uv.y);
                finalY += additionalOffset*480/YScale*_MainTex_TexelSize.y + YOffset*divBy480*0.5;

                // Horizontal
                float XOffset = XPos - 320;

                float CurrentWidth = cos(CurrentCosStep);

                additionalOffset = -CurrentWidth * XOffset*divBy640;

                float finalX = lerp(-(0.5 - CurrentWidth*0.5), (0.5 - CurrentWidth*0.5), IN.uv.x);
                finalX += additionalOffset*640/XScale*_MainTex_TexelSize.x + XOffset*divBy640*0.5;

                // Final combination
                IN.uv.x -= finalX * XStrength;
                IN.uv.y -= finalY * YStrength;

                color = (tex2D(_MainTex, IN.uv) + _TextureSampleAdd) * IN.color;

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