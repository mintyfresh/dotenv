
module dotenv;

import std.algorithm;
import std.conv;
import std.uni;

/++
 + Stores and accesses loaded environment variables.
 + All environment variables are case-insensitive, and their names are stored in upper case.
 ++/
shared struct Env
{
private static:
    string[string] _cache;

public static:
    void clear()
    {
        _cache = typeof(_cache).init;
    }

    @property
    bool empty()
    {
        return _cache.length == 0;
    }

    @property
    size_t length()
    {
        return _cache.length;
    }

    @property
    const(string[]) keys()
    {
        return _cache.keys;
    }

    @property
    const(string[]) values()
    {
        return _cache.values;
    }

    int opApply(scope int delegate(string) dg)
    {
        foreach(value; _cache)
        {
            if(int result = dg(value))
            {
                return value;
            }
        }

        return 0;
    }

    int opApply(scope int delegate(string, string) dg)
    {
        foreach(key, value; _cache)
        {
            if(int result = dg(key, value))
            {
                return value;
            }
        }

        return 0;
    }

    string[string] opIndex()
    {
        return _cache.dup;
    }

    string opIndex(string name)
    {
        if(string* variable = name.toUpper in _cache)
        {
            return *variable;
        }

        return null;
    }

    string opIndexAssign(T)(T value, string name)
    {
        return _cache[name.toUpper] = to!string(value);
    }

    template opDispatch(string name) if(name.all!(c => c.isUpper || !c.isAlpha))
    {
        @property
        T opDispatch(T = string, Args...)(Args args) if(Args.length == 0)
        {
            if(string variable = typeof(this)[name])
            {
                return to!T(variable);
            }

            return T.init;
        }

        @property
        T opDispatch(T = string, Args...)(Args args) if(Args.length == 1)
        {
            typeof(this)[name] = args[0];

            return args[0];
        }
    }

    bool remove(string name)
    {
        return _cache.remove(name.toUpper);
    }

    /++
     + Loads system environment variables (but not the dotenv file).
     ++/
    void loadSystem()
    {
        import std.process : environment;

        // Copy the environment first.
        foreach(key, value; environment.toAA)
        {
            if(name !in _cache)
            {
                _cache[name] = value;
            }
        }
    }

    /++
     + Copies environment variables, then loads the dotenv file, if present.
     + Variables declared in the .env file will override system environment variables.
     + All variable names are case-insensitive, and are stored as upper case.
     +
     + Params:
     +   handlers   = An optional list of exception handlers.
     +   fileName   = The name of the dovenv file (".env" by default).
     +   copySystem = If true, system environment variables are loaded as well.
     ++/
    void load(handlers...)(string fileName = ".env", bool copySystem = true)
        if(__traits(compiles, {
            Exception e = void;
            foreach(handler; handlers)
            {
                handler(e);
            }
        }))
    {
        import std.exception;
        import std.stdio, std.string;

        try
        {
            // Optionally copy environment.
            if(copySystem) loadSystem;

            // Open the .env file if it exists.
            File file = File(fileName, "r");
            scope(exit) file.close;

            // Read and store variables.
            foreach(line; file.byLineCopy.map!strip)
            {
                // Skip empty lines or line comments.
                if(line.length == 0 || line[0] == "#") continue;

                auto result = line.split("=");
                if(result.length < 1) continue;

                // Convert all names to upper case.
                string name  = result[0].strip.toUpper;
                string value = "";

                if(result.length > 0)
                {
                    // Recostruct the right side of the assignment.
                    value = result[1 .. $].join("=").strip;
                }

                typeof(this)[name] = value;
            }
        }
        catch(Exception e)
        {
            foreach(handler; handlers)
            {
                handler(e);
            }
        }
    }
}
