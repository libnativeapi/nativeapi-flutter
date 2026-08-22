using System;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

namespace CNativeAPI;

/// <summary>
/// Resolves the "nativeapi" native library. The NATIVEAPI_LIBRARY_PATH
/// environment variable, when set, takes precedence over the default .NET
/// probing paths.
/// </summary>
internal static class NativeLibraryResolver
{
    [ModuleInitializer]
    internal static void Register()
    {
        NativeLibrary.SetDllImportResolver(typeof(NativeLibraryResolver).Assembly, Resolve);
    }

    private static IntPtr Resolve(string libraryName, Assembly assembly, DllImportSearchPath? searchPath)
    {
        if (libraryName != Libraries.NativeApi)
        {
            return IntPtr.Zero;
        }
        var overridePath = Environment.GetEnvironmentVariable("NATIVEAPI_LIBRARY_PATH");
        if (!string.IsNullOrEmpty(overridePath) && NativeLibrary.TryLoad(overridePath, out var handle))
        {
            return handle;
        }
        // IntPtr.Zero falls back to the default probing behaviour.
        return IntPtr.Zero;
    }
}
