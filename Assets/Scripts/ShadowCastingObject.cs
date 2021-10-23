using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShadowCastingObject : MonoBehaviour
{
    private Renderer renderer = null;
    private bool isMoving = false;
    // Previous position
    private Vector3 previousPosition = new Vector3(0,0,0);
    void Start()
    {
        renderer = GetComponent<Renderer>();
        // Save the central location of the object
        Vector4 center = transform.position;
        // Update the shaders for the objects
        renderer.material.SetVector("_ObjectCenter", center);
    }

    void Update()
    {
        // If position of the light changes
        isMoving = previousPosition != transform.position;
        // Save the position
        previousPosition = transform.position;
        // If the object has moved update the shader's information
        if (isMoving)
        {
            Vector4 center = transform.position;
            // Update the shaders for the objects
            renderer.material.SetVector("_ObjectCenter", center);
        }
    }
}
