using System;
using NativeAPI;

using var prefs = Preferences.CreateWithScope("nativeapi-example");
if (prefs is null)
{
    Console.Error.WriteLine("Failed to create Preferences.");
    return 1;
}

prefs.Set("greeting", "Hello from C#!");
prefs.Set("launch-count", "42");

Console.WriteLine($"greeting     = {prefs.Get("greeting", "(missing)")}");
Console.WriteLine($"launch-count = {prefs.Get("launch-count", "(missing)")}");
Console.WriteLine($"contains foo = {prefs.Contains("foo")}");

Console.WriteLine("All entries:");
foreach (var (key, value) in prefs.All)
{
    Console.WriteLine($"  {key} = {value}");
}

prefs.Clear();
Console.WriteLine($"After clear: {prefs.All.Count} entries");
return 0;
