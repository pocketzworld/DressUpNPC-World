/*

    Copyright (c) 2024 Pocketz World. All rights reserved.

    This is a generated file, do not edit!

    Generated by com.pz.studio
*/

#if UNITY_EDITOR

using System;
using System.Linq;
using UnityEngine;
using Highrise.Client;
using Highrise.Studio;
using Highrise.Lua;

namespace Highrise.Lua.Generated
{
    [AddComponentMenu("Lua/DressUpCamera")]
    [LuaRegisterType(0x1616a1c31f6cf5f6, typeof(LuaBehaviour))]
    public class DressUpCamera : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "0cb67e544cbf3b74a97a770b1dd6895c";
        public override string ScriptGUID => s_scriptGUID;

        [Header("Zoom Settings")]
        [SerializeField] public System.Double m_zoom = 15;
        [SerializeField] public System.Double m_zoomMin = 10;
        [SerializeField] public System.Double m_zoomMax = 50;
        [SerializeField] public System.Double m_fov = 30;
        [Header("Defaults")]
        [SerializeField] public System.Boolean m_allowRotation = true;
        [SerializeField] public System.Double m_pitch = 30;
        [SerializeField] public System.Double m_yaw = 45;
        [SerializeField] public System.Boolean m_centerOnCharacterWhenSpawned = true;
        [Tooltip("0 means no centering, as you approach 1 the centering will get faster, 1 means immediate centering")]
        [Range(0,1)]
        [SerializeField] public System.Double m_centerOnCharacterWhenMovingSpeed = 0;
        [LuaScriptPropertyAttribute("51c49f8bf92d2604c9e3fa1c12320a1c")]
        [SerializeField] public UnityEngine.Object _defaultCameraCutsceneSettings = default;
        [SerializeField] public System.Double _panToTargetCenterTime = 2;
        [SerializeField] public System.Boolean m_keepPlayerInView = false;
        [SerializeField] public System.Double m_keepPlayerInViewPanDuration = 0.5;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), m_zoom),
                CreateSerializedProperty(_script.GetPropertyAt(1), m_zoomMin),
                CreateSerializedProperty(_script.GetPropertyAt(2), m_zoomMax),
                CreateSerializedProperty(_script.GetPropertyAt(3), m_fov),
                CreateSerializedProperty(_script.GetPropertyAt(4), m_allowRotation),
                CreateSerializedProperty(_script.GetPropertyAt(5), m_pitch),
                CreateSerializedProperty(_script.GetPropertyAt(6), m_yaw),
                CreateSerializedProperty(_script.GetPropertyAt(7), m_centerOnCharacterWhenSpawned),
                CreateSerializedProperty(_script.GetPropertyAt(8), m_centerOnCharacterWhenMovingSpeed),
                CreateSerializedProperty(_script.GetPropertyAt(9), _defaultCameraCutsceneSettings),
                CreateSerializedProperty(_script.GetPropertyAt(10), _panToTargetCenterTime),
                CreateSerializedProperty(_script.GetPropertyAt(11), m_keepPlayerInView),
                CreateSerializedProperty(_script.GetPropertyAt(12), m_keepPlayerInViewPanDuration),
            };
        }
    }
}

#endif
