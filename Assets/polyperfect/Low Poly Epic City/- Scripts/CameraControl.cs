using System;

using System.Collections;
using UnityEngine;
using UnityEngine.Rendering;

public class CameraControl : MonoBehaviour
{

    //autorotaton
    [Header("Autorotation")]
    public float autoRotationSpeed = 3;
    private bool isAutoRotationEnable = true;
    private int autoRotateDierction = 1;

    //rotation
    [Header("Rotation")]
    public float rotationSpeed = 1;
    public Transform target;
    private Vector3 targetPositionCache;
    private bool isRotationEnable = true;
    public float distance = 1000f;
    private float distanceCache = 1000f;
    public float currentDistanceToTarget = 1000f;
    public float virtualTrackballDistance = 0.25f;
    private bool smoothEndEnabled = true;
    private Coroutine smoothEnd;

    //zoom
    [Header("Zoom")]
    private bool isZooming = false;
    private bool isZoomed = true;
    private bool isZoomingEnable = true;
    //private bool maxZoomReached = true;
    public float zoomSpeed = 0.8f;
    public float minYpos = 150;
    //private Coroutine zoomCoroutine;


    //move
    [Header("Move")]
    public float moveSpeed = 10;

    //all
    Vector3 velocity;
    private bool isRotationStarted = false;
    private Vector3 lastMousePosition;
    private Vector3 mousePosition;
    private float fieldOfView;
    GameObject postprocess;

    //move
    private Coroutine camMoveCoroutine;
    private Coroutine cameraLook;
    
    private void Start()
    {
        Physics.reuseCollisionCallbacks = true;
        
        distance = Vector3.Distance(transform.position, target.position);
        distanceCache = distance;

        fieldOfView = GetComponent<Camera>().fieldOfView;
        transform.LookAt(target.position);

        targetPositionCache = new Vector3(target.position.x, target.position.y, target.position.z);

        EnableAutoRotation();
    }

    
    private void Update()
    {
        if (isAutoRotationEnable)
        {
            transform.RotateAround(target.position, Vector3.up, autoRotationSpeed * Time.deltaTime * autoRotateDierction);
        }

        float xAxe = Input.GetAxis("Horizontal");
        float yAxe = Input.GetAxis("Vertical");
        
        if (yAxe > 0 || yAxe < 0) {

            DisableAutoRotation();
            Vector3 forward = transform.forward;
            forward.y = 0;
            Vector3 moveDelta = forward.normalized * ( yAxe * moveSpeed * Time.deltaTime);
            transform.position += moveDelta;
            target.position += moveDelta;
        }

        if (xAxe > 0 || xAxe < 0)
        {
            DisableAutoRotation();
            Vector3 moveDelta = transform.right * (xAxe * moveSpeed * Time.deltaTime);
            //float amount = xAxe * -moveSpeed * Time.deltaTime;
            transform.position += moveDelta;
            target.position += moveDelta;

        }

        bool mouseBtnUp = Input.GetMouseButtonUp(0);
        bool mouseBtn = Input.GetMouseButton(0);

        if (isRotationEnable) {

            if (mouseBtn)
            {
                DisableAutoRotation();
                StopAllCoroutines();
                isZooming = false;
                mousePosition = Input.mousePosition;

                if (isRotationStarted)
                {
                    var lastPos = this.transform.position;
                    var targetPos = target.position;
                    
                    var rotation = FigureOutAxisAngleRotation(lastMousePosition, mousePosition) ;
                    var vecPos = (targetPos - lastPos).normalized * -distance ;
                    Vector3 finalPosition = rotation * vecPos + targetPos;

                    if (finalPosition.y < minYpos)
                    {
                        finalPosition = new Vector3(finalPosition.x, minYpos, finalPosition.z);
                    }

                    this.transform.position = finalPosition;
                    this.transform.LookAt(targetPos);

                    lastMousePosition = mousePosition;
                }
                else
                {
                    isRotationStarted = true;
                    lastMousePosition = mousePosition;
                }
            }
            else
            {
                isRotationStarted = false;
            }

           
            if (mouseBtnUp)
            {
               
                Vector3 upMousePosition = Input.mousePosition;
                float mouseDistance = Vector3.Distance(lastMousePosition, upMousePosition);
                mouseDistance = mouseDistance / 300;
                mouseDistance = Mathf.Clamp(mouseDistance, 1f, 3);
                Vector3 direction =  upMousePosition - lastMousePosition;

                if(direction.x >0)
                {
                    autoRotateDierction = 1;
                } else
                {
                    autoRotateDierction = -1;
                }
                if(smoothEndEnabled) {
                    smoothEnd = StartCoroutine(SmoothEnd(upMousePosition, upMousePosition + direction * mouseDistance, mouseDistance));
                }
                EnableAutoRotation();
            }
        }
        if (isZoomingEnable) 
        {
            if (Input.GetAxis("Mouse ScrollWheel") > 0f) // forward
            {
                if (!isZooming)
                {
                    ZoomIn();
                }
            }
            else if (Input.GetAxis("Mouse ScrollWheel") < 0f) // backwards
            {
                if (!isZooming)
                {
                    ZoomOut();
                }
            }
        }

    }

    

    IEnumerator SmoothEnd(Vector3 start, Vector3 end, float duration )
    {
        DisableAutoRotation();
        float currentDuration = duration;
        Vector3 lastPosition = start;

        while (currentDuration > 0)
        {
            currentDuration -= Time.deltaTime;
            float progress = 1 - currentDuration / duration;
            float ease =  Mathf.Sin(progress * Mathf.PI * 0.5f);
            Vector3 nextPosition = Vector3.Slerp(start, end, ease);

            var lastPos = this.transform.position;
            var targetPos = target.position;

            var rotation = FigureOutAxisAngleRotation(lastPosition, nextPosition);
            var vecPos = (targetPos - lastPos).normalized * -distance;

            Vector3 finalPosition = rotation * vecPos + targetPos;

            if (finalPosition.y < minYpos)
            {
                finalPosition = new Vector3(finalPosition.x, minYpos, finalPosition.z);
            }

            this.transform.position = finalPosition;
            this.transform.LookAt(targetPos);

            lastPosition = nextPosition;
            
            if (progress > 0.8f && !isZoomed)
            {
                EnableAutoRotation();
            }
            yield return null;
        }
    }
    private void ZoomIn()
    {
        float ammout = zoomSpeed * Time.deltaTime;
        if(Camera.main.orthographicSize - ammout > 1) { 
            Camera.main.orthographicSize -= ammout;
        }
        else
        {
            Camera.main.orthographicSize = 1;
        }
    }

    private void ZoomOut()
    {
        float ammout = zoomSpeed * Time.deltaTime;
        Camera.main.orthographicSize += ammout;
    }
    IEnumerator ZoomCorrection()
    {
        isZooming = true;
        currentDistanceToTarget = Vector3.Distance(transform.position, target.position);

        while (Vector3.Distance(transform.position, target.position) >= distanceCache)
        {
            transform.position = Vector3.SmoothDamp(target.position, transform.position, ref velocity, 0.1f * Time.deltaTime);
            yield return null;
        }

        SetDefaultPoint();
       
        isZooming = false;
        isZoomed = false;
        //maxZoomReached = true;
        minYpos = 150;
    }
 

    IEnumerator CameraZoom(Vector3 targetZoomPosition, Vector3 hitPoint)
    {
        isZooming = true;
        isZoomed = true;
        DisableAutoRotation();

        if (smoothEnd != null)
        {
            StopCoroutine(smoothEnd);
        }
       
        while (Vector3.Distance(targetZoomPosition, transform.position) > 0.5f)
        {   
            
            float currentDistance = Vector3.Distance(transform.position, target.position);

            if (currentDistance > distanceCache)
            {
                StartCoroutine(ZoomCorrection());
                //StopCoroutine(zoomCoroutine);
               
            }

            transform.position = Vector3.SmoothDamp(targetZoomPosition, transform.position, ref velocity, zoomSpeed * Time.deltaTime);
            

            SetNewPoint(hitPoint);
            yield return null;
        }
        //SetDefaultPoint();
        isZooming = false;
    }

    public void SetNewPoint(Vector3 focusPoint )
    {
        target.position = focusPoint;
        distance = Vector3.Distance(transform.position, focusPoint);
        minYpos = 60;
    }

    public void SetDefaultPoint()
    {
        target.position = targetPositionCache;
        distance = distanceCache;
    }
    public void EnableAutoRotation()
    {
        isAutoRotationEnable = true;
    }

    public void DisableAutoRotation()
    {
        isAutoRotationEnable = false;
    }

    public void EnableRotation()
    {
        isRotationEnable = true;
    }

    public void DisableRotation()
    {
        isRotationEnable = false;
    }

    public void EnableZooming()
    {
        isZoomingEnable = true;
    }

    public void DisableZooming()
    {
        isZoomingEnable = false;
    }

    private Quaternion FigureOutAxisAngleRotation(Vector3 lastMousePos, Vector3 mousePos)
    {
        if (lastMousePos.x == mousePos.x && lastMousePos.y == mousePos.y)
        {
            return Quaternion.identity;
        }

        var near = new Vector3(0, 0, Camera.main.nearClipPlane);
        Vector3 p1 = Camera.main.ScreenToWorldPoint(lastMousePos * rotationSpeed + near);
        Vector3 p2 = Camera.main.ScreenToWorldPoint(mousePos * rotationSpeed + near);

        Vector3 axisOfRotation = Vector3.Cross(p2, p1);

       
        var twist = (p2 - p1).magnitude / (2.0f * virtualTrackballDistance);

        if (twist > 1.0f)
        {
            twist = 1.0f;
        }

        if (twist < -1.0f)
        {
            twist = -1.0f;
        }

        var phi = (2.0f * Mathf.Asin(twist)) * 180 / Mathf.PI;

       
        Quaternion rotationAngle = Quaternion.AngleAxis(phi, axisOfRotation);
        return rotationAngle;
    }


    private Quaternion TrackBall(float p1x, float p1y, float p2x, float p2y, float radius)
    {
        // if there has been no drag, then return "no rotation"
        if (p1x == p2x && p1y == p2y)
        {
            return Quaternion.identity;
        }

        var p1 = ProjectToSphere(radius, p1x, p1y);
        var p2 = ProjectToSphere(radius, p2x, p2y);
        var a = Vector3.Cross(p2, p1); // axis of rotation
                                       // how much to rotate around above axis
        var d = p1 - p2;
        var t = d.magnitude / (2.0f * radius);

        // clamp values to stop things going out of control.
        if (t > 1.0f)
        {
            t = 1.0f;
        }

        if (t < -1.0f)
        {
            t = -1.0f;
        }

        var phi = 2.0f * Mathf.Asin(t);
        phi = phi * 180 / Mathf.PI; // to degrees

        return Quaternion.AngleAxis(phi, a);
    }

    private Vector3 ProjectToSphere(float distance, float x, float y)
    {
        float z;
        float d = Mathf.Sqrt(x * x + y * y);
        if (d < distance * 0.707f)
        {
            // inside sphere
            z = Mathf.Sqrt(distance * distance - d * d);
        }
        else
        {
            // on hyperbola
            var t = distance / 1.4142f;
            z = t * t / d;
        }

        return new Vector3(x, y, z);
    }

    void OnDrawGizmos()
    {
        // Draw a yellow sphere at the transform's position
        Gizmos.color = Color.red;
        Gizmos.DrawSphere(target.position, 1);
    }
}
