using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class InputMovement : MonoBehaviour
{
    [Header("Movement Variables")]

    [SerializeField] private int movementSpeed = 10;
    [SerializeField] private int rotationSpeed = 5;
    void Update()
    {
        // Detect input
        float horizontalInput = Input.GetAxis("Horizontal");
        float verticalInput = Input.GetAxis("Vertical");
        float mouseXInput = Input.GetAxis("Mouse X");
        float mouseYInput = Input.GetAxis("Mouse Y");

        // If we detect a motion input lets move
        if (horizontalInput != 0 || verticalInput != 0)
        {
            // Get the new position
            Vector3 newPosition = transform.position  
                + transform.forward * movementSpeed * Time.deltaTime * verticalInput
                + - Vector3.Cross(transform.forward, transform.up) * movementSpeed * Time.deltaTime * horizontalInput;

            // Move the object to the new position
            transform.position = newPosition;
        }

        // If we detect mouse input rotate
        if (mouseXInput != 0 || mouseYInput != 0)
        {
            transform.Rotate(-mouseYInput * rotationSpeed, mouseXInput * rotationSpeed, 0);
            Vector3 currentAngles = transform.eulerAngles;
            transform.eulerAngles = new Vector3(currentAngles.x, currentAngles.y, 0);
        }

    }
}
