using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace PolyPerfect.City
{
    [RequireComponent(typeof(PathFinding)),RequireComponent(typeof(Rigidbody))]
    public class CarBehavior : MonoBehaviour
    {
        //[HideInInspector]
        public List<Path> trajectory = new List<Path>();
        public bool randomDestination = true;
        public bool closedCircuit = false;
        private PathFinding pathFinding;
        public float minDistance = 90f;
        public float maxspeed = 5.0f;
        public float maxTurnAngle = 35f;
        public float acceleration = 0.5f;

        public Transform rearWheelsMiddlePoint;
        private int rearWheelsPath = 0;
        private int rearWheelsCheckpoint = 1;
        public Transform frontWheelsMiddlePoint;
        private int frontWheelsPath = 0;
        private int frontWheelsCheckpoint = 1;
        public List<Transform> FrontWheels = new List<Transform>();
        public List<Transform> RearWheels = new List<Transform>();

        private const float KMHTOMS = 5f / 18.0f;
        private float speed;
        private float currentMaxSpeed;
        private float angleDelta = 0;
        private float wheelBase = 0;

        float angle = 0;
        bool isMoving = false;
        bool drivingBihindCar = false;
        bool drivingTrafficLights = false;
        int randomPathTries = 10;

        private Vector3 targetDrivePoint;
        private Vector3 frontPathDirection;
        private Vector3 rearPathDirection;
        private Vector3 destination;

        public List<Vector3> checkpoints = new List<Vector3>();
        private Vector3 start;
        private CarBehavior carInFront;


        private void Awake()
        {
            pathFinding = GetComponent<PathFinding>();
        }

        void Start()
        {
            currentMaxSpeed = maxspeed;
            wheelBase = Vector3.Distance(frontWheelsMiddlePoint.localPosition, rearWheelsMiddlePoint.localPosition);
            if (closedCircuit)
                checkpoints.Add(checkpoints[0]);
            SetNewPath();
        }
        //Finds and sets up new path to follow
        public void SetNewPath()
        {
            isMoving = false;
            if (randomDestination)
            {
                start = transform.position;
                destination = start;
                int tries = 0;
                randomPathTries--;
                //Selects random tile which is at least minDistance away 
                while (Vector3.Distance(start, destination) < minDistance && tries < Tile.Tiles.Count)
                {
                    tries++;
                    Tile t = Tile.Tiles[UnityEngine.Random.Range(0, Tile.Tiles.Count - 1)];
                    if (t.tileType == Tile.TileType.Road || t.tileType == Tile.TileType.RoadAndRail)
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
                if (tries == Tile.Tiles.Count)
                {
                    Debug.Log(name + ": Target Tile not found farther then " + minDistance + "m");
                    return;
                }
                //Path finding
                trajectory = pathFinding.GetPath(start, destination, PathType.Road);
            }
            else
            {
                //Path finding with checkpoints
                if (!closedCircuit)
                    checkpoints.Reverse();
                trajectory = pathFinding.GetPathWithCheckpoints(checkpoints, PathType.Road);
            }
            if (trajectory != null)
            {
                speed = 0;
                rearWheelsPath = 0;
                rearWheelsCheckpoint = 1;
                frontWheelsPath = 0;
                frontWheelsCheckpoint = 1;
                float closest = float.MaxValue;
                for (int i = 1; i < trajectory[0].pathPositions.Count; i++)
                {
                    float tmp = Vector3.Distance(trajectory[0].pathPositions[i].position, transform.position);
                    if (tmp < closest)
                    {
                        closest = tmp;
                        frontWheelsCheckpoint = i;
                        rearWheelsCheckpoint = i;
                    }
                }
                frontPathDirection = (trajectory[frontWheelsPath].pathPositions[frontWheelsCheckpoint].position - trajectory[frontWheelsPath].pathPositions[frontWheelsCheckpoint - 1].position).normalized;
                rearPathDirection = (trajectory[rearWheelsPath].pathPositions[rearWheelsCheckpoint].position - trajectory[rearWheelsPath].pathPositions[rearWheelsCheckpoint - 1].position).normalized;
                targetDrivePoint = trajectory[frontWheelsPath].pathPositions[frontWheelsCheckpoint].transform.position;
                if (randomDestination)
                {
                    transform.position = Vector3.Lerp(trajectory[frontWheelsPath].pathPositions[frontWheelsCheckpoint-1].transform.position, trajectory[frontWheelsPath].pathPositions[frontWheelsCheckpoint].transform.position,Random.Range(0f,0.9f));
                    transform.rotation = Quaternion.LookRotation(frontPathDirection);
                }
                StartCoroutine(StartMovingAfterWait(Random.Range(0.5f,2f)));
            }
            else
            {
                if (randomDestination && randomPathTries > 0)
                {
                    Debug.Log(name + ": Path not found, End tile: " + destination + " || Trying new path");
                    SetNewPath();
                }
                else
                {
                    Debug.LogWarning(name + ": Path not found, End tile: " + destination);
                    gameObject.SetActive(false);
                }
            }
        }

        private void UpdateCheckpoint(ref int path,ref int checkpoint,ref Vector3 pathDirection , Transform wheelsMidpoint, bool isFront)
        {
            if (!trajectory[path] || !trajectory[path].gameObject.activeInHierarchy)
            {
                SetNewPath();
                if (trajectory == null)
                    return;
            }
            Vector3 target = trajectory[path].pathPositions[checkpoint].position;

            //Is wheel behind the checkpoint
            if (Vector3.Dot((target - wheelsMidpoint.position).normalized, (target - (wheelsMidpoint.position- wheelsMidpoint.forward*20)).normalized) <= 0.2f && Vector3.Dot(pathDirection,wheelsMidpoint.forward) > -0.5f)
            {
                if (path == trajectory.Count - 1)
                {
                    if (checkpoint == trajectory[path].pathPositions.Count - 1)
                    {
                        if (isFront)
                        {
                            trajectory[path].Vehicles.Remove(this);
                            SetNewPath();
                        }
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
                        checkpoint = 1;
                        if (!trajectory[path] || !trajectory[path].gameObject.activeInHierarchy || Vector3.Distance(trajectory[path].pathPositions[0].position, trajectory[path-1].pathPositions[trajectory[path - 1].pathPositions.Count-1].position) > 1.5f)
                        {
                            SetNewPath();
                            if (trajectory == null)
                                return;
                        }
                        else if (isFront)
                        {
                            currentMaxSpeed = Mathf.Min(trajectory[path].speed, maxspeed);
                            trajectory[path-1].Vehicles.Remove(this);
                            trajectory[path].Vehicles.Add(this);
                        }
                    }
                    else
                    {
                        checkpoint++;
                    }
                }
                pathDirection = (trajectory[path].pathPositions[checkpoint].position - trajectory[path].pathPositions[checkpoint - 1].position).normalized;
                if (isFront)
                {
                    targetDrivePoint = trajectory[path].pathPositions[checkpoint].transform.position;
                    if (checkpoint == 2)
                    {
                        angleDelta = Vector3.SignedAngle(transform.forward, pathDirection.normalized, transform.up)*0.33f;
                    }
                }
            }
        }
        //Update car incline to keep wheels stay at path
        private void UpdateCarIncline()
        {
            float ratio = frontWheelsMiddlePoint.localPosition.z / wheelBase;
            Vector3 frontPoint = Vector3.Project(frontWheelsMiddlePoint.position - trajectory[frontWheelsPath].pathPositions[frontWheelsCheckpoint - 1].position, frontPathDirection) + trajectory[frontWheelsPath].pathPositions[frontWheelsCheckpoint - 1].position;
            Vector3 rearPoint = Vector3.Project(rearWheelsMiddlePoint.position - trajectory[rearWheelsPath].pathPositions[rearWheelsCheckpoint - 1].position, rearPathDirection) + trajectory[rearWheelsPath].pathPositions[rearWheelsCheckpoint - 1].position;

            transform.SetPositionAndRotation(new Vector3(transform.position.x, Vector3.Lerp(frontPoint, rearPoint, ratio).y, transform.position.z),
                Quaternion.LookRotation(new Vector3(transform.forward.x, (frontPoint - rearPoint).normalized.y, transform.forward.z)));
        }

        void Update()
        {
            if (isMoving && trajectory != null)
            {
                if (rearWheelsMiddlePoint && frontWheelsMiddlePoint)
                {
                    //Update path checkpoints for wheel axles
                    UpdateCheckpoint(ref frontWheelsPath, ref frontWheelsCheckpoint,ref frontPathDirection , frontWheelsMiddlePoint, true);
                    UpdateCheckpoint(ref rearWheelsPath, ref rearWheelsCheckpoint, ref rearPathDirection, rearWheelsMiddlePoint, false);

                    if (drivingBihindCar && trajectory[frontWheelsPath].Vehicles.Count > 0)
                    {
                        if (carInFront.speed < speed)
                            speed = Mathf.Lerp(speed, carInFront.speed * 0.8f, 12 * Time.deltaTime);
                    }
                    else
                    {
                        float targetSpeed = currentMaxSpeed * Mathf.Clamp((1f - Mathf.Abs(Vector3.SignedAngle(transform.forward, (targetDrivePoint - frontWheelsMiddlePoint.position).normalized, Vector3.up)) / maxTurnAngle), 0.65f, 1f);

                        if (trajectory[frontWheelsPath].pathShape == PathShape.LaneChange || trajectory[frontWheelsPath].pathShape == PathShape.RampExit)
                            speed = Mathf.Lerp(speed, targetSpeed * 0.8f, 4 * Time.deltaTime);
                        else if (speed > targetSpeed)
                            speed = Mathf.Lerp(speed, targetSpeed, 3 * Time.deltaTime);
                        else
                            speed = Mathf.Lerp(speed, maxspeed, acceleration * Time.deltaTime);
                        
                    }
                    
                    
                    if (trajectory[frontWheelsPath].pathShape == PathShape.Curve && frontWheelsCheckpoint > 1 && frontWheelsCheckpoint <= 3)
                    {
                        //Calculate turn radius for curve
                        float directionSign = Mathf.Sign(Vector3.SignedAngle(trajectory[frontWheelsPath].pathPositions[2].position - trajectory[frontWheelsPath].pathPositions[1].position, trajectory[frontWheelsPath].pathPositions[3].position - trajectory[frontWheelsPath].pathPositions[1].position, Vector3.up));
                        float radius = Vector3.Distance(trajectory[frontWheelsPath].pathPositions[1].position, trajectory[frontWheelsPath].pathPositions[2].position);
                        float targetAngle = Mathf.Atan(wheelBase /  (Mathf.Abs(radius) + wheelBase)) *(180/Mathf.PI);
                        angle = directionSign * (targetAngle + (directionSign*angleDelta));
                    }
                    else
                    {
                        //Calculate turn delta
                        float targetAngle = Mathf.Clamp(Vector3.SignedAngle(transform.forward, (targetDrivePoint - frontWheelsMiddlePoint.position).normalized, Vector3.up), -maxTurnAngle, maxTurnAngle);
                        float turnDelta = Time.deltaTime * Mathf.Clamp(Mathf.Abs(targetAngle - angle) / maxTurnAngle, 0.35f, 1f) * 150;
                        if ((angle >= 0 && targetAngle < angle) || (angle <= 0 && targetAngle > angle))
                            turnDelta *= 1.25f;

                        if (targetAngle < angle - turnDelta)
                            angle -= turnDelta;
                        else if (targetAngle > angle + turnDelta)
                            angle += turnDelta;
                        else if (targetAngle != angle)
                            angle = targetAngle;

                    }

                    float positionDelta = speed * KMHTOMS * Time.deltaTime;

                    UpdateCarIncline();

                    if (Mathf.Abs(angle) > 0.2f)
                    {
                        //Updates car position and roatation when turning
                        Vector3 frontWheelsVector = (Quaternion.Euler(0, angle, 0) * (frontWheelsMiddlePoint.right)).normalized;
                        Vector3 rotatePoint = frontWheelsMiddlePoint.position - frontWheelsVector * wheelBase / Vector3.Dot(rearWheelsMiddlePoint.forward, frontWheelsVector);
                        float alpha = Mathf.Sign(angle)*(180 * positionDelta) / (Mathf.PI * Vector3.Distance(rotatePoint, rearWheelsMiddlePoint.position));
                        transform.RotateAround(rotatePoint, transform.up, alpha);
                    }
                    else
                    {
                        //Updates car position and roatation when driving straight
                        Vector3 newPosition = transform.forward * positionDelta;
                        transform.position += newPosition;
                    }

                    //Set correct rotation of car wheels
                    foreach (Transform t in FrontWheels)
                    {
                        t.parent.localRotation = Quaternion.Euler(0, angle,0);
                        t.Rotate(Vector3.right,speed * Time.deltaTime * 40); 
                    }
                    foreach (Transform t in RearWheels)
                    {
                        t.Rotate(speed * Time.deltaTime * 40, 0, 0);
                    }
                }
            }
            else
            {
                speed = 0;
            }
        }

        private void OnTriggerEnter(Collider other)
        {
            //Handles traffic lights
            if (other.CompareTag("TrafficLight") && !drivingTrafficLights )
            {
                TrafficLight trafic = other.GetComponent<TrafficLight>();
                if (Vector3.Angle(-trafic.transform.forward,transform.forward) < 25)
                {
                    if (!trafic.isGreen)
                    {
                        drivingTrafficLights = true;
                        isMoving = false;
                        trafic.lightChange += StartMoving;
                    }
                }
            }
            //Handles traffic crosswalks
            if (other.CompareTag("Crosswalk"))
            {
                Crosswalk crosswalk = other.GetComponent<Crosswalk>();
                if (crosswalk.PedestriansAreCrossing)
                {
                    crosswalk.stateChange += CrosswalkChange;
                    isMoving = false;
                }

            }
            //Handles traffic level crossing
            else if (other.CompareTag("LevelCrossing"))
            {
                LevelCrossingController levelCrossing = other.GetComponent<LevelCrossingController>();
                if (levelCrossing.trainCrossing)
                {
                    levelCrossing.stateChange += LevelCrossingChange;
                    isMoving = false;
                }

            }
            // Primitive car avoidence
            else if (other.CompareTag("Car") && !other.isTrigger && frontWheelsPath > 0)
            {
                float direction = Vector3.Angle(transform.forward, other.transform.forward);
                float carDirection = Vector3.Angle(transform.right, (other.transform.position - transform.position).normalized);
                if (direction < 60)
                {
                    carInFront = other.GetComponentInParent<CarBehavior>();
                    if (trajectory[frontWheelsPath].Vehicles.Contains(carInFront) || direction < 45)
                        drivingBihindCar = true;
                }
               if (direction > 40 && carDirection < 80 && carDirection > 45 && !drivingBihindCar && direction < 110)
                {
                    isMoving = false;
                }

            }
        }

        private void OnTriggerExit(Collider other)
        {
            if (other.CompareTag("Car") && !other.isTrigger)
            {
                StopCoroutine(StartMovingAfterWait(0.2f));
                StartCoroutine(StartMovingAfterWait(0.2f));
                drivingBihindCar = false;
            }
            else if (other.CompareTag("TrafficLight"))
            {
                TrafficLight trafic = other.GetComponent<TrafficLight>();
                trafic.lightChange -= StartMoving;
                drivingTrafficLights = false;
            }
            else if (other.CompareTag("Crosswalk"))
            {
                other.GetComponent<Crosswalk>().stateChange -= CrosswalkChange;
            }
            else if (other.CompareTag("LevelCrossing"))
            {
                other.GetComponent<LevelCrossingController>().stateChange -= LevelCrossingChange;
            }
        }
        void StartMoving(bool isGreen)
        {
            if (isGreen)
            {
                drivingTrafficLights = false;
                isMoving = true;
            }
        }
        void CrosswalkChange(bool crossing)
        {
            if (!crossing && !drivingTrafficLights)
            {
                isMoving = true;
            }
        }
        void LevelCrossingChange(bool crossing)
        {
            if (!crossing)
            {
                isMoving = true;
            }
        }

        IEnumerator StartMovingAfterWait(float seconds)
        {
            yield return new WaitForSeconds(seconds);
            isMoving = true;
        }

    }
}