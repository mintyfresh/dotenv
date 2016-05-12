
module dotenv;

import std.conv;

shared struct Env
{
private static:
    string[string] _cache;

public static:
    void readEnv()
    {
        version(EnvFile)
        {
            import std.stdio, std.string;

            File file = File(".env", "r");
            scope(exit) file.close;

            foreach(line; file.byLineCopy)
            {
                auto result = line.split("=");
                if(result.length < 2) continue;

                string name  = result[0].strip.toUpper;
                string value = result[1 .. $].join.strip;

                typeof(this)[name] = value;
            }
        }
        else
        {
            import std.process : environment;

            _cache = environment.toAA;
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
