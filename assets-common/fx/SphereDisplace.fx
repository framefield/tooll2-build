float4x4 objectToWorldMatrix;
float4x4 worldToCameraMatrix;
float4x4 projMatrix;
float4x4 textureMatrix;

float2 center;
float2 radius;
float strength;
float bias;

Texture2D txDiffuse;

SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

struct VS_IN
{
    float4 pos : POSITION;
    float3 normal: NORMAL;
    float4 col : COLOR;
    float2 texCoord : TEXCOORD;
    float3 tangent: TANGENT;
    float3 binormal: BINORMAL;
};

struct PS_IN
{
    float4 pos : SV_POSITION;
    float4 col : COLOR;
    float2 texCoord: TEXCOORD0;
};

PS_IN VS( VS_IN input )
{
    PS_IN output = (PS_IN)0;

    input.pos = mul(input.pos, objectToWorldMatrix);

    float4 d = input.pos - float4(center.x, center.y, 0, 1);
    float distance = length(d);
    float4 offset = float4(0, 0, 0, 1);
    offset.x = pow(smoothstep(1, 0, distance/radius.x), bias);
    offset.y = pow(smoothstep(1, 0, distance/radius.y), bias);
    offset *= d*strength;

    input.pos = input.pos + offset;

    output.pos = mul(input.pos, worldToCameraMatrix);
    output.pos = mul(output.pos, projMatrix);

    output.col = input.col;
    output.texCoord = mul(float4(input.texCoord.xy, 0, 1), textureMatrix).xy;

    return output;
}

float4 PS( PS_IN input ) : SV_Target
{
    return txDiffuse.Sample(samLinear, input.texCoord) * input.col;
}

technique10 Render
{
    pass P0
    {
        SetGeometryShader( 0 );
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetPixelShader( CompileShader( ps_4_0, PS() ) );
    }
}
