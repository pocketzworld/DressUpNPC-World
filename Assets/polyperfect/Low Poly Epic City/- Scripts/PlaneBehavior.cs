using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace PolyPerfect.City
{
    public class PlaneBehavior : MonoBehaviour
    {

        public Path trajectory;
        public float maxspeed = 5.0f;
        private const float KMHTOMS = 0.27777f;
        private float currentMaxSpeed;
        [HideInInspector]
        public float speed;
        [Range(0f, 1f)]
        public float acceleration;
        [Range(0f, 5f)]
        public float brakePower;
        int activepoint = 0;
        private Vector3 targetDrivePoint;
        private bool isMoving;
        

        // Start is called before the first frame update
        void Start()
        {
            targetDrivePoint = trajectory.pathPositions[activepoint].position;
            isMoving = true;
            currentMaxSpeed = maxspeed;
        }

        private void FixedUpdate()
        {
            if (isMoving)
            {
                if (Vector3.Dot(targetDrivePoint - transform.position, transform.forward) < 0 && Vector3.Distance(targetDrivePoint, transform.position) < 20)
                {
                    MoveToNextPoint();
                }
                Vector3 direction = targetDrivePoint - transform.position;

                if(transform.position.y < 150 && activepoint > 5 && transform.position.y > 20)
                {
                    currentMaxSpeed = maxspeed * (transform.position.y) * 0.0075f;
                }
                else if(activepoint == trajectory.pathPositions.Count-1)
                {
                    currentMaxSpeed = 50;
                }

                if (speed < currentMaxSpeed)
                {
                    speed += ((maxspeed * Mathf.Cos((speed / maxspeed) * 0.5f * Mathf.PI)) * Time.deltaTime) * acceleration;
                }
                else
                {
                    speed = Mathf.Lerp(speed, currentMaxSpeed, brakePower * Time.deltaTime);
                }



               // if (direction != Vector3.zero)
               // {
                    
                    direction = direction.normalized;
                float angle = Vector3.SignedAngle(transform.forward, direction, transform.up);
                    //direction.y = speed / maxspeed * shipTipping;
                    if (activepoint == 0)
                    {
                        transform.rotation = Quaternion.LookRotation(direction, Vector3.up);
                    }
                    else
                        transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(direction, Quaternion.AngleAxis(-(angle > 10 ? angle : 0f), transform.forward) * Vector3.up), 1.75f);
                if(transform.localRotation.eulerAngles.x < 180)
                {
                    transform.GetChild(0).localRotation = Quaternion.Euler(-transform.localRotation.eulerAngles.x*1.5f,0f,0f);
                }
                else
                    transform.GetChild(0).localRotation = Quaternion.identity;
                //  }
                direction = transform.forward;
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
                currentMaxSpeed = maxspeed;
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