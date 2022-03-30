Shader "Demo/BasePassTranslucent"
{
    Properties
    {
        _Sky ("Sky", Cube) = "" {}
        _ReflectionTex ("Reflection Texture", 2D) = "White" {}
        _Distortion ("Distortion", float) = 0.2
        _SpecularStrength ("Specular Strength", float) = 0.8
        _SpecularRange ("Specular Range", Int) = 32
        _Fresnel ("Fresnel", float) = 0.2
        _WaveStrength ("Wave Strength", float) = 0.006
        _Foam ("Foam", 2D) = "" {}
        _WaveSpeed ("Wave Speed", float) = 1.0
        _Edge ("Edge", float) = 0.2
        _Caustic ("Caustic", 2D) = "" {}
    }
    SubShader
    {

        Tags {"RenderType"="Transparent" "Queue"="Transparent" "LightMode"="FORWARDBASE"}
        ZWrite Off
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _CameraDepthTexture;
            sampler2D _GT0;
            samplerCUBE _Sky;
            sampler2D _Foam;
            float4 _Foam_ST;
            sampler2D _Caustic;
            sampler2D _Caustic_ST;
            sampler2D _ReflectionTex;
            float4 _Reflection_TexelSize;
            int _SpecularRange;
            float _SpecularStrength;
            float _Fresnel;
            float _WaveStrength;
            float _WaveSpeed;
            float _Edge;
            float _Distortion;

            struct Vertex
            {
                float4 Position : POSITION;
                float3 Normal : NORMAL;
                float3 Tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 ClipPos : SV_Position;
                float2 uv : TEXCOORD0;
                float3 WorldPos : TEXCOORD1;
                float4 ScreenPos : TEXCOORD2;
                float3 Normal : TEXCOORD3;
                float3 Tangent : TEXCOORD4;
            };

            float Unpack(float4 rgbaDepth)
            {
                float4 bitShift = float4(1.0, 1.0 / 256.0, 1.0 / (256.0 * 256.0), 1.0 / (256.0 * 256.0 * 256.0));
                return dot(rgbaDepth, bitShift);
            }

            fixed4 cosine_gradient(float x,  fixed4 phase, fixed4 amp, fixed4 freq, fixed4 offset)
            {
                const float TAU = 2. * 3.14159265;
                phase *= TAU;
                x *= TAU;

                return fixed4(
                    offset.r + amp.r * 0.5 * cos(x * freq.r + phase.r) + 0.5,
                    offset.g + amp.g * 0.5 * cos(x * freq.g + phase.g) + 0.5,
                    offset.b + amp.b * 0.5 * cos(x * freq.b + phase.b) + 0.5,
                    offset.a + amp.a * 0.5 * cos(x * freq.a + phase.a) + 0.5
                );
            }

            fixed3 toRGB(fixed3 grad)
            {
                return grad.rgb;
            }

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

            float3 swell(float3 pos, float anisotropy)
            {
                float height = noise(pos.xz * 0.1,0) * anisotropy;
                float3 normal = normalize(cross(float3(0,ddy(height),1), float3(1,ddx(height),0)));
                return normal;
            }

            v2f vert (Vertex v)
            {
                v2f o;
                float height = noise(v.Position.xz * 0.15, 0) * _WaveStrength;
                v.Position.y += height / 2.0;
                o.WorldPos = mul(UNITY_MATRIX_M, v.Position).xyz;
                o.ClipPos = UnityObjectToClipPos(v.Position);
                o.uv = TRANSFORM_TEX(v.uv, _Foam);
                o.ScreenPos = UNITY_PROJ_COORD(ComputeScreenPos(o.ClipPos));
                o.ScreenPos.z = -mul(UNITY_MATRIX_MV, v.Position).z;

                o.Normal = normalize(UnityObjectToWorldNormal(v.Normal.xyz));
                o.Tangent = normalize(UnityObjectToWorldDir(v.Tangent.xyz));

                return o;
            }

            fixed4 BlendSeaColor(fixed4 col1,fixed4 col2)
            {
                fixed4 col = min(1,1.5-col2.a) * col1+col2.a * col2;
                return col;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                
                i.ScreenPos.xy /= i.ScreenPos.w;
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.ScreenPos.xy));
                float3 WorldViewDir = _WorldSpaceCameraPos - i.WorldPos;
                float depthDiff = (depth - i.ScreenPos.z) / 10.0;
                float depthRate = depth / i.ScreenPos.z;

                fixed4 col;

                const fixed4 phases = fixed4(0.28, 0.50, 0.07, 0);
                const fixed4 amplitudes = fixed4(4.02, 0.34, 0.65, 0);
                const fixed4 frequencies = fixed4(0.00, 0.48, 0.08, 0);
                const fixed4 offsets = fixed4(0.00, 0.16, 0.00, 0);
                fixed4 cos_grad = cosine_gradient(saturate(1.5-depthDiff), phases, amplitudes, frequencies, offsets);
                cos_grad = clamp(cos_grad, 0, 1);
                col.rgb = toRGB(cos_grad);

                
                float anisotropy = saturate(normalize(-WorldViewDir).xz);
                float3 normal = swell(i.WorldPos, anisotropy);
                float height = noise(i.WorldPos.xz * 1.0, 0);

                float Xoffset = height * _Distortion;
                i.ScreenPos.x = (1.0 - i.ScreenPos.x) + pow(Xoffset, 2) * saturate(depthDiff);
                fixed4 reflectColor = tex2D(_ReflectionTex, i.ScreenPos.xy);
                // float3 reflDir = reflect(-WorldViewDir, normal);
                // fixed4 reflectSkyColor= texCUBE(_Sky, reflDir);
                // reflectColor = BlendSeaColor(reflectColor, reflectSkyColor);

                float3 L = normalize(UnityWorldSpaceLightDir(i.WorldPos));
                float3 H = normalize(normalize(WorldViewDir) + L);
                float3 specular = _LightColor0.rgb * _SpecularStrength * pow(max(0, dot(normal ,H)), _SpecularRange);
                col += fixed4(specular,1);

                float2 CausticUV = i.uv;
                CausticUV.x += 0.08 * cos(_Time.y * height * 0.01);
                CausticUV.y += 0.1 * sin(_Time.y * height * 0.01);
                fixed4 caustic = tex2D(_Caustic, CausticUV) * depthRate * saturate(1.0 - depthDiff * depthDiff);
                col.rgb += caustic.rgb;

                //col += ddy(length(WorldViewDir.xz) * 30) / 200;
                i.uv.y -= _Time.y * _WaveSpeed;
                fixed4 foamTexCol = tex2D(_Foam, i.uv);
                fixed4 foamCol = saturate((0.7 - height) * (foamTexCol.r + foamTexCol.g) * depthDiff * 6) * step(depthDiff, _Edge) * step(depthRate * 0.12, _Edge);
                foamCol = step(0.5, foamCol);
                col += foamCol;

                _Fresnel = saturate(_Fresnel);
                float kd = _Fresnel + (1 - _Fresnel) * pow(1.0 - dot(normalize(WorldViewDir), normal), 5);
                kd = saturate(kd);
                col = lerp(col, reflectColor, kd);

                if(depthDiff < 0.0000001)
                    col.a = 0.9;
                else if(step(0.8, foamCol.r) > 0)
                    col.a = 0.9;
                else
                    col.a = saturate(depthDiff + 0.1);

                return col;
            }

            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}
