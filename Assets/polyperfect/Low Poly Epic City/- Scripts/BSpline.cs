using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PolyPerfect.City
{
    [System.Serializable]
    public class BSpline
    {
        public List<Transform> SplinePoints;
        public float splineLength;
        public int degree = 2;
        public float[] knots;
        public float[] derivativeKnots;
        public float[][] derivativeBaseFunctions;
        public float[][] baseFunctions;

        public BSpline(List<Transform> points, int curveDegree)
        {
            SplinePoints = points;
            splineLength = 0;
            /*SplinePoints = new List<Vector3>();
            foreach (Transform transform in points)
            {
                SplinePoints.Add(ref transform.position);
            }*/
            degree = curveDegree;
            InitSpline();
        }

        private void InitSpline()
        {
            if (SplinePoints.Count < 2)
                return;
            
            knots = new float[SplinePoints.Count + degree + 1];
            baseFunctions = new float[degree + 1][];
            derivativeKnots = new float[SplinePoints.Count + degree - 1];
            derivativeBaseFunctions = new float[degree][];
            for (int i = 0; i <= degree; i++)
            {
                baseFunctions[i] = new float[knots.Length - i - 1];
                for (int j = 0; j < baseFunctions[i].Length; j++)
                    baseFunctions[i][j] = -1;
            }
            for (int i = 0; i < degree; i++)
            {
                derivativeBaseFunctions[i] = new float[derivativeKnots.Length - i - 1];
                for (int j = 0; j < derivativeBaseFunctions[i].Length; j++)
                    derivativeBaseFunctions[i][j] = -1;
            }
            for (int i = 0; i < knots.Length; i++)
            {
                if (i < degree)
                    knots[i] = 0;
                else if (i >= knots.Length - degree)
                    knots[i] = 1;
                else
                    knots[i] = (i - degree) / (knots.Length - (2 * degree) - 1.0f);
            }
            for (int i = 0; i < derivativeKnots.Length; i++)
            {
                derivativeKnots[i] = knots[i+1];
            }
            ComputeSplineLenght();
        }

        public void ComputeSplineLenght()
        {
            Vector3 lastPoint = GetPoint(0f); ;
            Vector3 newPoint;
            int h = SplinePoints.Count * 100;
            for (int i = 1; i <= h; i++)
            {
                newPoint = GetPoint(i / (float)h);
                splineLength += Vector3.Distance(lastPoint, newPoint);
                lastPoint = newPoint;
            }
        }

        private float Division(float dividend, float divisor)
        {
            if (divisor == 0)
                return 0;
            return dividend / divisor; 
        }

        private float ComputeBaseFunction(int i, int p, float t,float[][] baseF,float[] _knots)
        {
            if(baseF[p][i] != -1)
            {
                return baseF[p][i];
            }
            
            if (p == 0)
            {
                if ((_knots[i] <= t && t < _knots[i+1])||(_knots[i] <= t && t <= _knots[i + 1] && t == 1))
                    baseF[p][i] = 1;
                else
                    baseF[p][i] = 0;
            }
            else
            {
                baseF[p][i] = (Division(t-_knots[i],_knots[i+p] - _knots[i])*ComputeBaseFunction(i,p-1,t,baseF,_knots)) + (Division(_knots[i + p+1] -t, _knots[i + p+1] - _knots[i+1]) * ComputeBaseFunction(i+1, p - 1, t, baseF,_knots));
            }
            return baseF[p][i];
        }

        public float GetTime(float s)
        {
            float t = 0;
            float h = s / 100;
            float k1, k2, k3, k4;
            for (int i = 0;i<100;i++)
            {
                k1 = h / GetNormal(t).magnitude;
                k2 = h / GetNormal(t+k1/2).magnitude;
                k3 = h / GetNormal(t + k2 / 2).magnitude;
                k4 = h / GetNormal(t+ k3).magnitude;
                t += (k1 + 2 * (k2 + k3) + k4) / 6;
            }
            return t;
        }

        public Vector3 GetPoint(float t)
        {
            
            Vector3 result = new Vector3();
            for (int i = 0; i < SplinePoints.Count; i++)
            {
                ComputeBaseFunction(i, degree, t, baseFunctions, knots);
            }
            for (int i = 0; i < SplinePoints.Count; i++)
            {
                result += SplinePoints[i].position * baseFunctions[degree][i];
            }
            for (int i = 0; i <= degree; i++)
            {
                for (int j = 0; j < baseFunctions[i].Length; j++)
                    baseFunctions[i][j] = -1;
            }
            return result;
        }
        public Vector3 GetNormal(float t)
        {
            Vector3 derivationResult = new Vector3();
            for (int i = 0; i < SplinePoints.Count-1; i++)
            {
                ComputeBaseFunction(i, degree - 1, t, derivativeBaseFunctions, derivativeKnots);
            }
            for (int i = 0; i < SplinePoints.Count-1; i++)
            {
                derivationResult += derivativeBaseFunctions[degree-1][i] * (Division(degree, knots[i+degree+1] - knots[i + 1])* (SplinePoints[i + 1].position - SplinePoints[i].position));
            }
            for (int i = 0; i < degree; i++)
            {
                for (int j = 0; j < derivativeBaseFunctions[i].Length; j++)
                    derivativeBaseFunctions[i][j] = -1;
            }
            return derivationResult;
        }
    }
}