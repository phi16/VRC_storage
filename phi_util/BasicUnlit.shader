Shader "phi_util/BasicUnlit"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "DisableBatching"="True" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 color : TEXCOORD0;
            };

            appdata vert (appdata v) { return v; }

            [maxvertexcount(3)]
            void geom(triangle appdata IN[3], inout TriangleStream<v2f> stream) {
                v2f o;
                for(int i=0;i<3;i++) {
                    appdata v = IN[i];
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.color = 1;
                    stream.Append(o);
                }
                stream.RestartStrip();
            }

            float4 _Color;

            fixed4 frag (v2f i) : SV_Target {
                float3 col = _Color * i.color;
                return float4(col,1);
            }
            ENDCG
        }
    }
}
