float4x4 worldToCameraMatrix;
float4x4 projMatrix;
float4x4 textureMatrix;

Texture2D txDiffuse;

SamplerState samNearest
{
    Filter = MIN_MAG_MIP_POINT;
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

    output.pos = mul(input.pos, worldToCameraMatrix);
    output.pos = mul(output.pos, projMatrix);
    output.col = input.col;
    output.texCoord = mul(float4(input.texCoord.xy, 0, 1), textureMatrix).xy;

    return output;
}

float4 PS( PS_IN input ) : SV_Target
{
    return txDiffuse.Sample(samNearest, input.texCoord) * input.col;
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
