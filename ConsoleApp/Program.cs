using System.Threading.Tasks;
internal class Program
{
    private static async Task Main(string[] args)
    {
        while(true)
        {
            await Task.Delay(1000);
            Console.WriteLine("Hello, World!");
        }
    }
}