using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MovingObject : MonoBehaviour
{    
    [Header("Movement Variables")]
    [SerializeField] private int movementSpeed = 10;
    [SerializeField] private int rotationSpeed = 5;
    [SerializeField] private bool isMoving = false;
    [SerializeField] public bool isPlayer = false;

    // Method to switch isMoving to the other state
    public void SwitchMovingController(bool b)
    {
        isMoving = b;
    }

    // Detect Movement and move
    public void DetectInput()
    {
        // Move if it is moving
        if (isMoving)
        {
            // Detect input
            float horizontalInput = Input.GetAxis("Horizontal");
            float verticalInput = Input.GetAxis("Vertical");
            float zAxisInput = Input.GetAxis("Z-axis");
            float mouseXInput = Input.GetAxis("Mouse X");
            float mouseYInput = Input.GetAxis("Mouse Y");

            // If we detect a motion input lets move
            if (horizontalInput != 0 || verticalInput != 0 || zAxisInput != 0)
            {
                // Get the new position
                Vector3 newPosition = transform.position  
                    + transform.forward * movementSpeed * Time.deltaTime * verticalInput
                    + - Vector3.Cross(transform.forward, transform.up) * movementSpeed * Time.deltaTime * horizontalInput
                    + transform.up * movementSpeed * Time.deltaTime * zAxisInput;

                // Move the object to the new position
                transform.position = newPosition;
            }

            // Detect mouse input only if it is a player
            if (isPlayer)
            {
                // If we detect mouse input rotate
                if (mouseXInput != 0 || mouseYInput != 0)
                {
                    transform.Rotate(-mouseYInput * rotationSpeed, mouseXInput * rotationSpeed, 0);
                    // Freeze the z-axis rotation
                    Vector3 currentAngles = transform.eulerAngles;
                    transform.eulerAngles = new Vector3(currentAngles.x, currentAngles.y, 0);
                }
            }
        }
    }

}
