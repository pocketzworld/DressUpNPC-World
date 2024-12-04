using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace PolyPerfect.City
{
    [RequireComponent(typeof(PathFinding))]
    public class TrainController : MonoBehaviour
    {
        //[HideInInspector]
        public List<Path> trajectory = new List<Path>();
        [HideInInspector]
        public List<Wagon> wagons = new List<Wagon>(64);
        public float maxspeed = 5.0f;
        [Range(0f,1f)]
        public float acceleration = 0.05f;

        private float currentMaxSpeed;
        private const float KMHTOMS = 0.27777f;
        private float speed = 0;

        public Transform frontBogie;
        private int frontBogieCheckpoint = 1;
        private int frontBogiePath = 0;
        public Transform rearBogie;
        private int rearBogieCheckpoint = 1;
        private int rearBogiePath = 0;

        bool isMoving = false;
        private Vector3 targetFrontPoint;
        private Vector3 targetRearPoint;
        public List<Vector3> checkpoints = new List<Vector3>();
        private Vector3 start;

        private float ratio;
        private BoxCollider trainCollider;
        private PathFinding pathFinding;

        private void Awake()
        {
            pathFinding = GetComponent<PathFinding>();
            trainCollider = GetComponent<BoxCollider>();
        }

        void Start()
        {
            ratio = frontBogie.localPosition.z / Vector3.Distance(frontBogie.localPosition, rearBogie.localPosition);
            SetNewPath();
        }
        void FixedUpdate()
        {
            if (isMoving && trajectory != null)
            {
                UpdateCheckpoint(ref frontBogiePath, ref frontBogieCheckpoint, true);
                UpdateCheckpoint(ref rearBogiePath, ref rearBogieCheckpoint, false);
                if(wagons.Count > 0)
                    currentMaxSpeed = Mathf.Min(wagons.Min(w => w.currentMaxSpeed),currentMaxSpeed);
                if (speed < currentMaxSpeed)
                {
                    speed += ((maxspeed * Mathf.Cos((speed/maxspeed) *  0.5f * Mathf.PI)) * Time.deltaTime) * acceleration;
                }
                else
                {
                    speed = Mathf.Lerp(speed, currentMaxSpeed, 10 * Time.deltaTime);
                }
                float magnitude = speed * KMHTOMS * Time.fixedDeltaTime;

                Vector3 frontBogieDirection = targetFrontPoint - frontBogie.position;
                Vector3 rearBogieDirection = targetRearPoint - rearBogie.position;
                Vector3 frontPoint = frontBogie.position+ frontBogieDirection.normalized* magnitude;
                Vector3 rearPoint = rearBogie.position+ rearBogieDirection.normalized * magnitude;

                frontBogie.rotation = Quaternion.LookRotation(frontBogieDirection);
                rearBogie.rotation = Quaternion.LookRotation(rearBogieDirection);

                transform.SetPositionAndRotation(Vector3.Lerp(frontPoint, rearPoint, ratio), 
                    Quaternion.LookRotation((frontPoint - rearPoint).normalized));
                
                foreach (Wagon wagon in wagons)
                {
                    wagon.UpdateWagon(magnitude);
                }
            }
            else
            {
                speed = 0;
            }
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

            //Is bogie behind the checkpoint
            if (Vector3.Dot(target - bogie, transform.forward) <= 0)
            {
                if (path == trajectory.Count - 1)
                {
                    if (checkpoint == trajectory[path].pathPositions.Count - 1)
                    {
                        if (isFront)
                            SetNewPath();
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
                        if (isFront)
                        {
                            if(wagons.All(w => w.transform.forward == transform.forward))
                            {
                                SetWagonTransforms();
                            }
                            currentMaxSpeed = Mathf.Min(trajectory[path].speed, maxspeed);
                        }
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

        //Finds and sets up new path to follow
        private void SetNewPath()
        {
            isMoving = false;

            SetTrajectory();

            if (trajectory != null)
            {
                frontBogieCheckpoint = 1;
                frontBogiePath = 0;
                rearBogieCheckpoint = 1;
                rearBogiePath = 0;
                float closest = float.MaxValue;
                for (int i = 1; i < trajectory[frontBogiePath].pathPositions.Count; i++)
                {
                    float tmp = Vector3.Distance(trajectory[frontBogiePath].pathPositions[i].position, transform.position);
                    if (tmp < closest)
                    {
                        closest = tmp;
                        frontBogieCheckpoint = i;
                        rearBogieCheckpoint = i;
                    }
                }
                targetFrontPoint = trajectory[frontBogiePath].pathPositions[frontBogieCheckpoint].transform.position;
                targetRearPoint = trajectory[rearBogiePath].pathPositions[rearBogieCheckpoint].transform.position;
                transform.SetPositionAndRotation(trajectory[frontBogiePath].pathPositions[1].transform.position, 
                    Quaternion.LookRotation(trajectory[frontBogiePath].pathPositions[frontBogieCheckpoint].transform.position- trajectory[frontBogiePath].pathPositions[frontBogieCheckpoint-1].transform.position));
                SetUpWagons();
                currentMaxSpeed = Mathf.Min(trajectory[frontBogiePath].speed, maxspeed);
                speed = 0;
                if (wagons.Count > 1)
                    start = wagons[wagons.Count - 1].transform.position;
                else
                    start = transform.position;

                StartCoroutine(StartMoving());
            }
            else
            {
                Debug.Log(name + ": Path not found");
                return;
            }
        }

        private void SetTrajectory()
        {
            trajectory = pathFinding.GetPathWithCheckpoints(checkpoints, PathType.Rail);
            checkpoints.Reverse();
        }
        //Rotates the whole train
        public void RotateTrain()
        {
            transform.position = wagons[wagons.Count - 1].transform.position;
            transform.Rotate(Vector3.up,180);
            SetUpWagons();
        }
        //Sets up wagons
        private void SetUpWagons()
        {
            foreach (Wagon wagon in wagons)
            {
                wagon.SetWagon(trajectory);
            }
            SetWagonTransforms();
        }
        //Sets up wagon positions in line behind locomotive
        private void SetWagonTransforms()
        {
            for (int i = 0; i < wagons.Count; i++)
            {
                if (i == 0)
                {
                    wagons[i].transform.SetPositionAndRotation(transform.position - ((wagons[i].Collider.size.z / 2 + trainCollider.size.z / 2) * wagons[i].transform.lossyScale.x) * transform.forward,
                        Quaternion.LookRotation(transform.forward));
                }
                else
                {
                    wagons[i].transform.SetPositionAndRotation(wagons[i - 1].transform.position - ((wagons[i].Collider.size.z / 2 + wagons[i - 1].Collider.size.z / 2) * wagons[i].transform.lossyScale.x) * transform.forward,
                        Quaternion.LookRotation(transform.forward));
                }
            }
        }
        IEnumerator StartMoving()
        {
            yield return new WaitForSeconds(1.5f);
            isMoving = true;
        }
    }
}
