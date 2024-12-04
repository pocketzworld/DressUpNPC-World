using System;

namespace PolyPerfect.City
{
    [Serializable]
    public class BinaryHeap
    {

        private PathNode[] Heap;
        private int count;
        public int Count
        {
            get
            {
                return count;
            }
        }
        public BinaryHeap(int size)
        {
            Heap = new PathNode[size +1];
            Heap[0] = new PathNode
            {
                score = -1
            };
            for (int i = 1;i<Heap.Length;i++)
            {
                Heap[i] = new PathNode();
            }
            count = 0;
        }
        
        public void Clear()
        {
            Heap[0].path = null;
            Heap[0].currentScore = int.MaxValue;
            Heap[0].lastNode = null;
            Heap[0].score = -1;
            for (int i = 1; i < count; i++)
            {
                Heap[i].path = null;
                Heap[i].currentScore = int.MaxValue;
                Heap[i].lastNode = null;
                Heap[i].score = int.MaxValue;
            }
            count = 0;
        }

        public void RepairTop()
        {
            int topIndex = 1;
            int child = 2;
            PathNode tmp = Heap[topIndex];
            if(topIndex < count && Heap[child].score > Heap[child+1].score)
            {
                child++;
            }
            while(topIndex <= count && tmp.score > Heap[child].score)
            {
                Heap[topIndex] = Heap[child];
                topIndex = child;
                child *= 2;
                if(child > count)
                {
                    break;
                }
                if (topIndex < count && Heap[child].score > Heap[child + 1].score)
                {
                    child++;
                }
            }
            Heap[topIndex] = tmp;
        }

        public PathNode PopTop()
        {
            if (count == 0)
                return null;
            else
            {
                PathNode topNode = Heap[1];
                if (count != 1)
                {
                    Heap[1] = Heap[count];
                    count--;
                    RepairTop();
                }
                else
                {
                    count--;
                    Heap[1] = new PathNode();
                }
                return topNode;
            }

        }
        public PathNode PeekTop()
        {
            if (count > 0)
                return Heap[1];
            else
                return null;
        }
        public void Insert(PathNode path)
        {
            count++;
            int index = count;
            if (Heap.Length <= count)
            {
                Array.Resize<PathNode>(ref Heap,Heap.Length * 2);
                for (int i = count; i < Heap.Length; i++)
                {
                    Heap[i] = new PathNode();
                }
            }
            while (index != 0 && path.score < Heap[index/2].score)
            {
                Heap[index] = Heap[index / 2];
                index /= 2;
            }
            Heap[index] = path;
        }
      
    }
}
