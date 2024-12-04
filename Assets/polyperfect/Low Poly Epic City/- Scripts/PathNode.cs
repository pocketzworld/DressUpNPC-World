namespace PolyPerfect.City
{
    [System.Serializable]
    public class PathNode
    {
        public Path path;
        public PathNode lastNode;
        public float currentScore = float.MaxValue;
        public float score = float.MaxValue;
        
    }
}
