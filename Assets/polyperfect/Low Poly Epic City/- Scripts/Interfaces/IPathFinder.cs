using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PolyPerfect.City
{
    public interface IPathFinder
    {
        List<Path> GetPath(Vector3 vector);
    }
}
