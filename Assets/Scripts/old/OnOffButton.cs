using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

public class OnOffButton : MonoBehaviour
{
    [SerializeField] private bool isOn = false;
    private Button buttonComponent = null;
    private EventSystem eventSystem = null;

    [SerializeField] private InputMovement inputMovementObject = null;

    // Variables to enable single click with a count down
    private bool isClickBlocked = false;
    private float clickCountdown = 0.0f;

    void Start()
    {
        // Save the reference to the button component
        buttonComponent = GetComponent<Button>();
        // Event system ref saved
        eventSystem = EventSystem.current.GetComponent<EventSystem>();
        // The Input movement object save
        inputMovementObject = GameObject.Find("Player").GetComponent<InputMovement>();
    }

    void Update()
    {
        buttonComponent.onClick.AddListener(OnOffClick);

        // If the click is blocked countdown 1s 
        if (isClickBlocked)
        {
            clickCountdown += Time.deltaTime;
            if (clickCountdown >= 1.0f)
            {
                // Reset the values
                isClickBlocked = false;
                clickCountdown = 0.0f;
            }
        }
        
        // We can click by press of Q
        if (!isClickBlocked && Input.GetKeyDown(KeyCode.Q))
        {
            OnOffClick();
        }

    }

    // Method changing state of the button
    private void OnOffClick()
    {
        // Click only if it is allowed now
        if (!isClickBlocked)
        {
            // Block clicking for now
            isClickBlocked = true;

            // Switch the on/off state
            isOn = !isOn;
            inputMovementObject.SwitchMovingController();

            // If the new state is Off (!isOn) unselect the button
            if (!isOn)
            {
                eventSystem.SetSelectedGameObject(null);
            }
            else
            {
                eventSystem.SetSelectedGameObject(gameObject);
            }
        }
    }
}
