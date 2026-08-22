using System;
using NativeAPI;

var displays = DisplayManager.Shared.GetAll();
Console.WriteLine($"Found {displays.Length} display(s):");
foreach (var display in displays)
{
    using (display)
    {
        Console.WriteLine($"  {display.Name} ({display.Id})");
        Console.WriteLine($"    size:         {display.Size.Width}x{display.Size.Height}");
        Console.WriteLine($"    position:     {display.Position.X},{display.Position.Y}");
        Console.WriteLine($"    work area:    {display.WorkArea.Width}x{display.WorkArea.Height}");
        Console.WriteLine($"    scale factor: {display.ScaleFactor}");
        Console.WriteLine($"    primary:      {display.IsPrimary}");
        Console.WriteLine($"    orientation:  {display.Orientation}");
        Console.WriteLine($"    refresh rate: {display.RefreshRate} Hz");
    }
}

var cursor = DisplayManager.Shared.GetCursorPosition();
Console.WriteLine($"Cursor position: {cursor.X},{cursor.Y}");
