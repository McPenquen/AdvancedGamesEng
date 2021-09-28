using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class InputMovement : MonoBehaviour
{
    [Header("Movement Variables")]

    [SerializeField] private int speed = 10;

    void Update()
    {
        // Detect input
        float horizontalInput = Input.GetAxis("Horizontal");
        float verticalInput = Input.GetAxis("Vertical");

        // If we detect an input lets move
        if (horizontalInput != 0 || verticalInput != 0)
        {
            // Get the new position
            Vector3 newPosition = transform.position  
                + transform.forward * speed * Time.deltaTime * verticalInput
                + - Vector3.Cross(transform.forward, transform.up) * speed * Time.deltaTime * horizontalInput;

            // Move the object to the new position
            transform.position = newPosition;
        }
    }
}
