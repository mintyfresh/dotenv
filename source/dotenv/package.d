
module dotenv;

import std.conv;

shared struct Env
{
private static:
    string[string] _cache;

public static:
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

    void readEnv()
    {
        import std.exception;
        import std.process : environment;
        import std.stdio, std.string;

        // Copy the environment first.
        _cache = environment.toAA;

        try
        {
            // Open the .env file if it exists.
            File file = File(".env", "r");
            scope(exit) file.close;

            // Read and store variables.
            foreach(line; file.byLineCopy)
            {
                auto result = line.split("=");
                if(result.length < 2) continue;

                // Convert all names to upper case.
                string name  = result[0].strip.toUpper;
                string value = result[1 .. $].join.strip;

                typeof(this)[name] = value;
            }
        }
        catch(ErrnoException)
        {
            // TODO : Handle this somehow.
            // Dismiss silently for now.
        }
    }

    string[string] opIndex()
    {
        return _cache.dup;
    }

    string opIndex(string name)
    {
        if(string* variable = name in _cache)
        {
            return *variable;
        }

        return null;
    }

    string opIndexAssign(T)(T value, string name)
    {
        return _cache[name] = to!string(value);
    }

    template opDispatch(string name)
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
}

shared static this()
{
    Env.readEnv;
}
