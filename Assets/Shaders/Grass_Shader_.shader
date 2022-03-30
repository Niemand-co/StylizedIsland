Shader "Demo/Grass_Shader_"
{
    Properties
    {
        _BaseLight ("Base Light", float) = 1.1
        _Wind ("Wind", vector) = (1, 0, 1, 0.2)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderQueue"="Transparent"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 Position : POSITION;
                float3 Normal : NORMAL;
            };

            struct v2f
            {
                float4 ClipPos : SV_POSITION;
                float3 WorldPos : TEXCOORD1;
                fixed4 Color : TEXCOORD2;
                float3 Normal : TEXCOORD3;
            };

            float _BaseLight;
            float4 _Wind;

            float2 rand(float2 st, int seed)
            {
                float2 s = float2(dot(st, float2(127.1, 311.7)) + seed, dot(st, float2(269.5, 183.3)) + seed);
                return -1 + 2 * frac(sin(s) * 43758.5453123);
            }

            float noise(float2 st, int seed)
            {
                st.y += _Time.y;

                float2 p = floor(st);
                float2 f = frac(st);

                float w00 = dot(rand(p, seed), f);
                float w10 = dot(rand(p + float2(1, 0), seed), f - float2(1, 0));
                float w01 = dot(rand(p + float2(0, 1), seed), f - float2(0, 1));
                float w11 = dot(rand(p + float2(1, 1), seed), f - float2(1, 1));

                float2 u = f * f * (3 - 2 * f);

                return lerp(lerp(w00, w10, u.x), lerp(w01, w11, u.x), u.y);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.WorldPos = mul(UNITY_MATRIX_M, v.Position);
                o.Normal = UnityObjectToWorldNormal(v.Normal);
                float nois = noise(o.WorldPos.xz, 0);
                o.WorldPos.x += sin(nois * _Wind.x) * _Wind.x * v.Position.y * _Wind.w;
                o.WorldPos.z += sin(nois * _Wind.z) * _Wind.z * v.Position.y * _Wind.w;
                o.ClipPos = mul(UNITY_MATRIX_VP, float4(o.WorldPos, 1.0));
                o.Color = fixed4(0.1, 0.8, 0.1, 1.0) * saturate((v.Position.y + 0.5) * _BaseLight);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 L = normalize(UnityWorldSpaceLightDir(i.WorldPos));
                float diffuse = max(0.5, dot(L, i.Normal));
                return i.Color * diffuse;
            }
            ENDCG
        }
    }
}
