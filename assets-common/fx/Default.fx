float4x4 objectToWorldMatrix;
float4x4 worldToCameraMatrix;
float4x4 cameraToObjectMatrix; // modelview inverse
float4x4 projMatrix;
float4x4 textureMatrix;


struct PointLight
{
    float4 position;
    float4 ambient;
    float4 diffuse;
    float4 specular;
};


cbuffer FogSettings
{
    float4 fogColor;
    float fogStart;
    float fogEnd;
    float fogScale;
}

cbuffer MaterialBuffer
{
    float4 materialAmbient;
    float4 materialDiffuse;
    float4 materialSpecular;
    float4 materialEmission;
    float materialShininess;
};


cbuffer PointLightsBuffer
{
    PointLight pointLights[2];
};


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
    float3 normal : NORMAL;
    float4 col : COLOR;
    float2 texCoord : TEXCOORD0;
    float3 tangent : TANGENT0;
    float3 binormal : BINORMAL0;
};


struct PS_IN
{
    float4 pos : SV_POSITION;
    float4 posInWorld  : WORLD_POS;
    float3 normal : NORMAL;   
    float2 texCoord : TEXCOORD0;
    float4 vertexColor : COLOR;
    float3 fragPosToCamPos : CAM_POS;
    float fogFragCoord : FALLO;
};


float mod(float a, float b)
{
    return a - b*floor(a/b);
}

float3 mod(float3 a, float b)
{
    return a - b*floor(a/b);
}



//>>>> VS2
PS_IN VS( VS_IN input )
{
    PS_IN output = (PS_IN)0;

    output.posInWorld = mul(input.pos, objectToWorldMatrix);
    output.pos = mul(output.posInWorld, worldToCameraMatrix);
    output.normal = mul(input.normal, (float3x3)objectToWorldMatrix);
    output.fogFragCoord = abs(output.pos.z / input.pos.w);
    output.pos = mul(output.pos, projMatrix);
    output.texCoord = mul(float4(input.texCoord, 0, 1), textureMatrix).xy;
    output.vertexColor = input.col;
    output.fragPosToCamPos = (mul(cameraToObjectMatrix[3], objectToWorldMatrix) - output.posInWorld);
      
    return output;
}
//<<< VS

float4 calcLightSource(float3 tbnTLightPosition, int lightIdx, float3 cameraVector, float3 norm, float4 baseColor)
{
    float3 lightVector = normalize(tbnTLightPosition);
    float nxDir = max(0.0, dot(norm, lightVector));
    float4 diffuse = pointLights[lightIdx].diffuse * nxDir;
    float specularPower = 0.0;
    if (nxDir > 0.0)
    {
//        float3 halfVector = normalize(lightVector + cameraVector);
//        float nxHalf = max(0.0, dot(norm, halfVector));
//        specularPower = pow(nxHalf, materialShininess);
        float3 r = reflect(-lightVector, norm);
        float rl = max(0.0, dot(r, cameraVector));
        specularPower = pow(rl, materialShininess);
    }

    float4 color = materialAmbient * pointLights[lightIdx].ambient +
                   materialDiffuse * (diffuse * baseColor) +
                   materialSpecular * pointLights[lightIdx].specular * specularPower;

    return color;
}



//>>>> PS
float4 PS( PS_IN input ) : SV_Target
{
    float3 fragPosToCamDir = normalize(input.fragPosToCamPos);
    
    float2 newTexCoords = input.texCoord;
    float3 norm = normalize(input.normal);
    float4 baseColor = input.vertexColor * txDiffuse.Sample(samLinear, newTexCoords);

    float4 color = calcLightSource(pointLights[0].position - input.posInWorld, 0, fragPosToCamDir, norm, baseColor);
    color += calcLightSource(pointLights[1].position - input.posInWorld, 1, fragPosToCamDir, norm, baseColor);    

    color += materialEmission*baseColor;

    float fog = (fogEnd - input.fogFragCoord) * fogScale;
    fog = clamp(fog, 0.0, 1.0);
    return float4(lerp(fogColor.rgb, color.rgb, fog), materialDiffuse.a * baseColor.a);
}
//<<< PS

technique10 Render
{
    pass P0
    {
        SetGeometryShader( 0 );
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetPixelShader( CompileShader( ps_4_0, PS() ) );
    }
} 

