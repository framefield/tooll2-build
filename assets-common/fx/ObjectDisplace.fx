float4x4 objectToWorldMatrix;
float4x4 worldToCameraMatrix;
float4x4 projMatrix;
float4x4 textureMatrix;

float2 scale;
float2 rotate;
float textureScale;

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

    uint MipLevel;
    uint Width;
    uint Height;
    uint Elements;
    uint Depth;
    uint NumberOfLevels;
    uint NumberOfSamples;
    txDiffuse.GetDimensions(Width, Height);

    float4 worldTPos = mul(float4(0, 0, 0, 1), objectToWorldMatrix);

    //float2 displaceTexCoord = float2( (worldTPos.x-50.0f) / 100.0f, (worldTPos.y-50.0f) / 100.0f);
    float2 displaceTexCoord = worldTPos.xy * textureScale;

	displaceTexCoord = mul(float4(displaceTexCoord.xy, 0, 1), textureMatrix).xy;
    float4 sample0 = txDiffuse.Load(int3((displaceTexCoord.x + 0.5) * Width,   (displaceTexCoord.y + 0.5) * Height, 0));
    float4 sample1 = txDiffuse.Load(int3((displaceTexCoord.x + 0.5) * Width-1, (displaceTexCoord.y + 0.5) * Height, 0));
    float4 sample2 = txDiffuse.Load(int3((displaceTexCoord.x + 0.5) * Width+1, (displaceTexCoord.y + 0.5) * Height, 0));
    float4 sample3 = txDiffuse.Load(int3((displaceTexCoord.x + 0.5) * Width,   (displaceTexCoord.y + 0.5) * Height-1, 0));
    float4 sample4 = txDiffuse.Load(int3((displaceTexCoord.x + 0.5) * Width,   (displaceTexCoord.y + 0.5) * Height+1, 0));

    float4 sample5 = txDiffuse.Load(int3((displaceTexCoord.x + 0.5) * Width-1, (displaceTexCoord.y + 0.5) * Height+1, 0));
    float4 sample6 = txDiffuse.Load(int3((displaceTexCoord.x + 0.5) * Width+1, (displaceTexCoord.y + 0.5) * Height+1, 0));
    float4 sample7 = txDiffuse.Load(int3((displaceTexCoord.x + 0.5) * Width-1,   (displaceTexCoord.y + 0.5) * Height-1, 0));
    float4 sample8 = txDiffuse.Load(int3((displaceTexCoord.x + 0.5) * Width+1,   (displaceTexCoord.y + 0.5) * Height-1, 0));

	float4 displaceSample = 0.3 * sample0 + (sample1 + sample2 + sample3 + sample4) *0.25 * 0.4 + (sample5 + sample6 + sample7 + sample8) *0.25 * 0.3 ;

    //displaceSample *= 10;
    float finalRotate = displaceSample.b * 2 * 3.14159265f / 360.0f * rotate.x + rotate.y * 2 * 3.14159265f / 360.0f;

    float4x4 rotateTransform;
    rotateTransform[0].xyzw =  float4(cos(finalRotate), sin(finalRotate), 0, 0);
    rotateTransform[1].xyzw =  float4(-sin(finalRotate), cos(finalRotate), 0, 0);
    rotateTransform[2].xyzw = float4(0, 0, 1, 0);
    rotateTransform[3].xyzw = float4(0, 0, 0, 1);

    float4x4 scaleTransform;
    scaleTransform[0].xyzw = float4(scale.x * displaceSample.r, 0, 0, 0);
    scaleTransform[1].xyzw = float4(0, scale.y * displaceSample.g, 0, 0);
    scaleTransform[2].xyzw = float4(0, 0, 1, 0);
    scaleTransform[3].xyzw = float4(0, 0, 0, 1);

    input.pos = mul(input.pos, rotateTransform);
    input.pos = mul(input.pos, scaleTransform);
    input.pos = mul(input.pos, objectToWorldMatrix);
    output.pos = mul(input.pos, worldToCameraMatrix);
    output.pos = mul(output.pos, projMatrix);

    output.col = input.col;
    output.texCoord = mul(float4(input.texCoord.xy, 0, 1), textureMatrix).xy;

    return output;
}

float4 PS( PS_IN input ) : SV_Target
{
//    return txDiffuse.Sample(samLinear, input.texCoord) * input.col;
    return input.col;
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
