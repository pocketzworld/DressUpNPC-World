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
    [AddComponentMenu("Lua/UIManager")]
    [LuaRegisterType(0x4420fd164eed93fa, typeof(LuaBehaviour))]
    public class UIManager : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "9f8ffe3cb935f1d499d9b03a579da054";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public UnityEngine.GameObject _nodeUIPrefab = default;
        [SerializeField] public UnityEngine.GameObject _clothingChoiceUIPrefab = default;
        [SerializeField] public UnityEngine.GameObject _dressUpUIPrefab = default;
        [SerializeField] public UnityEngine.GameObject _dialogUIPrefab = default;
        [SerializeField] public UnityEngine.GameObject _rewardUIPrefab = default;
        [SerializeField] public UnityEngine.GameObject _questHudPrefab = default;
        [SerializeField] public UnityEngine.GameObject _contestVotingPrefab = default;
        [SerializeField] public UnityEngine.GameObject _contestPrefab = default;
        [SerializeField] public UnityEngine.GameObject _contestResultsPrefab = default;
        [SerializeField] public UnityEngine.GameObject _genericPopupPrefab = default;
        [SerializeField] public UnityEngine.GameObject _dressUpClosetPrefab = default;
        [SerializeField] public UnityEngine.GameObject _welcomePopupPrefab = default;
        [SerializeField] public UnityEngine.GameObject _itemStoreUIPrefab = default;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), _nodeUIPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(1), _clothingChoiceUIPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(2), _dressUpUIPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(3), _dialogUIPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(4), _rewardUIPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(5), _questHudPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(6), _contestVotingPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(7), _contestPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(8), _contestResultsPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(9), _genericPopupPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(10), _dressUpClosetPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(11), _welcomePopupPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(12), _itemStoreUIPrefab),
            };
        }
    }
}

#endif
