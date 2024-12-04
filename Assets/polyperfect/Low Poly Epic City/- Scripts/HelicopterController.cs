using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace PolyPerfect.City
{
    public class HelicopterController : MonoBehaviour
    {
        public Path trajectory;
        public float maxspeed = 5.0f;
        private float currentMaxSpeed;
        [HideInInspector]
        public float speed;
        [Range(0f, 1f)]
        public float acceleration;
        [Range(0f, 5f)]
        public float brakePower;

        public Transform propeller;
        public Transform tialPropeller;

        int activepoint = 0;
        private Vector3 targetDrivePoint;
        private bool isMoving;

        private float tippingVelocity;
        private float tipAngle = 0f;

        private float fowardAcceleration;
        private float lastfowardSpeed = 0;
        private Vector2 lastPosition;

        private const float KMHTOMS = 0.27777f;
        // Start is called before the first frame update
        void Start()
        {
            lastPosition = transform.position;
            targetDrivePoint = trajectory.pathPositions[activepoint].position;
            isMoving = true;
            currentMaxSpeed = maxspeed;
        }

        private void FixedUpdate()
        {
            if (isMoving)
            {
                float fowardSpeed = ((new Vector2(transform.position.x,transform.position.z) - lastPosition).magnitude / Time.fixedDeltaTime) * 3.6f;
                fowardAcceleration = ((fowardSpeed - lastfowardSpeed)/ Time.fixedDeltaTime )*3.6f;
                lastfowardSpeed = fowardSpeed;
                lastPosition = new Vector2(transform.position.x, transform.position.z);

                float targetDistance = Vector3.Distance(targetDrivePoint, transform.position);
                if (targetDistance < 0.25f)
                {
                    MoveToNextPoint();
                }

                if(Mathf.Abs(fowardAcceleration) > 5)
                    tipAngle = Mathf.SmoothDamp(tipAngle,(fowardAcceleration / maxspeed ) * 15f, ref tippingVelocity, 0.5f);

                Vector3 direction = targetDrivePoint - transform.position;
                if (targetDistance < 50 / brakePower)
                {
                    currentMaxSpeed = targetDistance + 2;
                }
                else
                {
                    currentMaxSpeed = maxspeed;
                }

                if (speed < currentMaxSpeed)
                {
                    speed += ((maxspeed * Mathf.Cos((speed / maxspeed) * 0.5f * Mathf.PI)) * Time.deltaTime) * acceleration;  
                }
                else
                {
                    speed = Mathf.Lerp(speed, currentMaxSpeed, brakePower * Time.deltaTime);
                }

                float angle = Vector3.Angle(Vector3.ProjectOnPlane(transform.forward, Vector3.up),Vector3.ProjectOnPlane(direction, Vector3.up));
                
                if (angle < 60 || Mathf.Abs(fowardAcceleration) < 5)
                {
                    
                    //direction.y = speed / maxspeed * shipTipping;
                    Vector3 newPosition = transform.position + (direction.normalized * speed * KMHTOMS * Time.deltaTime);
                    transform.position = newPosition;
                }
                else
                {
                    speed = 0;
                }

                if(Mathf.Abs(fowardAcceleration) < 5)
                    tipAngle = 0f;
                direction.y = 0;
                transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(Quaternion.AngleAxis(tipAngle, transform.right) * direction), 1.75f);
            }
            else
            {
                speed = 0;
            }

        }
        private void Update()
        {
            propeller.Rotate(0f, 75f, 0f);
            tialPropeller.Rotate(75f, 0, 0f);
        }
        public void MoveToNextPoint()
        {
            if (activepoint == trajectory.pathPositions.Count - 1)
            {
                trajectory.pathPositions.Reverse();
                activepoint = 0;
                speed = 0;
                fowardAcceleration = 0;
                tipAngle = 0f;
            }
            else
            {
                activepoint++;
            }
            
            targetDrivePoint = trajectory.pathPositions[activepoint].transform.position;
        }

    }
}