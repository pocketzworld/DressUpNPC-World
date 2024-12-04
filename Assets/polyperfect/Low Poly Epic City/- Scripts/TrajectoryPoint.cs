using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TrajectoryPoint : MonoBehaviour
{
    void OnDrawGizmosSelected()
    {
        this.transform.parent.SendMessage("OnDrawGizmosSelected");
    }
}
