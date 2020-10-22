Shader "phi_util/BasicParticle"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "DisableBatching"="True" }
        LOD 100
        AlphaToMask On
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/phi_util/Util.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            appdata vert (appdata v) { return v; }

            [maxvertexcount(4)]
            void geom(point appdata IN[1], inout TriangleStream<v2f> stream) {
                v2f o;
                uint ix = IN[0].vertex.x;
                float2 seed = float2(ix/1000.0, 0);
                float3 center = float3(rand(seed+0), rand(seed+1), rand(seed+2)) - 0.5;
                float size = lerp(0.01, 0.03, rand(seed+3));
                center = mul(UNITY_MATRIX_M, float4(center,1));

                float2 uvs[4] = { float2(-1,-1), float2(-1,1), float2(1,-1), float2(1,1) };
                float3 normal = normalize(center - _WorldSpaceCameraPos);
                float3 tangent = normalize(mul(transpose((float3x3)UNITY_MATRIX_V), float3(1,0,0)));
                float3 binormal = normalize(cross(tangent, normal));
                tangent *= size, binormal *= size;
                
                for(int i=0;i<4;i++) {
                    o.worldPos = center + tangent*uvs[i].x + binormal*uvs[i].y;
                    o.vertex = mul(UNITY_MATRIX_VP, float4(o.worldPos,1));
                    o.uv = uvs[i];
                    stream.Append(o);
                }
                stream.RestartStrip();
            }

            float4 _Color;

            fixed4 frag (v2f i) : SV_Target {
                float d = length(i.uv);
                float3 col = lerp(float3(0,0,1), float3(0,1,1), i.uv.y*0.5+0.5);
                float alpha = 1 - distance(d, 0.9) * 10;
                // ref: https://github.com/momoma-null/MomomaShaders/blob/master/Surface/MS_Surface_AlphaToCoverage.shader
                alpha = saturate(alpha / max(fwidth(alpha), 0.0001) + 0.5);
                return float4(col,alpha);
            }
            ENDCG
        }
    }
}
