using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomLightSource : MonoBehaviour
{
    // All objects on the scene
    [SerializeField] GameObject[] objects = null;
    // Detection of movement
    private bool isMoving = false;
    // Previous position
    private Vector3 previousPosition = new Vector3(0,0,0);

    void Update()
    {
        // If position of the light changes
        isMoving = previousPosition != transform.position;
        // Save the position
        previousPosition = transform.position;
        
        // If the light source has moved update the shadows
        if (isMoving) {
            Vector4 vec4 = new Vector4(transform.position.x, transform.position.y, transform.position.z, 0);
            foreach (GameObject o in objects)
            {
                // Update the shaders for the objects
                Renderer r = o.GetComponent<Renderer>();
                r.material.SetVector("_LightSourcePosition", vec4);
            }
        }
    }
}