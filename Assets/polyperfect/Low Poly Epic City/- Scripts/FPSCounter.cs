using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class FPSCounter : MonoBehaviour
{
    public Text fpsText;
    int fpsCount;
    // Update is called once per frame
    private void Start()
    {
        InvokeRepeating("CountFPS", 0f, 1f);
    }
    void CountFPS()
    {
        fpsText.text = (Time.frameCount - fpsCount).ToString();
        fpsCount = Time.frameCount;
    }
}
