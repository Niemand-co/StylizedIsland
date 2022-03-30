using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SkyChanging : MonoBehaviour
{
    
    void Start()
    {
        
    }

    
    async void Update()
    {
        transform.Rotate(rotateSpeed, 0.0f, 0.0f, Space.Self);
    }

    public float rotateSpeed = 0.1f;


}
