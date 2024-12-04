using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Crosswalk : MonoBehaviour
{
    public delegate void StateChange(bool crossing);
    public StateChange stateChange;
    public bool PedestriansAreCrossing = false;
    private int numberOfPedestians = 0;
    public bool CanCross = true;
    // Start is called before the first frame update
    private void OnTriggerEnter(Collider other)
    {
        if(other.CompareTag("Human"))
        {
            numberOfPedestians++;
            PedestriansAreCrossing = true;
        }
    }
    private void OnTriggerExit(Collider other)
    {
        if (other.CompareTag("Human"))
        {
            if (--numberOfPedestians == 0)
            {
                PedestriansAreCrossing = false;
                if(stateChange != null)
                    stateChange.Invoke(false);
            }
        }
    }
}
