using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IndividualLightSource : MonoBehaviour
{
    // Light source radius
    [SerializeField] private float radius = 10; 
    // Check if the radius is changing
    private bool _isChangingRadius = false;
    // Previous position
    private float previousRadius = 10;
    // Detection of movement
    private bool _isMoving = false;
    // Previous position
    private Vector3 previousPosition = new Vector3(0,0,0);

    void Update()
    {
        // If position of the light changes
        _isMoving = previousPosition != transform.position;
        // Save the position
        previousPosition = transform.position;

        // If the radius of the light source changes
        _isChangingRadius = previousRadius != radius;
        previousRadius = radius; // save the radius
    }

    // Check if the object is moving
    public bool isMoving()
    {
        return _isMoving;
    }
    // Return radius of the light source
    public float GetRadius()
    {
        return radius;
    }
    // Return if the radius of the lightsource is changing
    public bool isRadiusChanging()
    {
        return _isChangingRadius;
    }
}
