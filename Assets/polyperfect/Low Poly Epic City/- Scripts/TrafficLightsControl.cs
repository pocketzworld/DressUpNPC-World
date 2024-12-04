using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TrafficLightsControl : MonoBehaviour
{
    public TrafficLight[] firstLights;
    public TrafficLight[] secondLights;
    public float timeInterval = 10;

    private bool firstOn = false;
    void Start()
    {
        //Toggle light every timeInterval seconds
        InvokeRepeating("ToggleLights", 0, timeInterval);
    }

    private void ToggleLights()
    {
        //Changes collors
        Color firstColor;
        Color secondColor;
        if (firstOn)
        {
            firstColor = Color.red;
            secondColor = Color.green;
            firstOn = false;
        } else
        {
            firstColor = Color.green;
            secondColor = Color.red;
            firstOn = true;
        }



        foreach (TrafficLight light in firstLights)
        {
            light.GetComponent<Renderer>().materials[1].SetColor("_EmissionColor", firstColor);
            light.isGreen = firstOn;
            light.lightChange?.Invoke(light.isGreen);
        }

        foreach (TrafficLight light in secondLights)
        {
            light.GetComponent<Renderer>().materials[1].SetColor("_EmissionColor", secondColor);
            light.isGreen = !firstOn;
            light.lightChange?.Invoke(light.isGreen);
        }

        
    }
}
