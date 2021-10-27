using System.Collections;
using System.Collections.Generic;
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
        int p = 0;
        if (gameObject.name == "Obstacle (1)")
        {
            Debug.Log( meshComponent.vertexCount);
            foreach(int v in meshComponent.triangles)
            {
                p += 1;
                Debug.Log( p+ ": " + v);
            }
        }
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
            //UpdateAdjTrianglesBuffer();
        }
    }
    private void UpdateAdjTrianglesBuffer()
    {
        // First find and assign all adj triangle groups
        // first [] indicates the adj triangle group, second [] has the 6 different vertices 
        Vector4[][] adjTriangleFinderList = new Vector4[(meshComponent.triangles.Length / 3)][];
        
        int meshTrianglesIndex = 0;

        // First create the empty setup to iterate through later
        for (int i = 0; i < (meshComponent.triangles.Length / 3); i++)
        {
            adjTriangleFinderList[i] = new Vector4[6];
            for (int j = 0; j < 6; j++)
            {
                // 0, 2 and 4 are the central indices - the main triangle
               if (j % 2 == 0)
               {
                    adjTriangleFinderList[i][j] = meshComponent.vertices[meshComponent.triangles[meshTrianglesIndex]];
                    // Setting w to 1 marks it as a valid vertex
                    adjTriangleFinderList[i][j].w = 1;
                    meshTrianglesIndex++;
               }
               else
               {
                    adjTriangleFinderList[i][j] = new Vector4(-1,-1,-1,-1);
               } 
            }
        }

        // Now each vertex can find all places it can belong to
        for (int i = 0; i < (meshComponent.triangles.Length / 3); i++)
        {
            for (int j = 0; i < 6; j++)
            {
                // Only the adj triangles - 1, 3 and 5, and only if it isn't set yet
                if (j % 2 == 1)
                {
                   //adjTriangleFinderList[i][j] = new Vector4(-1,-1,-1,-1); 
                }   
            }
        }
/*
        // Create an array that then will sent the data to the buffer
        AdjTriangles[] adjTrianglesArray = new AdjTriangles[(meshComponent.triangles.Length / 3)];

        Debug.Log(adjTriangleFinderList.Length);
        Debug.Log((meshComponent.triangles.Length / 3));

        // Iterate through the array of arrays and assign all to the list
        for (int i = 0; i < (meshComponent.triangles.Length / 3); i++)
        {
            AdjTriangles newTri = new AdjTriangles()
            {
                vertex1 = adjTriangleFinderList[i][0],
                vertex2 = adjTriangleFinderList[i][1],
                vertex3 = adjTriangleFinderList[i][2],
                vertex4 = adjTriangleFinderList[i][3],
                vertex5 = adjTriangleFinderList[i][4],
                vertex6 = adjTriangleFinderList[i][5]
            };

            // Add the adj triangles to the array
            adjTrianglesArray[i] = newTri;
        }
        //Update the Buffer
        adjTrianglesBuffer.SetData(adjTrianglesArray);

        // Send the buffer to the material
        renderer.material.SetBuffer("adjTriangles", adjTrianglesBuffer);
*/
    }
    private void OnDisable()
    {
        adjTrianglesBuffer.Dispose();
    }
}
