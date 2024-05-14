# CMake-Premake
## Description
This tool makes it easy to use both CMake and Premake projects by converting CMakeLists.txt files into Premake5.lua files. With this converter, we can use libraries that have a CMake build system in our Premake project.

## How to use this CMake converter

 1. Clone this repository or add this repository as a sub-module to a folder in premake's search path.
 2. Include "**cmake_premake.lua**" file in your premake5 by adding the following lines in the beginning of premake file `local cmake_premake = require "path.to.repo.cmake_premake"`.
 3. To include cmake projects, add `cmake_premake.include_proj(/path/to/cmake_project)` below where you define the workspace.
 4. Then run "**premake5 translate-cmake**"
 5. At last include the project by adding `include 'exported-project-name.lua'` at the end of the premake file
 5. Thats all! Just generate the project now using premake.

### Example Premake file
```lua
-- Include the CMake converter module
local cmake_premake = require "path.to.repo.cmake_premake"

-- Define the workspace
workspace "MyWorkspace"
    configurations { "Debug", "Release" }
    platforms { "x86", "x64" }
    -- Add more configurations and platforms as needed

    -- Include the CMake project
    cmake_premake.include_proj("/path/to/cmake_project")

    -- Define your own projects and settings below
    project "MyProject"
        kind "ConsoleApp"
        language "C++"
        files { "**.cpp", "**.h" }

        -- Additional project settings...

-- Example additional settings and configurations
filter "configurations:Debug"
    defines { "DEBUG" }
    symbols "On"

filter "configurations:Release"
    defines { "NDEBUG" }
    optimize "On"

-- including this afer conversion
include "cmake_project.lua"
```

## Contributing
We welcome any and all contributions! Here are some ways you can get started:

1.  Report bugs: If you encounter any bugs, please let us know. Open up an issue and let us know the problem.
2.  Contribute code: If you are a developer and want to contribute, follow the instructions below to get started!
3.  Suggestions: If you don't want to code but have some awesome ideas, open up an issue explaining some updates or imporvements you would like to see!
4.  Documentation: If you see the need for some additional documentation, feel free to add some!


