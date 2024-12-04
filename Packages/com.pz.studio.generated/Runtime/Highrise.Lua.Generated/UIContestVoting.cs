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
    [AddComponentMenu("Lua/UIContestVoting")]
    [LuaRegisterType(0x5518429a555f179a, typeof(LuaBehaviour))]
    public class UIContestVoting : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "ff149c691d6989d45ad75670c3d57722";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public UnityEngine.Transform _cameraTarget = default;
        [SerializeField] public UnityEngine.GameObject _fxToPlayPrefab = default;
        [SerializeField] public Highrise.Client.Characters.Character _leftNPCCharacter = default;
        [SerializeField] public UnityEngine.Transform _leftFXAnchor = default;
        [SerializeField] public UnityEngine.Sprite _starSprite = default;
        [SerializeField] public Highrise.Client.Characters.Character _rightNPCCharacter = default;
        [SerializeField] public UnityEngine.Transform _rightFXAnchor = default;
        [SerializeField] public System.Double _starSequenceDuration = 2;
        [SerializeField] public System.Double _cameraZoomWaitTime = 0.5;
        [SerializeField] public System.Double _delayAfterSmokeToChange = 0.25;
        [SerializeField] public System.Double _floatTicketHeight = 10;
        [SerializeField] public System.Double _floatTicketTime = 2;
        [SerializeField] public Highrise.AudioShader _smokeSound = default;
        [SerializeField] public Highrise.AudioShader _votedSound = default;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), null),
                CreateSerializedProperty(_script.GetPropertyAt(1), null),
                CreateSerializedProperty(_script.GetPropertyAt(2), null),
                CreateSerializedProperty(_script.GetPropertyAt(3), null),
                CreateSerializedProperty(_script.GetPropertyAt(4), null),
                CreateSerializedProperty(_script.GetPropertyAt(5), null),
                CreateSerializedProperty(_script.GetPropertyAt(6), null),
                CreateSerializedProperty(_script.GetPropertyAt(7), null),
                CreateSerializedProperty(_script.GetPropertyAt(8), null),
                CreateSerializedProperty(_script.GetPropertyAt(9), null),
                CreateSerializedProperty(_script.GetPropertyAt(10), _cameraTarget),
                CreateSerializedProperty(_script.GetPropertyAt(11), _fxToPlayPrefab),
                CreateSerializedProperty(_script.GetPropertyAt(12), _leftNPCCharacter),
                CreateSerializedProperty(_script.GetPropertyAt(13), _leftFXAnchor),
                CreateSerializedProperty(_script.GetPropertyAt(14), _starSprite),
                CreateSerializedProperty(_script.GetPropertyAt(15), _rightNPCCharacter),
                CreateSerializedProperty(_script.GetPropertyAt(16), _rightFXAnchor),
                CreateSerializedProperty(_script.GetPropertyAt(17), _starSequenceDuration),
                CreateSerializedProperty(_script.GetPropertyAt(18), _cameraZoomWaitTime),
                CreateSerializedProperty(_script.GetPropertyAt(19), _delayAfterSmokeToChange),
                CreateSerializedProperty(_script.GetPropertyAt(20), _floatTicketHeight),
                CreateSerializedProperty(_script.GetPropertyAt(21), _floatTicketTime),
                CreateSerializedProperty(_script.GetPropertyAt(22), _smokeSound),
                CreateSerializedProperty(_script.GetPropertyAt(23), _votedSound),
            };
        }
    }
}

#endif
