using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Reflection : MonoBehaviour
{
    private Camera m_mainCamera = null;
    private Camera m_reflectionCamera = null;
    public GameObject m_reflectionPlane = null;
    public Material m_reflectionPlaneMat = null;
    RenderTexture m_reflectionBuffer = null;

    void Start()
    {
        GameObject reflectionCameraGo = new GameObject("ReflectionCamera");
        m_reflectionCamera = reflectionCameraGo.AddComponent<Camera>();
        m_reflectionCamera.enabled = false;

        m_mainCamera = GetComponent<Camera>();
        m_reflectionBuffer = new RenderTexture(Screen.width, Screen.height, 24);
    }

    void Update()
    {
        
    }

    private void OnPostRender()
    {
        RenderReflection();
    }

    void RenderReflection()
    {
        m_reflectionCamera.CopyFrom(m_mainCamera);
        
        Vector3 worldSpaceCameraDir = m_mainCamera.transform.forward;
        Vector3 worldSpaceCameraUp = m_mainCamera.transform.up;
        Vector3 worldSpaceCameraPos = m_mainCamera.transform.position;

        Vector3 planeSpaceCameraDir = m_reflectionPlane.transform.InverseTransformDirection(worldSpaceCameraDir);
        Vector3 planeSpaceCameraUp = m_reflectionPlane.transform.InverseTransformDirection(worldSpaceCameraUp);
        Vector3 planeSpaceCameraPos = m_reflectionPlane.transform.InverseTransformPoint(worldSpaceCameraPos);

        planeSpaceCameraDir.y *= -1.0f;
        planeSpaceCameraUp.y *= -1.0f;
        planeSpaceCameraPos.y *= -1.0f;

        worldSpaceCameraDir = m_reflectionPlane.transform.TransformDirection(planeSpaceCameraDir);
        worldSpaceCameraUp = m_reflectionPlane.transform.TransformDirection(planeSpaceCameraUp);
        worldSpaceCameraPos = m_reflectionPlane.transform.TransformPoint(planeSpaceCameraPos);
        
        m_reflectionCamera.transform.position = worldSpaceCameraPos;
        m_reflectionCamera.transform.LookAt(worldSpaceCameraPos + worldSpaceCameraDir, worldSpaceCameraUp);

        m_reflectionCamera.targetTexture = m_reflectionBuffer;
        m_reflectionCamera.Render();
        m_reflectionPlaneMat.SetTexture("_ReflectionTex", m_reflectionBuffer);
    }
}