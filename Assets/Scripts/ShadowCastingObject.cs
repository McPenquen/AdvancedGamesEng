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
    // Compute buffer with the adj triangles data
    private ComputeBuffer adjTrianglesBuffer;
    // The mesh
    private Mesh meshComponent = null;
    // Light Source
    [SerializeField] private CustomLightingManager lightSources = null;

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
        // Save the number of triangles
        renderer.material.SetInt("_MeshTrianglesNumber", (meshComponent.triangles.Length / 3));
    }

    private void Update()
    {
        // Change the extents so it includes the shadow
        UpdateTheBounds();
    }

    // Update the bounds to include the shadow
    private void UpdateTheBounds()
    {
        Bounds newBounds = meshComponent.bounds;

        float radius0 = lightSources.GetRadiuses()[0];
        Vector3 position0 = lightSources.GetLightSourcePositions()[0];

        // Calculate how much to move the center of the bounds
        float toLightDistance = (position0 - transform.position).magnitude;
        float displacement = (radius0 - toLightDistance);
        Vector3 fromLightDirection = (transform.position - position0).normalized;
        Vector3 newWorldCenter = transform.position + (fromLightDirection * displacement / 2);

        // Calculate the extends
        Vector3 furtherestPoint = transform.position + fromLightDirection * 
            (Mathf.Sqrt(Mathf.Pow(meshComponent.bounds.extents.x, 2) 
            + Mathf.Pow(meshComponent.bounds.extents.y, 2) 
            + Mathf.Pow(meshComponent.bounds.extents.z, 2)));
        furtherestPoint += (fromLightDirection * displacement);
        Vector3 newExtents;
        newExtents.x = Mathf.Abs(furtherestPoint.x - newWorldCenter.x);
        newExtents.y = Mathf.Abs(furtherestPoint.y - newWorldCenter.y);
        newExtents.z = Mathf.Abs(furtherestPoint.z - newWorldCenter.z);
        newBounds.extents = newExtents;

        meshComponent.bounds = newBounds;
    }

    // Update the buffer of adj triangles for tha geometry shader
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

        // Now each triangle will try to fill its adj vertices
        for (int m = 0; m < adjTriangleFinderList.Length; m++)
        {
            int[] emptyAdjVertices = {0,0,0};
            int idCounter = 0;
            // Count how many vertices to find a match to
            for (int o = 1; o < adjTriangleFinderList[m].Length; o=o+2)
            {
                if (adjTriangleFinderList[m][o].w == -1)
                {
                    emptyAdjVertices[idCounter] = o;
                }
                idCounter++;
            }
            for (int n = 0; n < adjTriangleFinderList.Length; n++)
            {
                // If all vertices are set continue to the next triangle
                if (emptyAdjVertices[0] == 0 && emptyAdjVertices[1] == 0 && emptyAdjVertices[2] == 0)
                {
                    continue;
                }
                // Skip if it is the same triangle
                if (m != n)
                {
                    // Attempt to find 2 of the same vertices
                    for (int p = 1; p < adjTriangleFinderList[n].Length; p=p+2)
                    {
                        int frstIndex = p-1; 
                        int scndIndex = (p+1) % 6; // indx of 6 is = 0
                        Vector4 v1 = adjTriangleFinderList[n][frstIndex];
                        Vector4 v2 = adjTriangleFinderList[n][scndIndex];
                        for (int q = 0; q < emptyAdjVertices.Length; q++)
                        {
                            // Skip 0s
                            if (emptyAdjVertices[q] == 0) { continue; }

                            int i0 = emptyAdjVertices[q]-1;
                            int i1 = (emptyAdjVertices[q]+1) % 6;
                            // If two of the vertices are the same for both triangle we have a match
                            if ((adjTriangleFinderList[m][i0] == v1 && adjTriangleFinderList[m][i1] == v2) || 
                                (adjTriangleFinderList[m][i0] == v2 && adjTriangleFinderList[m][i1] == v1) // Just to be sure check them interchangeably 
                            )
                            {
                                // The unused vertex from the other 6vertices belongs to the empty spot
                                int mIndex = (i1 + 2) % 6;
                                int nIndex = (scndIndex + 2) % 6;
                                adjTriangleFinderList[m][emptyAdjVertices[q]] = adjTriangleFinderList[n][nIndex];
                                adjTriangleFinderList[n][p] = adjTriangleFinderList[m][mIndex];
                                emptyAdjVertices[q] = 0;
                            }
                        }

                    }
                }
            }
        }

        // Create an array that then will sent the data to the buffer
        AdjTriangles[] adjTrianglesArray = new AdjTriangles[(meshComponent.triangles.Length / 3)];

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

    }
    private void OnDisable()
    {
        adjTrianglesBuffer.Dispose();
    }
}
