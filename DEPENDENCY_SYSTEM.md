# Module Dependency System

The ClientLoader and ServerLoader now support a dependency system that ensures modules are loaded in the correct order based on their dependencies.

## How to Use

### Adding Dependencies to a Module

To specify that your module depends on other modules, add a `Dependencies` table at the top of your module:

```lua
local MyModule = {}

MyModule.Dependencies = {
    "ModuleA",
    "ModuleB"
}

-- Rest of your module code...

function MyModule.Setup()
    -- Your setup code here
end

return MyModule
```

### Example

```lua
local Shop = {}

Shop.Dependencies = {
    "Menu"
}

-- Shop will only be loaded after Menu has been loaded and set up
```

## How It Works

1. **Collection**: The system scans all specified folders for modules with `Setup` functions
2. **Dependency Resolution**: Uses topological sorting to determine the correct load order
3. **Loading**: Modules are loaded in dependency order, ensuring dependencies are available when needed

## Features

- **Circular Dependency Detection**: The system will error if circular dependencies are detected
- **Missing Dependency Warnings**: Warns if a module depends on a non-existent module
- **Shared Logic**: Both ClientLoader and ServerLoader use the same LoadingUtility module

## Files

- `src/shared/Utility/LoadingUtility.lua` - Core dependency resolution logic
- `src/client/ClientLoader.lua` - Client-side module loader
- `src/server/ServerLoader.lua` - Server-side module loader

## Error Handling

- If a module fails to require, a warning is printed and loading continues
- If a module's Setup function fails, a warning is printed and loading continues
- Circular dependencies will cause an error and stop the loading process

## Testing

Run `test_dependencies.lua` to see a demonstration of the dependency resolution system.