using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditorInternal;
namespace PolyPerfect.City
{
    [CustomEditor(typeof(TrainController))]
    [CanEditMultipleObjects]
    public class TrainInspector : Editor
    {
        //Editing properties
        Vector3 currPos;
        int selectedID = 0;
        bool editing = false;
        Color handleColor;

        //ReorderableList with Checkpoints
        ReorderableList reorderableList;

        //SerializedProperties
        SerializedProperty m_WagonsProp;
        SerializedProperty m_MaxSpeedProp;
        SerializedProperty m_FrontBogieProp;
        SerializedProperty m_RearBogieProp;
        SerializedProperty m_AccelerationProp;
        SerializedProperty m_CheckpointsProp;

        //FoldGroups
        bool wagonsFolded = false;
        bool checkpointsFolded = false;

        // Target pointer
        TrainController train;
        private void OnEnable()
        {
            train = target as TrainController;
            handleColor = new Color(1f,0.367f,0.0625f);
            //Setup properties
            m_WagonsProp = serializedObject.FindProperty("wagons");
            m_MaxSpeedProp = serializedObject.FindProperty("maxspeed");
            m_FrontBogieProp = serializedObject.FindProperty("frontBogie");
            m_RearBogieProp = serializedObject.FindProperty("rearBogie");
            m_AccelerationProp = serializedObject.FindProperty("acceleration");
            m_CheckpointsProp = serializedObject.FindProperty("checkpoints");
            
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
                editing = GUI.Toggle(new Rect(rect.x + (EditorGUIUtility.currentViewWidth /2), rect.y, (EditorGUIUtility.currentViewWidth / 2) - 50, EditorGUIUtility.singleLineHeight ), editing, "Edit", "Button");
                if(tmp != editing)
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
            EditorGUILayout.PropertyField(m_FrontBogieProp);
            EditorGUILayout.PropertyField(m_RearBogieProp);
            //Wagons list
            wagonsFolded = EditorGUILayout.BeginFoldoutHeaderGroup(wagonsFolded,"Wagons");
            if (wagonsFolded)
            {
                GUILayout.BeginVertical();


                for (int i = 0; i < m_WagonsProp.arraySize; i++)
                {

                    EditorGUILayout.BeginVertical(EditorStyles.helpBox, GUILayout.MinHeight(25));
                    GUILayout.Space(2);
                    EditorGUILayout.BeginHorizontal();
                    EditorGUILayout.LabelField((i + 1) + ". Wagon", GUILayout.MinWidth(75));
                    m_WagonsProp.GetArrayElementAtIndex(i).objectReferenceValue = EditorGUILayout.ObjectField(m_WagonsProp.GetArrayElementAtIndex(i).objectReferenceValue, typeof(Wagon), true, GUILayout.MaxWidth(1000), GUILayout.MinWidth(5));
                    //  EditorGUILayout.LabelField(m_WeaponsProp.GetArrayElementAtIndex(i).FindPropertyRelative("weaponName").stringValue);
                    if (GUILayout.Button("-", GUILayout.Width(35)))
                    {
                        m_WagonsProp.DeleteArrayElementAtIndex(i);
                    }

                    EditorGUILayout.EndHorizontal();
                    GUILayout.Space(2);
                    EditorGUILayout.EndVertical();
                }
                if (m_WagonsProp.arraySize == 0)
                    EditorGUILayout.LabelField("List is empty!");
                if (m_WagonsProp.arraySize < 64)
                {
                    GUILayout.Space(15);
                    EditorGUILayout.BeginHorizontal();
                    GUILayout.FlexibleSpace();
                    if (GUILayout.Button("Add wagon slot", "Button", GUILayout.MaxWidth(150)))
                    {
                        m_WagonsProp.InsertArrayElementAtIndex(m_WagonsProp.arraySize);
                        m_WagonsProp.GetArrayElementAtIndex(m_WagonsProp.arraySize - 1).objectReferenceValue = null;
                    }
                    GUILayout.FlexibleSpace();
                    EditorGUILayout.EndHorizontal();
                }
                GUILayout.Space(10);
                GUILayout.EndVertical();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            //Checkpoints reorderableList GUI
            checkpointsFolded = EditorGUILayout.BeginFoldoutHeaderGroup(checkpointsFolded,"Checkpoints");
            if (checkpointsFolded)
            {
                reorderableList.DoLayoutList();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();
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
                    train.checkpoints[selectedID] = currPos;
                    EditorUtility.SetDirty(target);
                }
            }
            else if(checkpointsFolded)
            {
                //Draws arrows at checkpoints position when not editing
                Tools.hidden = false;
                for (int i = 0; i < m_CheckpointsProp.arraySize; i++)
                {
                    if(selectedID != i)
                    {
                        Handles.color = handleColor;
                       
                    }
                    else
                        Handles.color = Color.magenta;
                    Vector3 checkpointPosition = train.checkpoints[i];
                    Handles.ArrowHandleCap(0, checkpointPosition + (Vector3.up * HandleUtility.GetHandleSize(checkpointPosition)), Quaternion.LookRotation(Vector3.down),HandleUtility.GetHandleSize(checkpointPosition), EventType.Repaint);
                    Handles.Label(checkpointPosition + (Vector3.up * (HandleUtility.GetHandleSize(checkpointPosition)*1.2f)), (i + 1).ToString(),EditorStyles.whiteLargeLabel);

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
            if(checkpointsFolded)
                return new Bounds(currPos, Vector3.one*7);
            else
                return new Bounds(train.transform.position, Vector3.one * 10);
        }
    }
}
