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
    [AddComponentMenu("Lua/CharacterModel")]
    [LuaRegisterType(0xea24f8868577f9d, typeof(LuaBehaviour))]
    public class CharacterModel : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "bc72df88cc229ae4a879abb0c705426e";
        public override string ScriptGUID => s_scriptGUID;

        [LuaScriptPropertyAttribute("64950d21b33740b458a764b749158e4c")]
        [SerializeField] public UnityEngine.Object _fadeHelper = default;
        [SerializeField] public Highrise.Client.Characters.Character _character = default;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), _fadeHelper),
                CreateSerializedProperty(_script.GetPropertyAt(1), _character),
            };
        }
    }
}

#endif
