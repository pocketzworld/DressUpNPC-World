using UnityEngine;
using UnityEditor;
using UnityEditorInternal;
namespace PolyPerfect.City
{
    [CustomEditor(typeof(CarBehavior))]
    [CanEditMultipleObjects]
    public class CarInspector : Editor
    {
        //Editing properties
        Vector3 currPos;
        int selectedID = 0;
        bool editing = false;
        Color handleColor;

        //ReorderableList with Checkpoints
        ReorderableList reorderableList;

        SerializedProperty m_RandomDestinationProp;
        SerializedProperty m_ClosedCircuitProp;
        SerializedProperty m_MaxSpeedProp;
        SerializedProperty m_MinDistanceProp;
        SerializedProperty m_AccelerationProp;
        SerializedProperty m_RearWheelsMiddlePointProp;
        SerializedProperty m_FrontWheelsMiddlePointProp;
        SerializedProperty m_CheckpointsProp;
        SerializedProperty m_FrontWheelsProp;
        SerializedProperty m_RearWheelsProp;
        SerializedProperty m_MaxTurnAngleProp;
        bool checkpointsFolded = false;

        // Target pointer
        CarBehavior car;
        private void OnEnable()
        {
            car = target as CarBehavior;
            handleColor = new Color(1f, 0.367f, 0.0625f);
            m_RandomDestinationProp = serializedObject.FindProperty("randomDestination");
            m_RearWheelsMiddlePointProp = serializedObject.FindProperty("rearWheelsMiddlePoint");
            m_FrontWheelsMiddlePointProp = serializedObject.FindProperty("frontWheelsMiddlePoint");
            m_ClosedCircuitProp = serializedObject.FindProperty("closedCircuit");
            m_MaxSpeedProp = serializedObject.FindProperty("maxspeed");
            m_MinDistanceProp = serializedObject.FindProperty("minDistance");
            m_AccelerationProp = serializedObject.FindProperty("acceleration");
            m_CheckpointsProp = serializedObject.FindProperty("checkpoints");
            m_FrontWheelsProp = serializedObject.FindProperty("FrontWheels");
            m_RearWheelsProp = serializedObject.FindProperty("RearWheels");
            m_MaxTurnAngleProp = serializedObject.FindProperty("maxTurnAngle");

            reorderableList = new ReorderableList(serializedObject, m_CheckpointsProp, true, true, true, true);
            //ReorderableList callbacks
            reorderableList.onMouseUpCallback = (ReorderableList list) =>
            {
                //Repaint sceen on select
                SceneView.RepaintAll();
            };
            reorderableList.drawElementCallback = (Rect rect, int index, bool isActive, bool isFosused) =>
            {
                EditorGUI.LabelField(new Rect(rect.x, rect.y, EditorGUIUtility.currentViewWidth - 50, EditorGUIUtility.singleLineHeight), (index + 1).ToString() + ".");
                EditorGUI.BeginDisabledGroup(!editing || !isActive);
                m_CheckpointsProp.GetArrayElementAtIndex(index).vector3Value =
                EditorGUI.Vector3Field(new Rect(rect.x + 20, rect.y, EditorGUIUtility.currentViewWidth - 70, EditorGUIUtility.singleLineHeight), GUIContent.none, m_CheckpointsProp.GetArrayElementAtIndex(index).vector3Value);

                EditorGUI.EndDisabledGroup();

                if (isActive)
                {
                    currPos = m_CheckpointsProp.GetArrayElementAtIndex(index).vector3Value;
                    selectedID = index;
                }
            };
            reorderableList.onAddCallback = (ReorderableList list) =>
            {
                m_CheckpointsProp.InsertArrayElementAtIndex(m_CheckpointsProp.arraySize);
                reorderableList.index = m_CheckpointsProp.arraySize - 1;
                reorderableList.DoLayoutList();
            };
            reorderableList.onRemoveCallback = (ReorderableList list) =>
            {
                if (EditorUtility.DisplayDialog("Delete Checkpoint?", "Are you sure you want remove checkpoint?", "Delete", "Cancel"))
                {
                    m_CheckpointsProp.DeleteArrayElementAtIndex(list.index);
                    reorderableList.index = m_CheckpointsProp.arraySize - 1;
                    reorderableList.DoLayoutList();
                }
            };
            reorderableList.drawHeaderCallback = (Rect rect) =>
            {
                EditorGUI.LabelField(rect, "Path Checkpoints");
                bool tmp = editing;
                editing = GUI.Toggle(new Rect(rect.x + (EditorGUIUtility.currentViewWidth / 2), rect.y, (EditorGUIUtility.currentViewWidth / 2) - 50, EditorGUIUtility.singleLineHeight), editing, "Edit", "Button");
                if (tmp != editing)
                {
                    SceneView.RepaintAll();
                }
            };
        }
        public override void OnInspectorGUI()
        {
            serializedObject.Update();
            EditorGUILayout.PropertyField(m_MaxSpeedProp);
            EditorGUILayout.PropertyField(m_AccelerationProp);
            EditorGUILayout.PropertyField(m_MaxTurnAngleProp);
            EditorGUILayout.PropertyField(m_FrontWheelsMiddlePointProp);
            EditorGUILayout.PropertyField(m_FrontWheelsProp);
            EditorGUILayout.PropertyField(m_RearWheelsMiddlePointProp);
            EditorGUILayout.PropertyField(m_RearWheelsProp);
            EditorGUILayout.PropertyField(m_RandomDestinationProp);
            
            if (!m_RandomDestinationProp.boolValue)
            {
                EditorGUILayout.PropertyField(m_ClosedCircuitProp);
                GUIStyle style = EditorStyles.boldLabel;
                style.fixedHeight = 18;
                style.alignment = TextAnchor.MiddleCenter;
                
                checkpointsFolded = EditorGUILayout.BeginFoldoutHeaderGroup(checkpointsFolded,"Checkpoints");
                if (checkpointsFolded)
                {
                    reorderableList.DoLayoutList();
                }
                EditorGUILayout.EndFoldoutHeaderGroup();
            }
            else
            {
                EditorGUILayout.PropertyField(m_MinDistanceProp);
            }
            serializedObject.ApplyModifiedProperties();
        }
        void OnSceneGUI()
        {
            if (editing)
            {
                //Creates position handle for selected checkpoint when in edit mode
                Tools.hidden = true;
                Vector3 newPos = Handles.PositionHandle(currPos, Quaternion.identity);
                if (newPos != currPos)
                {
                    Undo.RegisterCompleteObjectUndo(target, "Changed Checkpoint Position");
                    currPos = newPos;
                    car.checkpoints[selectedID] = currPos;
                    EditorUtility.SetDirty(target);
                }
            }
            else if (checkpointsFolded)
            {
                //Draws arrows at checkpoints position when not editing
                Tools.hidden = false;
                for (int i = 0; i < m_CheckpointsProp.arraySize; i++)
                {
                    if (selectedID != i)
                    {
                        Handles.color = Color.white;
                    }
                    else
                        Handles.color = handleColor;
                    Vector3 checkpointPosition = car.checkpoints[i];
                    Handles.ArrowHandleCap(0, checkpointPosition + (Vector3.up * HandleUtility.GetHandleSize(checkpointPosition)), Quaternion.LookRotation(Vector3.down), HandleUtility.GetHandleSize(checkpointPosition), EventType.Repaint);
                    Handles.Label(checkpointPosition + (Vector3.up * (HandleUtility.GetHandleSize(checkpointPosition) * 1.2f)), (i + 1).ToString(), EditorStyles.boldLabel);

                }

            }
            else
            {
                Tools.hidden = false;
            }
        }
        public bool HasFrameBounds() { return true; }

        public Bounds OnGetFrameBounds()
        {
            if (checkpointsFolded)
                return new Bounds(currPos, Vector3.one * 7);
            else
                return new Bounds(car.transform.position, Vector3.one * 10);
        }
    }
}
