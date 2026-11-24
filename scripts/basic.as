int addBonus(int score, int bonus)
{
    return score + bonus; // BP
}

string formatProgress(int score)
{
    string prefix = "Total: "; // BP
    return prefix + score;
}

void showProgress(bool announce)
{
    int total = startingScore;
    float multiplier = 1.5f;
    bool hasBonus = multiplier > 1.0f;
    for (int round = 1; round <= 3; ++round)
    {
        total += round; // BP
    }
    total = addBonus(total, hasBonus ? 2 : 0); // BP
    string message = formatProgress(total); // BP
    if (announce)
    {
        print("Points earned: " + (total - startingScore));
        print(message);
    }
}

void main()
{
    print("Starting score: " + startingScore);
    showProgress(true);
}

void Tick()
{
    showProgress(false);
}

const int startingScore = 1;
