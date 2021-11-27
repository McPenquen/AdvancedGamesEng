using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MovementManager : MonoBehaviour
{
    [SerializeField] private MovingObject[] movingObjects;
    [SerializeField] private MovementIndicatorBox[] uiMovementIndicators;
    private int currentMovingObject = 0; // 0 is always player

    private void Start()
    {
        // Initiate the 0 box as the active one
        uiMovementIndicators[currentMovingObject].ChangeActiveStatus(true);
        movingObjects[currentMovingObject].SwitchMovingController();
    }
    void Update()
    {
        // Key P will switch between the objects
        if (Input.GetKeyDown(KeyCode.P))
        {
            // Update the id to the next index
            int newId = (currentMovingObject + 1) % movingObjects.Length;

            // Change the boxes look
            uiMovementIndicators[currentMovingObject].ChangeActiveStatus(false);
            uiMovementIndicators[newId].ChangeActiveStatus(true);

            // Switch the moving to true for the object
            movingObjects[currentMovingObject].SwitchMovingController();
            movingObjects[newId].SwitchMovingController();

            currentMovingObject = newId;
        }
        // Move the object by the input keys input
        movingObjects[currentMovingObject].DetectInput();
    }
}
