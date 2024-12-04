using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PolyPerfect.City
{

    public class HeapNode
    {
        public PathNode pathNode;
        public HeapNode[] childrens = new HeapNode[2];
    }
}
