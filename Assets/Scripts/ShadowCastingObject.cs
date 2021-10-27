using System.Collections;
using System.Collections.Generic;
using System;
using UnityEngine;

// Struct with the Adj Triangles for shader
public struct AdjTriangles
{
    public Vector4 vertex1;
    public Vector4 vertex2;
    public Vector4 vertex3;
    public Vector4 vertex4;
    public Vector4 vertex5;
    public Vector4 vertex6;
    public static int GetSize()
    {
        return sizeof(float) * 4 * 6;
    }
};

// Class for the shadow casting object
public class ShadowCastingObject : MonoBehaviour
{
    private Renderer renderer = null;
    private bool isMoving = false;
    // Previous position
    private Vector3 previousPosition = new Vector3(0,0,0);
    // Compute buffer with the adj triangles data
    private ComputeBuffer adjTrianglesBuffer;
    // The mesh
    private Mesh meshComponent = null;

    void Start()
    {
        // Get needed components
        renderer = GetComponent<Renderer>();
        meshComponent = GetComponent<MeshFilter>().mesh;
        // Set the buffer for adj triangles
        adjTrianglesBuffer = new ComputeBuffer(
            (meshComponent.triangles.Length / 3) * 6, AdjTriangles.GetSize()
            );
        UpdateAdjTrianglesBuffer();
    }

    void Update()
    {
        // If position of the light changes
        isMoving = previousPosition != transform.position;
        // Save the position
        previousPosition = transform.position;
        // If the object has moved update the buffer for the shader
        if (isMoving)
        {
            UpdateAdjTrianglesBuffer();
        }
    }
    private void UpdateAdjTrianglesBuffer()
    {
        // Create an array that then will sent the data to the buffer
        AdjTriangles[] adjTrianglesArray = new AdjTriangles[(meshComponent.triangles.Length / 3)];

        // For each triangle in the mesh update the buffer info element
        for (int i = 0; i < (meshComponent.triangles.Length / 3); i++)
        {
            AdjTriangles newTri = new AdjTriangles()
            {
                vertex1 = new Vector4(0,0,0,0),
                vertex2 = new Vector4(0,0,0,0),
                vertex3 = new Vector4(0,0,0,0),
                vertex4 = new Vector4(0,0,0,0),
                vertex5 = new Vector4(0,0,0,0),
                vertex6 = new Vector4(0,0,0,0),
            };

            // Add the adj triangles to the array
            adjTrianglesArray[i] = newTri;
        }
        //Update the Buffer
        adjTrianglesBuffer.SetData(adjTrianglesArray);

        // Send the buffer to the material
        renderer.material.SetBuffer("adjTriangles", adjTrianglesBuffer);
    }
    private void OnDisable()
    {
        adjTrianglesBuffer.Dispose();
    }
}
