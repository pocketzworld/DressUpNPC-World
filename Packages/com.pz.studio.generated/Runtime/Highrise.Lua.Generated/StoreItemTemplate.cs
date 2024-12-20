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
    [CreateAssetMenu(menuName = "Highrise/ScriptableObjects/StoreItemTemplate")]
    [LuaRegisterType(0x83cba23a01c98c53, typeof(LuaScriptableObject))]
    public class StoreItemTemplate : LuaScriptableObjectThunk
    {
        private const string s_scriptGUID = "012b2e69a916e624f82cc45810d0b5cd";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public System.String _id = "";
        [LuaScriptPropertyAttribute("d7af9898d0cf28149a4d5ee966f20672")]
        [SerializeField] public UnityEngine.Object _clothingCollectionRewardTemplate = default;
        [LuaScriptPropertyAttribute("876ef6e92558ac34d84b32223b9e4acc")]
        [SerializeField] public UnityEngine.Object _displayData = default;
        [SerializeField] public System.Double _cost = 0;
        [LuaScriptPropertyAttribute("8b26def9bece48447a02008d370991d2")]
        [SerializeField] public UnityEngine.Object _currencyCostTemplate = default;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), _id),
                CreateSerializedProperty(_script.GetPropertyAt(1), _clothingCollectionRewardTemplate),
                CreateSerializedProperty(_script.GetPropertyAt(2), _displayData),
                CreateSerializedProperty(_script.GetPropertyAt(3), _cost),
                CreateSerializedProperty(_script.GetPropertyAt(4), _currencyCostTemplate),
            };
        }
    }
}

#endif
