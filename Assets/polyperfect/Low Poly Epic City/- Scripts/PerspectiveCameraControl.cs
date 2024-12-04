using System;

using System.Collections;
using UnityEngine;
using UnityEngine.Rendering;
//using UnityEngine.Rendering.PostProcessing;

public class PerspectiveCameraControl : MonoBehaviour
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
    public float targetDistanceToTarget = 1000f;
    public float virtualTrackballDistance = 0.25f;
    private bool smoothEndEnabled = true;
    private Coroutine smoothEnd;

    //zoom
    [Header("Zoom")]
    private bool isZooming = false;
    private bool isZoomingEnable = true;
    public float zoomSmoothing = 3.2f;
    public float zoomSpeed = 50f;
    public float minYpos = 50;
    

    //move
    [Header("Move")]
    public float moveSpeed = 100;

    //all
    private bool isRotationStarted = false;
    private Vector3 lastMousePosition;
    private Vector3 mousePosition;
    //private float fieldOfView;
    //public bool AutomaticDOF = true;
    //private float DOFvelocity;
    //DepthOfField depthOfField;

   
    private Camera mainCamera;

    //move
    private Coroutine camMoveCoroutine;
    private Coroutine cameraLook;
    
    private void Start()
    {
        Physics.reuseCollisionCallbacks = true;
        
        distance = Vector3.Distance(transform.position, target.position);
        distanceCache = distance;
        targetDistanceToTarget = distance;

        mainCamera = Camera.main;
        //if(AutomaticDOF)
            //depthOfField = GetComponent<PostProcessVolume>().profile.GetSetting<DepthOfField>();
        //fieldOfView = mainCamera.fieldOfView;
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

        if(Input.GetKey(KeyCode.LeftShift))
        {
            yAxe *= 3;
            xAxe *= 3;
        }
        
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
        /*if (AutomaticDOF)
        {
            if (Physics.Raycast(transform.position, transform.forward, out RaycastHit hit))
            {
                float distance = Vector3.Distance(transform.position, hit.point);
                depthOfField.focusDistance.value = Mathf.SmoothDamp(depthOfField.focusDistance.value, distance, ref DOFvelocity, 0.1f);
                if (distance < 250)
                    depthOfField.focalLength.value = distance + 50;
                else
                    depthOfField.focalLength.value = 300;
            }
        }*/

        bool mouseBtnUp = Input.GetMouseButtonUp(0);
        bool mouseBtn = Input.GetMouseButton(0);

        if (isRotationEnable) {

            if (mouseBtn)
            {
                DisableAutoRotation();
                StopAllCoroutines();
                

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
                        if(!isZooming)
                            targetDistanceToTarget = distance;
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
            distance = Vector3.Distance(transform.position, target.position);
            if (Input.GetAxis("Mouse ScrollWheel") > 0f) // forward
            {
                ZoomIn();
            }
            else if (Input.GetAxis("Mouse ScrollWheel") < 0f) // backwards
            {
                ZoomOut();
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
            
            if (progress > 0.8f)
            {
                EnableAutoRotation();
            }
            yield return null;
        }
    }
    private void ZoomIn()
    {
        float ammout = zoomSpeed;
        if(targetDistanceToTarget - ammout > minYpos) {
            targetDistanceToTarget -= ammout;
        }
        else
        {
            targetDistanceToTarget = minYpos + 10;
        }
        DisableAutoRotation();
        StopAllCoroutines();
        StartCoroutine("ZoomInSmooth");

    }

    private void ZoomOut()
    {
        float ammout = zoomSpeed;
        targetDistanceToTarget += ammout;
        DisableAutoRotation();
        StopAllCoroutines();
        StartCoroutine("ZoomOutSmooth");
    }
    IEnumerator ZoomInSmooth()
    {
        isZooming = true;

        while (distance >= targetDistanceToTarget)
        {
            transform.position += (target.position-transform.position).normalized * (distance - targetDistanceToTarget + zoomSpeed) * Time.deltaTime * zoomSmoothing;
            if(transform.position.y < minYpos)
            {
                transform.position = new Vector3(transform.position.x, minYpos,transform.position.z);
                transform.LookAt(target);
            }
            yield return null;
        }

       // SetDefaultPoint();
       
        isZooming = false;
    }

    IEnumerator ZoomOutSmooth()
    {
        isZooming = true;

        while (distance <= targetDistanceToTarget)
        {
            transform.position += (transform.position-target.position ).normalized * (targetDistanceToTarget - distance + zoomSpeed) * Time.deltaTime * zoomSmoothing;
            yield return null;
        }

        // SetDefaultPoint();

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
        
        var near = new Vector3(0, 0, mainCamera.nearClipPlane);
        
        Vector3 p1 = mainCamera.ScreenToWorldPoint(lastMousePos  + near) - target.position;
        Vector3 p2 = mainCamera.ScreenToWorldPoint(mousePos  + near) - target.position;

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

}
