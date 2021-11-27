using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MovementManager : MonoBehaviour
{
    [SerializeField] private MovingObject[] movingObjects;
    [SerializeField] private GameObject[] uiMovementIndicators;
    private int currentMovingObject = 0; // 0 is always player

    void Update()
    {
        // Key P will switch between the objects
        if (Input.GetKeyDown(KeyCode.P))
        {
            // Update the id to the next index
            int newId = (currentMovingObject + 1) % movingObjects.Length;

            

            currentMovingObject = newId;

        }
        // Move the object by the input keys input
        movingObjects[currentMovingObject].DetectInput();
    }
}
