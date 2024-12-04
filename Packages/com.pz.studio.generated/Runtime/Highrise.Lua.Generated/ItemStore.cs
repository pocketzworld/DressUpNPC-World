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
    [AddComponentMenu("Lua/ItemStore")]
    [LuaRegisterType(0x2be55b4a46fe5fd7, typeof(LuaBehaviour))]
    public class ItemStore : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "90bde850f0274a540806709bbb0c9a6e";
        public override string ScriptGUID => s_scriptGUID;

        [LuaScriptPropertyAttribute("e4857184bfb273d40b3b6f28fe01513a")]
        [SerializeField] public UnityEngine.Object _gameSettings = default;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), _gameSettings),
            };
        }
    }
}

#endif