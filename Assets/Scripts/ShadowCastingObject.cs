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
    // The initial bounds of the object
    private Bounds initialBounds;

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
        // Save the initial bounds
        initialBounds = meshComponent.bounds;
    }

    private void Update()
    {
        // Change the extents so it includes the shadow
        UpdateTheBounds();
    }
    private void OnRenderObject()
    {
        GL.Clear(true, false, Color.black);
    }

    // Update the bounds to include all the shadows
    private void UpdateTheBounds()
    {
        Bounds newBounds = initialBounds;

        // Get the light info from the light manager
        Vector3[] lightPositions = lightSources.GetLightSourcePositions();
        float[] radiuses = lightSources.GetRadiuses();
        int lightsAmount = lightSources.GetLightSourcePositions().Length;

        // Make sure there are lights
        if (lightsAmount <= 0)
        {
            return;
        }

        // Varaibles for the overall bounds
        Vector3 averagedCenter = new Vector3(0,0,0);
        Vector3 averagedWorldCenter = new Vector3(0,0,0);
        Vector3[] furtherestPoints = new Vector3[lightsAmount];

        // Loop throught all the lights
        for(int i = 0; i < lightsAmount; i++)
        {
            // Calculate how much to move the center of the bounds
            float toLightDistance = (lightPositions[i] - transform.position).magnitude;
            float displacement = (radiuses[i] - toLightDistance);
            Vector3 fromLightDirection = (transform.position - lightPositions[i]).normalized;
            Vector3 newWorldCenter = transform.position + (fromLightDirection * displacement / 2);
            // Add that to the averaged center
            averagedCenter += (newWorldCenter - transform.position);
            averagedWorldCenter += newWorldCenter;

            // Calculate the extends
            Vector3 furtherestPoint = transform.position + fromLightDirection * 
                (Mathf.Sqrt(Mathf.Pow(initialBounds.extents.x, 2) 
                + Mathf.Pow(initialBounds.extents.y, 2) 
                + Mathf.Pow(initialBounds.extents.z, 2)));
            furtherestPoint += (fromLightDirection * displacement);
            // Save the furtherest point
            furtherestPoints[i] = furtherestPoint;
        }

        // Find the new extends
        averagedWorldCenter = averagedWorldCenter / lightsAmount;
        Vector3 finalfurtherestPoint = new Vector3(0,0,0);
        for(int i = 0; i < lightsAmount; i++)
        {
            // X value check
            if ( finalfurtherestPoint.x < Mathf.Abs(furtherestPoints[i].x))
            {
                finalfurtherestPoint.x = Mathf.Abs(furtherestPoints[i].x);
            }
            // Y value check
            if ( finalfurtherestPoint.y < Mathf.Abs(furtherestPoints[i].y))
            {
                finalfurtherestPoint.y = Mathf.Abs(furtherestPoints[i].y);
            }
            // Z value check
            if ( finalfurtherestPoint.z < Mathf.Abs(furtherestPoints[i].z))
            {
                finalfurtherestPoint.z = Mathf.Abs(furtherestPoints[i].z);
            }
        }

        // Update the final values
        newBounds.center = averagedCenter / lightsAmount;
        Vector3 newExtents;
        newExtents.x = Mathf.Abs(finalfurtherestPoint.x - averagedWorldCenter.x);
        newExtents.y = Mathf.Abs(finalfurtherestPoint.y - averagedWorldCenter.y);
        newExtents.z = Mathf.Abs(finalfurtherestPoint.z - averagedWorldCenter.z);
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
