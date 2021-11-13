using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomLightingManager : MonoBehaviour
{
    // All objects on the scene
    [SerializeField] GameObject[] objects = null;
    // Light sources
    [SerializeField] IndividualLightSource[] lightSources = null;
    // Radiuses of the lightsource
    private float[] _radiuses = {0,0};
    // Radiuses of the lightsource
    private Vector3[] _lsPositions = {new Vector3(0,0,0), new Vector3(0,0,0)};

    void Start()
    {
        // Save the radius for each light source
        for (int i = 0; i < lightSources.Length; i++)
        {
            _radiuses[i] = lightSources[i].GetRadius();
            _lsPositions[i] = lightSources[i].transform.position;
            // Update the initial values
            foreach (GameObject o in objects)
            {
                Vector4 vec4 = new Vector4(_lsPositions[i].x, _lsPositions[i].y, _lsPositions[i].z, 0);
                // Update the shaders for the objects
                Renderer r = o.GetComponent<Renderer>();
                if (i == 0)
                {
                    r.material.SetVector("_LightSourcePosition1", vec4); 
                     r.material.SetFloat("_LightSourceRadius1", _radiuses[0]);  
                }
                
            }
        }
    }

    void Update()
    {
        Debug.Log("Radius: " + _radiuses[0]);
        Debug.Log("Position: " + _lsPositions[0]);
        // Iterate through all light sources
        for (int i = 0; i < lightSources.Length; i++)
        {
            // If the light source has moved update the shadows
            if (lightSources[i].isMoving()) {
                _lsPositions[i] = lightSources[i].transform.position;
                Vector4 vec4 = new Vector4(_lsPositions[i].x, _lsPositions[i].y, _lsPositions[i].z, 0);
                foreach (GameObject o in objects)
                {
                    // Update the shaders for the objects
                    Renderer r = o.GetComponent<Renderer>();
                    if (i == 0)
                    {
                      r.material.SetVector("_LightSourcePosition1", vec4);  
                    }
                    
                }
            }
            // Update the light source's power and radius
            if (lightSources[i].isRadiusChanging())
            {
                float newR = lightSources[i].GetRadius();
                _radiuses[i] = newR;
                foreach (GameObject o in objects)
                {
                    // Update the shaders for the objects
                    Renderer r = o.GetComponent<Renderer>();
                    if (i == 0)
                    {
                       r.material.SetFloat("_LightSourceRadius1", newR); 
                    }
                    
                }
            }
        }

    }

    // Return radii for all light sources
    public float[] GetRadiuses()
    {
        return _radiuses;
    }
    // Return positions for all light sources
    public Vector3[] GetLightSourcePositions()
    {
        return _lsPositions;
    }
}
