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
    [AddComponentMenu("Lua/LongPressMiniProfileController")]
    [LuaRegisterType(0x4d22d1b286d9b9de, typeof(LuaBehaviour))]
    public class LongPressMiniProfileController : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "3b891345843bd4507b75132ee0914325";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public Highrise.AudioShader m_longPressSound = default;
        [SerializeField] public System.Double m_raiseHeight = 0.5;
        [SerializeField] public System.Double m_bounceDuration = 0.3;
        [SerializeField] public System.Collections.Generic.List<System.String> m_tappableLayers = default;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), m_longPressSound),
                CreateSerializedProperty(_script.GetPropertyAt(1), m_raiseHeight),
                CreateSerializedProperty(_script.GetPropertyAt(2), m_bounceDuration),
                CreateSerializedProperty(_script.GetPropertyAt(3), m_tappableLayers),
            };
        }
    }
}

#endif