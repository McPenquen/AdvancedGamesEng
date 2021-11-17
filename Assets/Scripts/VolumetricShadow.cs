using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VolumetricShadow : MonoBehaviour
{
    // The owner of the shadow
    [SerializeField] private GameObject shadowParent = null;
    // The mesh
    private Mesh meshComponent = null;
    // Light Source
    [SerializeField] private CustomLightingManager lightSources = null;
    void Start()
    {
        MeshFilter meshfilter = gameObject.GetComponent<MeshFilter>();
        meshfilter.mesh = shadowParent.GetComponent<MeshFilter>().mesh;
        meshComponent = shadowParent.GetComponent<MeshFilter>().mesh;
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
}
