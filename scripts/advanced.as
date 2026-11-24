interface Named
{
    string label() const;
}

class Character : Named
{
    string name = "Rook";

    string label() const
    {
        return name;
    }
}

class Scout : Character
{
    int rank = 3;
}

funcdef int ScoreCallback(int);

int factorial(int number)
{
    if (number <= 1)
        return 1;
    return number * factorial(number - 1); // BP
}

void inspectParty(bool announce)
{
    Scout@ scout = Scout();
    Named@ leader = scout;
    array<int> scores = {8, 13, 21};
    array<Player@> party = {getPlayer(0), getPlayer(1)};
    dictionary stats;
    stats.set("round", int64(2));
    stats.set("leader", leader.label());
    ScoreCallback@ callback = @factorial;
    int result = callback(3); // BP
    if (announce)
        print(leader.label() + " scored " + result + " with " + party[0].name);
}

void demonstrateException()
{
    array<int> scores = {8, 13, 21};
    int invalidIndex = int(scores.length());
    print("Score: " + scores[invalidIndex]); // BP
}

void main()
{
    inspectParty(true);
    demonstrateException();
}

void Tick()
{
    inspectParty(false);
}
