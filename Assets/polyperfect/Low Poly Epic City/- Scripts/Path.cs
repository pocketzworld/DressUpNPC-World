using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditorInternal;
#endif
namespace PolyPerfect
{
    namespace City
    {
        public enum PathType
        {
            Road,
            Rail,
            Sidewalk
        }
        public enum PathShape
        {
            Strait,
            Turn,
            RampExit,
            RampEnter,
            LaneChange,
            Curve
        }

        public class Path : MonoBehaviour
        {
            public PathType pathType;
            public PathShape pathShape;
            [Range(0,300)]
            public int speed;
            [HideInInspector]
            // List of paths checkpoins
            public List<Transform> pathPositions = new List<Transform>();
            public List<Vector3> spline = new List<Vector3>();
            [HideInInspector]
            public List<Path> nextPaths = new List<Path>();
            private int id;
            [HideInInspector]
            public int TileId;
            public int Id => id;
            [HideInInspector]
            public List<CarBehavior> Vehicles = new List<CarBehavior>();
            
            private void Awake()
            {
                id = IDManager.GetFreeID();
                //spline = new BSpline(pathPositions, 2);
            }

        }
        // Editor custom inspector
        // Handles visual rendering and editing of path
        #region Editor
#if UNITY_EDITOR
        [CustomEditor(typeof(Path))]
        public class CustomPath2Editor : Editor
        {
            SerializedProperty m_PathPositionProp;
            Vector3 currPosGlobal;
            Vector3 currPos;
            int editingID = 0;
            bool editing = false;
            ReorderableList reorderableList;
            Path navPath;
            private void OnEnable()
            {
                navPath = target as Path;
                //navPath.spline = new BSpline(navPath.pathPositions, 2);
                m_PathPositionProp = serializedObject.FindProperty("pathPositions");
                reorderableList = new ReorderableList(serializedObject, m_PathPositionProp, true, true, true, true);
                reorderableList.drawElementCallback = (Rect rect, int index, bool isActive, bool isFosused) =>
                {
                    Transform checkpointTransform = ((Transform)m_PathPositionProp.GetArrayElementAtIndex(index).objectReferenceValue);
                    if (!checkpointTransform)
                        return;
                    if (isActive)
                    {
                        currPos = checkpointTransform.localPosition;
                        currPosGlobal = checkpointTransform.position;
                    }
                    EditorGUI.LabelField(new Rect(rect.x, rect.y, EditorGUIUtility.currentViewWidth - 50, EditorGUIUtility.singleLineHeight), (index + 1).ToString() + ".");
                    EditorGUI.BeginDisabledGroup(!editing || !isActive);
                    checkpointTransform.localPosition =
                        EditorGUI.Vector3Field(new Rect(rect.x + 20, rect.y, EditorGUIUtility.currentViewWidth - 70, EditorGUIUtility.singleLineHeight), GUIContent.none, checkpointTransform.localPosition);
                    EditorGUI.EndDisabledGroup();
                    if (isActive)
                    {
                        editingID = index;
                        if (checkpointTransform.localPosition != currPos)
                        {
                            Undo.RegisterCompleteObjectUndo(target, "Changed Checkpoint Position");
                            currPosGlobal = navPath.transform.TransformPoint(currPos);
                            EditorUtility.SetDirty(target);
                        }
                    }
                };
                reorderableList.onMouseUpCallback = (ReorderableList list) =>
                {
                    SceneView.RepaintAll();
                };
                reorderableList.onAddCallback = (ReorderableList list) =>
                {
                    GameObject gameObject = new GameObject();
                    gameObject.transform.parent = navPath.transform;
                    gameObject.hideFlags = HideFlags.NotEditable;
                    navPath.pathPositions.Add(gameObject.transform);
                    reorderableList.index = navPath.pathPositions.Count - 1;
                    reorderableList.DoLayoutList();
                };
                reorderableList.onRemoveCallback = (ReorderableList list) =>
                {
                    if (EditorUtility.DisplayDialog("Delete Checkpoint?", "Are you sure you want remove checkpoint?", "Delete", "Cancel"))
                    {
                        if (navPath.pathPositions[list.index] != null)
                        {
                            GameObject gameObject = navPath.pathPositions[list.index].gameObject;
                            navPath.pathPositions.RemoveAt(list.index);
                            GameObject.DestroyImmediate(gameObject);
                            editingID = navPath.pathPositions.Count-1;
                            reorderableList.index = navPath.pathPositions.Count - 1;
                            reorderableList.DoLayoutList();
                            // ReorderableList.defaultBehaviours.DoRemoveButton(list);
                        }
                    }
                };

                    reorderableList.drawHeaderCallback = (Rect rect) =>
                {
                    EditorGUI.LabelField(rect, "Path Checkpoints");

                    editing = GUI.Toggle(new Rect(rect.x + 150, rect.y + 2, EditorGUIUtility.currentViewWidth - 200, EditorGUIUtility.singleLineHeight - 2), editing, "Edit", "Button");
                };
            }

            public override void OnInspectorGUI()
            {
                base.OnInspectorGUI();
                serializedObject.Update();
               

                reorderableList.DoLayoutList();
                serializedObject.ApplyModifiedProperties();
            }
            void OnSceneGUI()
            {
                if (editing)
                {
                    Tools.hidden = true;
                    Vector3 newPosGlobal = Handles.PositionHandle(currPosGlobal,Quaternion.identity);
                    if (newPosGlobal != currPosGlobal)
                    {
                        Undo.RegisterCompleteObjectUndo(target, "Changed Checkpoint Position");
                        currPosGlobal = newPosGlobal;
                        currPos = navPath.transform.InverseTransformPoint(currPosGlobal);
                        navPath.pathPositions[editingID].position = currPosGlobal;
                        EditorUtility.SetDirty(target);
                    }
                }
                else
                {
                    Tools.hidden = false;
                }
                /*Vector3 lineStart = navPath.spline.GetPoint(0f);
                Handles.color = Color.green;
                Handles.DrawLine(lineStart, lineStart + navPath.spline.GetNormal(0));
                for (int j = 1; j <= navPath.pathPositions.Count * navPath.visualQuality; j++)
                {
                    Handles.color = Color.white;
                    Vector3 lineEnd = navPath.spline.GetPoint(j / ((float)navPath.pathPositions.Count * navPath.visualQuality));
                    Handles.DrawLine(lineStart, lineEnd);
                    Handles.color = Color.green;
                    
                    Handles.DrawLine(lineEnd, lineEnd + navPath.spline.GetNormal(j / ((float)navPath.pathPositions.Count * navPath.visualQuality)));
                    lineStart = lineEnd;
                }*/
                for (int i = 0; i < navPath.pathPositions.Count; i++)
                {
                    if (navPath.pathPositions[i] != null)
                    {
                        if (i < navPath.pathPositions.Count - 1)
                        {
                            Handles.color = Color.white;
                            Handles.DrawLine(navPath.pathPositions[i].position, navPath.pathPositions[i + 1].position);

                            Handles.color = Color.blue;
                            if (navPath.pathPositions[i + 1].position - navPath.pathPositions[i].position != Vector3.zero)
                            {
                                Handles.ArrowHandleCap(0, navPath.pathPositions[i].position, Quaternion.LookRotation(navPath.pathPositions[i + 1].position - navPath.pathPositions[i].position), 1f, EventType.Repaint);
                            }
                            else
                            {
                                Handles.ArrowHandleCap(0, navPath.pathPositions[i].position, Quaternion.identity, 1f, EventType.Repaint);
                            }
                        }
                    }
                    if (i == 0)
                        Handles.color = Color.blue;
                    else if (i == navPath.pathPositions.Count - 1)
                        Handles.color = Color.red;
                    else
                        Handles.color = Color.white;
                    if (editingID == i)
                    {
                        if (!editing)
                        {
                            Handles.color = Color.green;
                            Handles.SphereHandleCap(0, navPath.pathPositions[i].position, Quaternion.identity, 0.5f, EventType.Repaint);
                        }
                    }
                    else
                        Handles.SphereHandleCap(0, navPath.pathPositions[i].position, Quaternion.identity, 0.2f, EventType.Repaint);

                }
                if(navPath.pathShape == PathShape.Curve)
                    Handles.DrawWireArc(new Vector3(navPath.pathPositions[1].position.x, -0.2f, navPath.pathPositions[1].position.z + Vector3.Distance(navPath.pathPositions[1].position, navPath.pathPositions[2].position)), navPath.transform.up, navPath.transform.right, 90f, Vector3.Distance(navPath.pathPositions[1].position, navPath.pathPositions[2].position));
            }
            public bool HasFrameBounds() { return true; }

            public Bounds OnGetFrameBounds()
            {
                    return new Bounds(currPosGlobal, Vector3.one * 10);
            }
        }
#endif
        #endregion
    }
}