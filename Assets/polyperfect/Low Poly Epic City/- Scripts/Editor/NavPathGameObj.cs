using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace PolyPerfect
{
    namespace City
    {
        public class NavPathGameObj : Editor
        {
            [MenuItem("GameObject/Create Other/Path")]
            public static void CreateNavPath()
            {
                GameObject obj = new GameObject("Path", typeof(Path));
                if (Selection.activeTransform != null)
                    obj.transform.parent = Selection.activeTransform;
                obj.transform.position = SceneView.lastActiveSceneView.camera.transform.position;
                RaycastHit hit;
                if (Physics.Raycast(obj.transform.position, SceneView.lastActiveSceneView.camera.transform.forward, out hit))
                {
                    obj.transform.position = hit.point;
                }

                GameObject gameObject = new GameObject();
                gameObject.transform.parent = obj.transform;
                gameObject.hideFlags = HideFlags.NotEditable;
                obj.GetComponent<Path>().pathPositions.Add(gameObject.transform);
                GameObject gameObject2 = new GameObject();
                gameObject2.transform.parent = obj.transform;
                gameObject2.hideFlags = HideFlags.NotEditable;
                obj.GetComponent<Path>().pathPositions.Add(gameObject2.transform);
                Selection.activeObject = obj;
            }
        }
    }
}
