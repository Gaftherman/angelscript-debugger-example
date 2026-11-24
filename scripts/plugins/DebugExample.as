// A small plugin with three runtime errors for the debugger to catch.
// Set a breakpoint (F9) on any line marked BREAK HERE, attach (F5), then run the map.

array<int> g_Scores = { 10, 20, 30 };
CBasePlayer@ g_pLastPlayer = null;

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( "Example" );
    g_Module.ScriptInfo.SetContactInfo( "https://github.com/Gaftherman/angelscript-debugger-example" );

    g_Scheduler.SetInterval( "CheckScores", 3.0f, g_Scheduler.REPEAT_INFINITE_TIMES );
}

// Error 1: index out of range. The array has 3 items, index 3 does not exist.
void CheckScores()
{
    int index = 3;
    int score = g_Scores[index]; // BREAK HERE: watch "index" and "g_Scores" in the Variables pane
    g_Game.AlertMessage( at_console, "Score: " + score + "\n" );
}

// Error 2: null handle. g_pLastPlayer is never assigned, so reading a member throws.
void ShowLastPlayer()
{
    string name = g_pLastPlayer.pev.netname; // BREAK HERE: g_pLastPlayer shows as null
    g_Game.AlertMessage( at_console, "Last player: " + name + "\n" );
}

// Error 3: division by zero.
int AveragePerPlayer( int total, int players )
{
    return total / players; // BREAK HERE: call it with players = 0
}
