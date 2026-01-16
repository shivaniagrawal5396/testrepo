using System.Diagnostics;

Console.WriteLine("🚀 Hello from .NET 10!");

var stopwatch = Stopwatch.StartNew();
await Task.Delay(500);
stopwatch.Stop();

Console.WriteLine($"Execution time: {stopwatch.ElapsedMilliseconds} ms");

// Example of modern pattern usage
int number = Random.Shared.Next(1, 100);

string result = number switch
{
    < 50 => "Less than 50",
    50 => "Exactly 50",
    > 50 => "Greater than 50"
};
//test.1.0.0 comment
Console.WriteLine($"Number: {number} → {result}");
