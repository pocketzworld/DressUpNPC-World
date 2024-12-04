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
    [CreateAssetMenu(menuName = "Highrise/ScriptableObjects/DressUpTaskRequirementTemplate")]
    [LuaRegisterType(0xce1a8ef59b5b584d, typeof(LuaScriptableObject))]
    public class DressUpTaskRequirementTemplate : LuaScriptableObjectThunk
    {
        private const string s_scriptGUID = "4d4dd9c7c4b0b3642bc19dbde3f6a64a";
        public override string ScriptGUID => s_scriptGUID;

        [LuaScriptPropertyAttribute("0a711aa27721882429f1cfea4a46b58d")]
        [SerializeField] public UnityEngine.Object _dressUpTask = default;
        [SerializeField] public System.Boolean _enteredContest = false;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), _dressUpTask),
                CreateSerializedProperty(_script.GetPropertyAt(1), _enteredContest),
            };
        }
    }
}

#endif
