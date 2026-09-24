namespace NativeAPI.Tests;

public class PreferencesTests
{
    [Fact]
    public void NativePreferencesRoundtrip()
    {
        using var preferences = Preferences.CreateWithScope($"nativeapi-csharp-ci-{Guid.NewGuid():N}");
        Assert.NotNull(preferences);
        // NSUserDefaults also enumerates inherited system defaults on macOS.
        var originalSize = preferences.Size;
        try
        {
            Assert.True(preferences.Set("greeting", "Hello 世界"));
            Assert.True(preferences.Contains("greeting"));
            Assert.Equal("Hello 世界", preferences.Get("greeting", "fallback"));
            Assert.Equal(originalSize + 1, preferences.Size);
            Assert.Contains("greeting", preferences.Keys);
            Assert.Equal("Hello 世界", preferences.All["greeting"]);
            Assert.True(preferences.Remove("greeting"));
            Assert.Equal("fallback", preferences.Get("greeting", "fallback"));
            Assert.DoesNotContain("greeting", preferences.Keys);
            Assert.False(preferences.Contains("greeting"));
        }
        finally
        {
            Assert.True(preferences.Clear());
        }
        preferences.Dispose();
        Assert.Equal(0UL, preferences.NativeHandle);
        preferences.Dispose(); // Repeated disposal must not free the handle twice.
    }
}
