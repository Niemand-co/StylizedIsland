using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Cloud : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        cloudMat.SetFloat("_Thickness", Thickness);
        cloudMat.SetFloat("_MidHeight", transform.position.y);

        offset = Thickness / horizontalStackSize / 2.0f;
        Vector3 startPosition = transform.position + (Vector3.up * (offset * horizontalStackSize / 2.0f));
        
        if(useGPUInstancing)
        {
            matrices = new Matrix4x4[horizontalStackSize];
        }

        for(int i = 0; i < horizontalStackSize; ++i)
        {
            matrix = Matrix4x4.TRS(startPosition - (Vector3.up * offset * i), transform.rotation, transform.localScale);

            if(useGPUInstancing)
            {
                matrices[i] = matrix;
            }
            else
            {
                Graphics.DrawMesh(quadMesh, matrix, cloudMat, cloudLayer, camera, 0, null, castShadows, false, false);
            }
        }

        if(useGPUInstancing)
        {
            UnityEngine.Rendering.ShadowCastingMode shadowCasting = UnityEngine.Rendering.ShadowCastingMode.Off;
            if(castShadows)
                shadowCasting = UnityEngine.Rendering.ShadowCastingMode.On;
            Graphics.DrawMeshInstanced(quadMesh, 0, cloudMat, matrices, horizontalStackSize, null, shadowCasting, false, cloudLayer, camera);
        }
    }

    public int horizontalStackSize = 20;

    public Material cloudMat;
    public int cloudLayer;
    public float Thickness = 1f;
    public Mesh quadMesh;
    float offset;
    public Camera camera;
    private Matrix4x4 matrix;
    private Matrix4x4[] matrices;
    public bool castShadows = true;
    public bool useGPUInstancing = false;
}
