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
    [AddComponentMenu("Lua/CharacterFadeHelper")]
    [LuaRegisterType(0xa30dc2aa688c2f82, typeof(LuaBehaviour))]
    public class CharacterFadeHelper : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "64950d21b33740b458a764b749158e4c";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public UnityEngine.Material _fadeMaterial = default;
        [SerializeField] public System.String _fadeString = "_FadeAlpha";

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), _fadeMaterial),
                CreateSerializedProperty(_script.GetPropertyAt(1), _fadeString),
            };
        }
    }
}

#endif