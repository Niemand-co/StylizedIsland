using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

[ExecuteInEditMode]
public class DeferedPipeline : RenderPipeline
{
    protected override async void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        Camera camera = cameras[0];
        context.SetupCameraProperties(camera);

        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "Init";

        PrePass(context, camera);

        cmd.SetRenderTarget(gbufferID, gdepth);
        cmd.SetGlobalTexture("_gdepth", gdepth);
        for(int i = 0; i < 4; ++i)
            cmd.SetGlobalTexture("_GT" + i, gbuffers[i]);

        cmd.ClearRenderTarget(true, true, Color.black);
        context.ExecuteCommandBuffer(cmd);
        
        context.DrawSkybox(camera);
        context.Submit();
        cmd.Release();

        BasePass(context, camera);
        LightPass(context, camera);
        TranslucentPass(context, camera);

        context.Submit();
    }

    void PrePass(ScriptableRenderContext context, Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "PrePass";
        cmd.SetRenderTarget(PreDepth, gdepth);
        cmd.ClearRenderTarget(true, true, Color.black);
        cmd.SetGlobalTexture("DepthTexture", PreDepth);
        context.ExecuteCommandBuffer(cmd);

        camera.TryGetCullingParameters(out var cullingParameters);
        var cullingResults = context.Cull(ref cullingParameters);

        ShaderTagId shaderTagId = new ShaderTagId("PrePass");
        SortingSettings srt = new SortingSettings(camera);
        DrawingSettings drs = new DrawingSettings(shaderTagId, srt);
        FilteringSettings fils = FilteringSettings.defaultValue;

        context.DrawRenderers(cullingResults, ref drs, ref fils);
    }

    async void BasePass(ScriptableRenderContext context, Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "BasePass";
        context.ExecuteCommandBuffer(cmd);

        camera.TryGetCullingParameters(out var cullingParameters);
        var cullingResults = context.Cull(ref cullingParameters);

        ShaderTagId shaderTagId = new ShaderTagId("BasePass");
        SortingSettings srt = new SortingSettings(camera);
        DrawingSettings drs = new DrawingSettings(shaderTagId, srt);
        FilteringSettings fils = FilteringSettings.defaultValue;

        context.DrawRenderers(cullingResults, ref drs, ref fils);
    }

    void LightPass(ScriptableRenderContext context, Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "LightPass";
        
        Material mat = new Material(Shader.Find("Demo/LightPass"));
        cmd.Blit(gbufferID[0], BuiltinRenderTextureType.CameraTarget, mat);
        context.ExecuteCommandBuffer(cmd);
    }

    void TranslucentPass(ScriptableRenderContext context, Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "TranslucentPass";
        context.ExecuteCommandBuffer(cmd);

        camera.TryGetCullingParameters(out var cullingParameters);
        var cullingResults = context.Cull(ref cullingParameters);

        ShaderTagId shaderTagId = new ShaderTagId("Translucent");
        SortingSettings srt = new SortingSettings(camera);
        DrawingSettings drs = new DrawingSettings(shaderTagId, srt);
        FilteringSettings fils = FilteringSettings.defaultValue;

        context.DrawRenderers(cullingResults, ref drs, ref fils);
    }

    public DeferedPipeline()
    {
        gdepth  = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.Depth, RenderTextureReadWrite.Linear);
        PreDepth = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        
        gbuffers[0] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        gbuffers[1] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB2101010, RenderTextureReadWrite.Linear);
        gbuffers[2] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
        gbuffers[3] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);

        for(int i = 0; i < 4; ++i)
            gbufferID[i] = gbuffers[i];
    }


    RenderTexture gdepth;
    RenderTexture PreDepth;
    RenderTexture[] gbuffers = new RenderTexture[4];
    RenderTargetIdentifier[] gbufferID = new RenderTargetIdentifier[4];

}
