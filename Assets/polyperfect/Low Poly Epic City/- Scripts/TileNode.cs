using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PolyPerfect.City
{
    public class TileNode
    {
        public Tile tile;
        public TileNode lastNode;
        public int currentScore = int.MaxValue;
        public int score = int.MaxValue;
    }
}
