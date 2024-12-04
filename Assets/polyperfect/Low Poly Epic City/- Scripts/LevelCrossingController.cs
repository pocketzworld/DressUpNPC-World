using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LevelCrossingController : MonoBehaviour
{
    public delegate void StateChange(bool crossing);
    public StateChange stateChange;
    [HideInInspector]
    public bool trainCrossing = false;
    private int numberOfWagons = 0;
    public List<LevelCrossing> levelCrossings = new List<LevelCrossing>();
    // Start is called before the first frame update
    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Train"))
        {
            numberOfWagons++;
            trainCrossing = true;
            if(numberOfWagons == 1)
            {
                foreach(LevelCrossing levelCrossing in levelCrossings)
                {
                    levelCrossing.meshRenderer.materials[2].SetColor("_EmissionColor", Color.red);
                    levelCrossing.ChangeBarrier(false);
                }
            }
        }
    }
    private void OnTriggerExit(Collider other)
    {
        if (other.CompareTag("Train"))
        {
            if (--numberOfWagons == 0)
            {
                trainCrossing = false;
                stateChange?.Invoke(false);
                foreach (LevelCrossing levelCrossing in levelCrossings)
                {
                    levelCrossing.meshRenderer.materials[2].SetColor("_EmissionColor", Color.black);
                    levelCrossing.ChangeBarrier(true);
                }
            }
        }
    }
}
