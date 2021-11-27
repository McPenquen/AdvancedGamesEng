using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class MovementIndicatorBox : MonoBehaviour
{
    [SerializeField] private Image imgComponent = null;
    [SerializeField] private TMP_Text textComponent = null;
    private void Start()
    {
        // Save the components
        imgComponent = GetComponent<Image>();
        textComponent = transform.GetChild(0).GetComponent<TMP_Text>();
    }
    public void ChangeActiveStatus(bool b)
    {
        if (b) // this is the active moving box
        {
            imgComponent.fillCenter = false;
            textComponent.color = Color.white;
        }
        else // this is not a moving box
        {
            imgComponent.fillCenter = true;
            textComponent.color = Color.black;
        }
    }
}
