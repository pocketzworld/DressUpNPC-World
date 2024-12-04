using System.Collections.Generic;
using System;
using UnityEngine;

namespace PolyPerfect
{
    namespace City
    {
        [Serializable]
        public class Tile : MonoBehaviour
        {
            //Path types that are on this tile. Road includes pathwalks.
            public enum TileType
            {
                RoadAndRail,
                Road,
                Rail,
                OnlyPathwalk
            }
            //Determines how steep tile is and how verticaly is placed.
            public enum VerticalType
            {
                Plane,
                Ramp,
                Tunnel,
                BridgeRamp,
                Bridge
            };
            //Shape of road / rail
            public enum TileShape
            {
                T,
                Cross,
                Straight,
                Turn,
                End,
                Exit,
                ExitOneWay,
                BothSideExit,
                BothSideExitOneWay
            };

            //List of all road/train paths on tile
            [HideInInspector]
            public List<Path> paths;
            //List of all sidewalk paths on tile
            [HideInInspector]
            public List<Path> sidewalkPaths;
            public TileShape tileShape;
            public VerticalType verticalType;
            public TileType tileType = TileType.Road;

            private int id;
            public int Id => id;
            //List of all walkable/driveable tiles in sceen
            public static List<Tile> Tiles = new List<Tile>();
            //Neighbor tiles of this tile
            [HideInInspector]
            public Tile[] NeighborTiles;
            private void Awake()
            {
                //Sets up unique id
                id = IDManager.GetFreeID();

                paths = new List<Path>();
                sidewalkPaths = new List<Path>();
                //Gets all paths from childrens of this gameobject
                foreach (Path navPath in gameObject.GetComponentsInChildren<Path>())
                {
                    navPath.TileId = id;
                    if (navPath.pathType == PathType.Sidewalk)
                    {
                        sidewalkPaths.Add(navPath);
                    }
                    else
                    {
                        paths.Add(navPath);
                    }
                }
                NeighborTiles = GetNeighborTiles();

                //Fixes paths if tile is mirrored
                if(transform.localScale.z < 0)
                {
                    foreach(Path path in paths)
                    {
                        path.pathPositions.Reverse();
                    }
                    foreach (Path path in sidewalkPaths)
                    {
                        path.pathPositions.Reverse();
                    }
                }
            }

            private void Start()
            {
                //Sets up paths that are connected from neighbor tiles for all paths
                UpdatePaths();
            }

            //Updates this tile
            //Call this when you move or add tile in runtime
            public void UpdateTile()
            {
                Tile[] newNeighborTiles = GetNeighborTiles();
                bool changed = false;
                for (int i = 0; i < 4; i++)
                {
                    if(NeighborTiles[i] != newNeighborTiles[i])
                    {
                        changed =true;
                    }
                }
                if (changed)
                {
                    for (int i = 0; i < 4; i++)
                    {
                        if (NeighborTiles[i])
                        {
                            NeighborTiles[i].UpdateNeighbors();
                        }
                        if (newNeighborTiles[i])
                        {
                            newNeighborTiles[i].UpdateNeighbors();
                        }
                    }
                    NeighborTiles = newNeighborTiles;
                    UpdatePaths();
                }
            }
            //Updates this tiles neighbors
            public void UpdateNeighbors()
            {
                NeighborTiles = GetNeighborTiles();
                UpdatePaths();
            }

            private void OnEnable()
            {
                Tiles.Add(this);
                UpdateTile();
            }

            private void OnDisable()
            {
                Tiles.Remove(this);
                foreach (Tile tile in NeighborTiles)
                {
                    if(tile)
                        tile.UpdateNeighbors();
                }
                NeighborTiles = new Tile[4];
            }

            //Gets neighbor tiles from sides of current tile 
            public Tile[] GetNeighborTiles()
            {
                Tile[] NewNeighborTiles = new Tile[4];
                Vector3 topOffset = Vector3.zero;
                Vector3 botttomOffset = Vector3.zero;
                Vector3 rightOffset = Vector3.zero; 
                Vector3 leftOffset = Vector3.zero;
                switch (verticalType)
                {
                    case VerticalType.Plane:
                        break;
                    case VerticalType.Ramp:
                        botttomOffset = new Vector3(0, 6 * transform.lossyScale.y, 0);
                        break;
                    case VerticalType.Tunnel:
                        break;
                    case VerticalType.BridgeRamp:
                        topOffset = new Vector3(0, 6 * transform.lossyScale.y, 0);
                        botttomOffset = new Vector3(0, 12 * transform.lossyScale.y, 0);
                        if (tileShape == TileShape.Turn)
                        {
                            leftOffset = new Vector3(0, 12 * transform.lossyScale.y, 0);
                            botttomOffset = new Vector3(0, 6 * transform.lossyScale.y, 0);
                        }
                        break;
                    case VerticalType.Bridge:

                        topOffset = new Vector3(0, 12 * transform.lossyScale.y, 0);
                        botttomOffset = new Vector3(0, 12 * transform.lossyScale.y, 0);
                        rightOffset = new Vector3(0, 12 * transform.lossyScale.y, 0);
                        leftOffset = new Vector3(0, 12 * transform.lossyScale.y, 0);

                        break;
                }
                Vector3 size = transform.rotation * (transform.lossyScale * 2);
                size.x = Mathf.Abs(size.x);
                size.y = Mathf.Abs(size.y);
                size.z = Mathf.Abs(size.z);

                Collider[] hitsTop = Physics.OverlapBox(gameObject.transform.position + (18 * Mathf.Abs(transform.lossyScale.z) * transform.forward) + topOffset, size);
                Collider[] hitsBottom = Physics.OverlapBox(gameObject.transform.position + (18 * Mathf.Abs(transform.lossyScale.z) * -transform.forward) + botttomOffset, size);
                Collider[] hitsRight = Physics.OverlapBox(gameObject.transform.position + (18 * Mathf.Abs(transform.lossyScale.x) * transform.right) + rightOffset, size);
                Collider[] hitsLeft = Physics.OverlapBox(gameObject.transform.position + (18 * Mathf.Abs(transform.lossyScale.x) * -transform.right) + leftOffset, size);

                NewNeighborTiles[Direction.Top] = GetTile(hitsTop);
                if (tileShape == TileShape.T || tileShape == TileShape.Exit || tileShape == TileShape.ExitOneWay)
                {
                    if (transform.localScale.z < 0)
                    {
                        NewNeighborTiles[Direction.Top] = GetTile(hitsBottom);
                        NewNeighborTiles[Direction.Left] = GetTile(hitsRight);
                        NewNeighborTiles[Direction.Right] = GetTile(hitsLeft);
                    }
                    else
                    {
                        NewNeighborTiles[Direction.Right] = GetTile(hitsRight);
                        NewNeighborTiles[Direction.Left] = GetTile(hitsLeft);
                    }
                }
                else if (tileShape == TileShape.Turn)
                {
                    if (transform.localScale.z < 0)
                    {
                        NewNeighborTiles[Direction.Top] = GetTile(hitsBottom);
                    }
                    NewNeighborTiles[Direction.Left] = GetTile(hitsLeft);
                }
                else if (tileShape == TileShape.Straight)
                {
                    NewNeighborTiles[Direction.Bottom] = GetTile(hitsBottom);
                }
                else if (tileShape == TileShape.Cross || tileShape == TileShape.BothSideExit || tileShape == TileShape.BothSideExitOneWay)
                {
                    NewNeighborTiles[Direction.Bottom] = GetTile(hitsBottom);
                    NewNeighborTiles[Direction.Right] = GetTile(hitsRight);
                    NewNeighborTiles[Direction.Left] = GetTile(hitsLeft);
                }
                return NewNeighborTiles;
            }

            //Updates all paths on this tile
            private void UpdatePaths()
            {
                foreach (Path path in paths)
                {
                    path.nextPaths = GetNextPaths(path.pathPositions[path.pathPositions.Count - 1].position, path.pathType);
                }
                foreach (Path path in sidewalkPaths)
                {
                    path.nextPaths = GetNextPaths(path.pathPositions[path.pathPositions.Count - 1].position, path.pathType);
                }
            }

            //Finds and returns first tile component found in colliders array
            private Tile GetTile(Collider[] colliders)
            {
                foreach (Collider collider in colliders)
                {
                    if(collider.gameObject.TryGetComponent<Tile>(out Tile tile))
                    {
                        return tile;
                    }
                }
                return null;
            }
            //Gets all paths from neighbor tiles that starts up to 1.5m from point
            private List<Path> GetNextPaths(Vector3 point, PathType pathType)
            {
                List<Path> paths = new List<Path>();
                foreach(Tile tile in NeighborTiles)
                {
                    if (tile != null)
                    {
                        if (pathType == PathType.Sidewalk)
                        {
                            foreach (Path path in tile.sidewalkPaths)
                            {
                                if (Vector3.Distance(path.pathPositions[0].position, point) < 1.5f * Mathf.Abs(transform.lossyScale.z))
                                {
                                    paths.Add(path);
                                }
                            }
                        }
                        else
                        {
                            foreach (Path path in tile.paths)
                            {
                                if (Vector3.Distance(path.pathPositions[0].position, point) < 1.5f * Mathf.Abs(transform.lossyScale.z))
                                {
                                    paths.Add(path);
                                }
                            }
                        }
                    }
                }
                return paths;
            }
        }
    }
}
