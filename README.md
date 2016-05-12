# dotenv
dotenv implementation for D. Simplifies handling environment variables.

Environment variables are one of the factors of the [12 Factor App](http://12factor.net/). dotenv helps you manage different environments, and extract data that is sensitive or likely to change into environment variables.

## Getting Started

Create a `.env` file at the root directory of your app. An example might look like,

```
# MySQL credentials.
MYSQL_HOST = localhost
MYSQL_PORT = 3306
MYSQL_USER = root
MYSQL_PASS =
```

Variables are declared in `NAME=value` format, and lines starting with '#' are treated as comments.

### Loading Env

Once you've created your file, it can be loaded using `Env.load`. `Env.load` also takes additional arguments if you need to customize its behaviour.

```d
import dotenv;

void main()
{
    // Loads the .env file
    Env.load;

    // Loads from a different file name
    Env.load(".my-env");

    // Do not load system environment variables
    Env.load(".env", false);

    // Load only system environment variables
    Env.loadSystem;
}
```

By default, `Env` will also load the system environment variables. Multiple calls to `Env.load` can be made to load multiple dotenv files. If multiple variables are loaded under the same name, the newer value will override the previous one.

### Accessing Variables

Once loaded, `Env` behaves like an associative-array. Variables are accessed by name (and are case-insensitive), and their values returned as strings.

```d
Connection connectDB()
{
    return new Connection(
        Env["MYSQL_HOST"], Env["MYSQL_PORT"],
        Env["MYSQL_USER"], Env["MYSQL_PASS"]
    );
}
```

`Env` also provides property-like access (using opDispatch) to variables, but only to their uppercase names. The properties also accept an optional template argument, to perform a type conversion.

```d
void dbInfo()
{
    string host = Env.MYSQL_HOST;
    ushort port = Env.MYSQL_PORT!ushort;

    // . . .
}
```

### Modifying Variables

Since `Env` behaves like an associative-array, it can also be modified in much the same way.

```d
unittest
{
    Env.load(".test-env");

    Env["MYSQL_USER"] = "test_user";
    Env.remove("MYSQL_PASS");

    // . . .
}
```

It also provides `empty`, `length`, `keys`, and `values` properties that behave as expected.

### Different Environments

dotenv is great for managing different environments. For example, if you have a local development environment where you needed to load your configuration exclusively from `.env`, and a remote production environment where there is no `.env` file, but only system environment variables, you could do something like,

```d
import dotenv;

shared static this()
{
    // Try to load .env file without system variables.
    Env.load!((e) {
        import std.exception : ErrnoException;

        if(cast(ErrnoException) e)
        {
            // .env file was not found, load system.
            Env.loadSystem;
        }
    })(".env", false);
}
```

`Env.load` takes optional callback functions (which must be callable with an Exception object as a parameter), to which any exceptions throw during initialization are forwarded. Here we check if it was an `ErrnoException`, and assume that if it is, no `.env` file was found, and that we're not in our local development environment.

## Planned Features

  - Support for JSON/SDLang dotenv files, for more complex variables
  - More customization during initialization

## License

MIT
