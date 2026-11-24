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
    int total = 1;
    float multiplier = 1.5f;
    bool hasBonus = multiplier > 1.0f;
    for (int round = 1; round <= 3; ++round)
    {
        total += round; // BP
    }
    total = addBonus(total, hasBonus ? 2 : 0); // BP
    string message = formatProgress(total); // BP
    if (announce)
        print(message);
}

void main()
{
    showProgress(true);
}

void Tick()
{
    showProgress(false);
}
