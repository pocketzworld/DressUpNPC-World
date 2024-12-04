using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Trajectory : MonoBehaviour
{
    // Start is called before the first frame update
    public List<Vector3> points = new List<Vector3>();

    void Awake()
    {

        foreach (Transform child in transform)
        {
            points.Add(child.position);

        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
    void OnDrawGizmosSelected()
    {
        int i = 0;
       
        foreach (Transform child in transform)
        {   
            if( i < transform.childCount-1) {
                Gizmos.color = Color.red;
                Gizmos.DrawLine(child.position, transform.GetChild(i + 1).position );

                Gizmos.color = Color.yellow;
                Gizmos.DrawCube(child.position, new Vector3(1, 1, 1));
            }
            i++;
        }
    }
}
