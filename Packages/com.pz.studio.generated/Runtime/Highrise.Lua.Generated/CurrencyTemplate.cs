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
    [CreateAssetMenu(menuName = "Highrise/ScriptableObjects/CurrencyTemplate")]
    [LuaRegisterType(0x7a20c55a16bad1e8, typeof(LuaScriptableObject))]
    public class CurrencyTemplate : LuaScriptableObjectThunk
    {
        private const string s_scriptGUID = "8b26def9bece48447a02008d370991d2";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public System.String _id = "";
        [LuaScriptPropertyAttribute("876ef6e92558ac34d84b32223b9e4acc")]
        [SerializeField] public UnityEngine.Object _displayData = default;
        [SerializeField] public System.Boolean _stackable = true;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), _id),
                CreateSerializedProperty(_script.GetPropertyAt(1), _displayData),
                CreateSerializedProperty(_script.GetPropertyAt(2), _stackable),
            };
        }
    }
}

#endif