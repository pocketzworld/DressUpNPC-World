using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PolyPerfect.City
{
    [RequireComponent(typeof(PathFinding)),RequireComponent(typeof(Rigidbody))]
    public class HumanBehavior : MonoBehaviour
    {
        [HideInInspector]
        public List<Path> trajectory = new List<Path>();
        private PathFinding pathFinding;
        private Animator animator;
        public float maxspeed = 5.0f;
        public bool randomDestination;
        private float speed;
        private int activepoint = 0;
        private int activePath = 0;
        bool isMoving = false;
        private Vector3 targetPoint;
        public Vector3 destination;
        private Vector3 start;
        private void Awake()
        {
            pathFinding = GetComponent<PathFinding>();
            animator = GetComponent<Animator>();
        }
        void Start()
        {
            maxspeed = Random.Range(2f, 3f);
            start = transform.position;
            if (randomDestination)
            {
                //Selects random tile which is at least 60m away and less then 300m
                SetRandomDestination();
            }
            trajectory = pathFinding.GetPath(start,destination,PathType.Sidewalk);
            if (trajectory != null)
            {
                isMoving = true;
                GetClocestPoint();
                targetPoint = trajectory[0].pathPositions[activepoint].transform.position;
                start = transform.position;
            }
            else
            {
                Debug.Log(name + ": Path not found");
            }
        }
        void FixedUpdate()
        {
            if (isMoving)
            {
                if (Vector3.Distance(targetPoint , transform.position) < 0.1f)
                {
                    MoveToNextPoint();
                }
                Vector3 direction = targetPoint - transform.position;

                speed = Mathf.Lerp(speed, maxspeed, Time.deltaTime);
                if (speed > maxspeed)
                {
                    speed = Mathf.Lerp(speed, maxspeed, 10 * Time.deltaTime);
                }
                
                Vector3 newPosition = transform.position + (direction.normalized * speed * Time.deltaTime);
                transform.position = newPosition;

                if (direction != Vector3.zero)
                {
                    direction.y = 0;
                    transform.rotation = Quaternion.LookRotation(direction, Vector3.up);
                }
            }
            else
            {
                speed = 0;
            }
            animator.SetFloat("speed",speed * 0.8f);
        }
        public void MoveToNextPoint()
        {
            if (activePath == trajectory.Count - 1)
            {
                if (activepoint == trajectory[activePath].pathPositions.Count - 1)
                {
                    isMoving = false;
                    if (randomDestination)
                    {
                        //Selects random tile which is at least 90m away 
                        SetRandomDestination();
                    }
                    else
                    {
                        destination = start;
                        start = transform.position;
                    }
                    trajectory = pathFinding.GetPath(start,destination,PathType.Sidewalk);
                    if (trajectory != null)
                    {
                        activePath = 0;
                        activepoint = 0;
                        GetClocestPoint();
                        speed = 0;
                        isMoving = true;
                    }
                    else
                    {
                        Debug.Log(name + ": Path not found");
                    }
                }
                else
                {
                    activepoint++;
                }
            }
            else
            {
                if (activepoint == trajectory[activePath].pathPositions.Count - 1)
                {
                    activePath++;
                   /* if (trajectory[activePath].speed < maxspeed)
                    {
                        maxspeed = trajectory[activePath].speed;
                    }
                    else
                    {
                        currentMaxSpeed = maxspeed;
                    }*/

                    activepoint = 1;
                }
                else
                {
                    activepoint++;
                }
            }
            if(trajectory != null)
                targetPoint = trajectory[activePath].pathPositions[activepoint].transform.position + (trajectory[activePath].pathPositions[activepoint].transform.right * Random.Range(-0.8f,0.8f));
        }
        private void SetRandomDestination()
        {
            start = transform.position;
            destination = start;
            while (Vector3.Distance(start, destination) < 60 || Vector3.Distance(start, destination) > 300)
            {
                Tile t = Tile.Tiles[UnityEngine.Random.Range(0, Tile.Tiles.Count - 1)];
                if (t.tileType == Tile.TileType.Road || t.tileType == Tile.TileType.OnlyPathwalk)
                {
                    if (t.verticalType == Tile.VerticalType.Bridge)
                    {
                        destination = t.transform.position + (Vector3.up * 12);
                    }
                    else
                    {
                        destination = t.transform.position;
                    }
                }
            }
        }
        private void GetClocestPoint()
        {
            float minDistance = Mathf.Infinity;
            for (int i = 0; i < trajectory[activePath].pathPositions.Count; i++)
            {
                float distance = Vector3.Distance(trajectory[activePath].pathPositions[i].position, transform.position);
                if (distance < minDistance)
                {
                    minDistance = distance;
                    activepoint = i;
                }
            }
        }
        private void OnTriggerEnter(Collider other)
        {
            if (other.CompareTag("TrafficLightCrosswalk"))
            {
                TrafficLight trafic = other.GetComponentInParent<TrafficLight>();
                if (trafic.isGreen)
                {
                    isMoving = false;
                    trafic.lightChange += StartMoving;
                }
            }
        }
        private void OnTriggerExit(Collider other)
        {
            if (other.CompareTag("TrafficLightCrosswalk"))
            {
                other.GetComponentInParent<TrafficLight>().lightChange -= StartMoving;
            }
        }
        void StartMoving(bool isGreen)
        {
            if(!isGreen)
                isMoving = true;
        }
    }
}
