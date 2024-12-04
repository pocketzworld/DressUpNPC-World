public static class IDManager
{
    private static int currentID = 0;

    public static int GetFreeID()
    {
        return ++currentID;
    }
}
