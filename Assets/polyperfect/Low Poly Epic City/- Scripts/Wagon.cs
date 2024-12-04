using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.SocialPlatforms.Impl;

namespace PolyPerfect.City
{
    public class Wagon : MonoBehaviour
    {
        public BoxCollider Collider;
        public Transform frontBogie;
        private int frontBogieCheckpoint = 1;
        private int frontBogiePath = 0;
        public Transform rearBogie;
        [HideInInspector]
        public float currentMaxSpeed = 0;
        private int rearBogieCheckpoint = 1;
        private int rearBogiePath = 0;
        private float ratio;

        private List<Path> trajectory;
        private Vector3 targetFrontPoint;
        private Vector3 targetRearPoint;

        private void Awake()
        {
            if(Collider == null)
                Collider = GetComponent<BoxCollider>();
            ratio = frontBogie.localPosition.z / Vector3.Distance(frontBogie.localPosition, rearBogie.localPosition);
        }

        public void SetWagon(List<Path> trainTrajectory)
        {
            trajectory = trainTrajectory;
            targetFrontPoint = trajectory[0].pathPositions[1].transform.position;
            targetRearPoint = trajectory[0].pathPositions[1].transform.position;
            frontBogieCheckpoint = 1;
            frontBogiePath = 0;
            rearBogieCheckpoint = 1;
            rearBogiePath = 0;
            currentMaxSpeed = trajectory[frontBogiePath].speed;
        }

        public void UpdateWagon(float speed)
        {
            UpdateCheckpoint(ref frontBogiePath, ref frontBogieCheckpoint, true);
            UpdateCheckpoint(ref rearBogiePath, ref rearBogieCheckpoint, false);
            Vector3 frontBogieDirection = targetFrontPoint - frontBogie.position;
            Vector3 rearBogieDirection = targetRearPoint - rearBogie.position;
            Vector3 frontPoint = frontBogie.position + frontBogieDirection.normalized * speed;
            Vector3 rearPoint = rearBogie.position + rearBogieDirection.normalized * speed;

            frontBogie.rotation = Quaternion.LookRotation(frontBogieDirection);
            rearBogie.rotation = Quaternion.LookRotation(rearBogieDirection);

            transform.SetPositionAndRotation(Vector3.Lerp(frontPoint, rearPoint, ratio),
                Quaternion.LookRotation((frontPoint - rearPoint).normalized));
        }

        private void UpdateCheckpoint(ref int path, ref int checkpoint, bool isFront)
        {
            Vector3 target;
            Vector3 bogie;
            if (isFront)
            {
                bogie = frontBogie.position;
                target = targetFrontPoint;
            }
            else
            {
                target = targetRearPoint;
                bogie = rearBogie.position;
            }

            if (Vector3.Dot(target - bogie, transform.forward) <= 0)
            {
                if (path == trajectory.Count - 1)
                {
                    if (checkpoint == trajectory[path].pathPositions.Count - 1)
                    {
                        return;
                    }
                    else
                    {
                        checkpoint++;
                    }
                }
                else
                {
                    if (checkpoint == trajectory[path].pathPositions.Count - 1)
                    {
                        path++;
                        currentMaxSpeed = trajectory[path].speed;
                        checkpoint = 1;
                    }
                    else
                    {
                        checkpoint++;
                    }
                }
                if (trajectory != null)
                {
                    if (isFront)
                        targetFrontPoint = trajectory[path].pathPositions[checkpoint].transform.position;
                    else
                        targetRearPoint = trajectory[path].pathPositions[checkpoint].transform.position;
                }
            }
        }
    }
    
}
