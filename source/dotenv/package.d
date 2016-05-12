
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

    template opDispatch(string name) if(name.all!isUpper)
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
        return _cache.remove(name);
    }

    /++
     + Copies environment variables, then loads the dotenv file, if present.
     + Variables declared in the .env file with override system environment variables.
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
        import std.process : environment;
        import std.stdio, std.string;

        try
        {
            if(copySystem)
            {
                // Copy the environment first.
                _cache = environment.toAA;
            }

            // Open the .env file if it exists.
            File file = File(fileName, "r");
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
        catch(Exception e)
        {
            foreach(handler; handlers)
            {
                handler(e);
            }
        }
    }
}
