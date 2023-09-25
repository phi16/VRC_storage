Shader "Im/Template/Particles/Update"
{
    Properties
    {
        _Store ("Store", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Particles.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
#if UNITY_UV_STARTS_AT_TOP
                o.vertex = float4(v.uv.x*2-1,1-v.uv.y*2,1,1);
#else
                o.vertex = float4(v.uv.x*2-1,v.uv.y*2-1,1,1);
#endif
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                uint2 iuv = i.uv * F;
                return update(iuv);
            }
            ENDCG
        }
    }
}
