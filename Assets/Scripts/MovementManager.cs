using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MovementManager : MonoBehaviour
{
    [SerializeField] private MovingObject[] movingObjects;
    [SerializeField] private MovementIndicatorBox[] uiMovementIndicators;
    [SerializeField] private int currentMovingObject = 0; // 0 is always player
    // Bool if the scene is starting
    static private bool isStarting = true;
    // Counter for the starting of the scene
    private float startingCounter = 0;

    void Update()
    {
        // Check if this is the first time this is run after a scene switch
        if (isStarting)
        {
            // The loading needs some time, bug
            startingCounter += Time.deltaTime;
            if (startingCounter > 1)
            {
                startingCounter = 0;
                isStarting = false;
                // Initiate the 0 box as the active one
                currentMovingObject = 0;
                uiMovementIndicators[currentMovingObject].ChangeActiveStatus(true);
                movingObjects[currentMovingObject].SwitchMovingController(true);
            }
        }

        // Key P will switch between the objects
        if (Input.GetKeyDown(KeyCode.P) && startingCounter == 0.0f)
        {
            // Update the id to the next index
            int newId = (currentMovingObject + 1) % movingObjects.Length;

            // Change the boxes look
            uiMovementIndicators[currentMovingObject].ChangeActiveStatus(false);
            uiMovementIndicators[newId].ChangeActiveStatus(true);

            // Switch the moving to true for the object
            movingObjects[currentMovingObject].SwitchMovingController(false);
            movingObjects[newId].SwitchMovingController(true);

            currentMovingObject = newId;
        }
        // Move the object by the input keys input
        movingObjects[currentMovingObject].DetectInput();
    }

    // Method to set isStarting
    static public void SetIsStarting(bool b)
    {
        isStarting = b;
    }
}
