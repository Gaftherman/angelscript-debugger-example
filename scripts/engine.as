int lastHealth;

void healPlayer(Player@ player, uint amount)
{
    string message = "Healing " + player.name;
    print(message); // BP
    player.heal(amount); // BP
    print("Health after healing: " + player.health);
}

void OnPlayerSpawn(Player@ player)
{
    if (player.health < 70)
        healPlayer(player, 5);
    lastHealth = player.health; // BP
}
