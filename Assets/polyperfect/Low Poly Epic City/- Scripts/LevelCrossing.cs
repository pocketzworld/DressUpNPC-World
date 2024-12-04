using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LevelCrossing : MonoBehaviour
{

    public GameObject Barrier;
    public MeshRenderer meshRenderer;
    public void ChangeBarrier(bool open)
    {
        StopAllCoroutines();
        if (open)
            StartCoroutine(OpenBarrier());
        else
            StartCoroutine(CloseBarrier());
    }
    private IEnumerator CloseBarrier()
    {
        while (Mathf.FloorToInt(Barrier.transform.localRotation.eulerAngles.z) != 0)
        {
            Barrier.transform.localRotation = Quaternion.RotateTowards(Barrier.transform.localRotation, Quaternion.Euler(0,0,0),1f);
            yield return null;
        }
        yield break;
    }
    private IEnumerator OpenBarrier()
    {
        while (Mathf.FloorToInt(Barrier.transform.localRotation.eulerAngles.z) != 270)
        {
            Barrier.transform.localRotation = Quaternion.RotateTowards(Barrier.transform.localRotation, Quaternion.Euler(0, 0, -90), 1f);
            yield return null;
        }
        yield break;
    }
}
