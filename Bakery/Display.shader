Shader "Unlit/Display"
{
	Properties
	{
		_BakedMap ("Baked Map", 2D) = "white" {}
		_Input ("Input", 2D) = "white"
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry-1" }
		LOD 100
		Cull Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Util.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float3 pos : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			struct fragOut {
				float4 color : SV_Target;
				float depth : SV_Depth;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.pos = (mul(UNITY_MATRIX_M, v.vertex).xyz - float3(0,2.5,0)) / 5.0;
				return o;
			}

			float Depth(float3 pos)
            {
                float4 vpPos = mul(UNITY_MATRIX_VP, float4(pos,1.0));
                #if UNITY_UV_STARTS_AT_TOP
                    return vpPos.z / vpPos.w;
                #else
                    return (vpPos.z / vpPos.w) * 0.5 + 0.5;
                #endif
            }

			fragOut frag (v2f i)
			{
				Scene scene = loadScene();
				float3 eye = (_WorldSpaceCameraPos - float3(0,2.5,0)) / 5.0;
				float4 firstCollision;
				Point p = rayCast(scene, eye, normalize(i.pos-eye), firstCollision);
				clip(firstCollision.w - 0.5);
				float3 col = p.type >= 0 ? radiance(p) : 0;
				// col = pow(col, 2.2);

				fragOut o;
				o.color = float4(saturate(col),1);
				o.depth = Depth(firstCollision.xyz*5 + float3(0,2.5,0));
				return o;
			}
			ENDCG
		}
	}
}
