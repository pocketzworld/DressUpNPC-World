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
    [AddComponentMenu("Lua/ClientChatDispatcher")]
    [LuaRegisterType(0xf3a12f3a54439355, typeof(LuaBehaviour))]
    public class ClientChatDispatcher : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "61ef0aee74211264c905a5e9b57a7847";
        public override string ScriptGUID => s_scriptGUID;


        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
            };
        }
    }
}

#endif
