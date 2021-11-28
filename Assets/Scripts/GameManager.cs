using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class GameManager : MonoBehaviour
{
    // Null instance of the manager
    public static GameManager instance = null;

    private void Awake()
    {
        // SINGLETON
        // Check if instance is null
        if (instance == null)
        {
            //Don't destroy the current game manager
            DontDestroyOnLoad(gameObject);

            //Set game manager instance to this
            instance = this;
        }
        // Check if current instance of game manager is equal to this game manager
        else if (instance != this)
        {
            //Destroy the game manager that is not the current game manager
            Destroy(gameObject);
        }
    }
    void Update()
    {
        // ESC press quits the game
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            Application.Quit();
        }
        // Else navigate between scenes by numbers 1-5 -> scene switch, tell the movement manager about scene switching
        else if (Input.GetKeyDown(KeyCode.Keypad1) || Input.GetKeyDown(KeyCode.Alpha1))
        {
            SceneManager.LoadScene("DevelopmentScene");
            MovementManager.SetIsStarting(true);
        }
        else if (Input.GetKeyDown(KeyCode.Keypad2) || Input.GetKeyDown(KeyCode.Alpha2))
        {
            SceneManager.LoadScene("MultipleLightSourcesScene");
            MovementManager.SetIsStarting(true);
        }
        else if (Input.GetKeyDown(KeyCode.Keypad3) || Input.GetKeyDown(KeyCode.Alpha3))
        {
            SceneManager.LoadScene("ComplexObjectsScene");
            MovementManager.SetIsStarting(true);
        }
        else if (Input.GetKeyDown(KeyCode.Keypad4) || Input.GetKeyDown(KeyCode.Alpha4))
        {
            SceneManager.LoadScene("GlassObjectsScene");
            MovementManager.SetIsStarting(true);
        }
        else if (Input.GetKeyDown(KeyCode.Keypad5) || Input.GetKeyDown(KeyCode.Alpha5))
        {
            SceneManager.LoadScene("ColouredGlassScene");
            MovementManager.SetIsStarting(true);
        }
    }
}
