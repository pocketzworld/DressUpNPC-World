using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PolyPerfect.City
{
    public class ShipBehavior : MonoBehaviour
    {

        public Path trajectory;
        public float maxspeed = 5.0f;
        private const float KMHTOMS = 0.27777f;
        private float currentMaxSpeed;
        [HideInInspector]
        public float speed;
        public float acceleration;
        int activepoint = 0;
        private Vector3 targetDrivePoint;
        private bool isMoving;
        [Range(0f,40f)]
        public float shipTipping = 0;

        // Start is called before the first frame update
        void Start()
        {
            targetDrivePoint = trajectory.pathPositions[activepoint].position;
            isMoving = true;
            currentMaxSpeed = maxspeed;
        }

        private void FixedUpdate()
        {
            if(isMoving)
            {
               /* float realT = trajectory.spline.GetTime(distance);
                transform.position = trajectory.spline.GetPoint(realT);
                transform.rotation = Quaternion.LookRotation(trajectory.spline.GetNormal(realT));
                distance += Time.fixedDeltaTime * maxspeed;
                if(distance >= trajectory.spline.splineLength)
                {
                    distance = 0;
                }*/
                if (Vector3.Dot(targetDrivePoint - transform.position, transform.forward) <= 0)
                {
                    MoveToNextPoint();
                }
                Vector3 direction = targetDrivePoint - transform.position;

                if (speed < currentMaxSpeed)
                {
                    speed += ((maxspeed * Mathf.Cos((speed / maxspeed) * 0.5f * Mathf.PI)) * Time.deltaTime) * acceleration;
                }
                else
                {
                    speed = Mathf.Lerp(speed, currentMaxSpeed, 10 * Time.deltaTime);
                }

                

                if (direction != Vector3.zero)
                {
                    direction = direction.normalized;
                    direction.y = speed/maxspeed * shipTipping*0.015f;
                    transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(direction, Vector3.up),1f);
                }
                direction = transform.forward;
                direction.y = 0;
                Vector3 newPosition = transform.position + (direction * speed * KMHTOMS * Time.deltaTime);
                transform.position = newPosition;
            }
            else
            {
                speed = 0;
            }

        }
        public void MoveToNextPoint()
        {
            if (activepoint == trajectory.pathPositions.Count - 1)
            {
                activepoint = 0;
                speed = 0;
            }
            else
            {
                activepoint++;
            }
            targetDrivePoint = trajectory.pathPositions[activepoint].transform.position;
        }

    }
}
