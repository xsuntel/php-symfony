# PhpStorm

## Project

### Plugin

* Downloaded
  * PHP Annotations
  * Symfony Plugin
* Database
  * Database Tools and SQL
* HTML and XML
  * HTML Tools
* Javascript Frameworks and Tools
  * Javascript and TypeScript
  * Javascript Debugger
  * Javascript intention Power Pack
  * Nodejs
  * Prettier
* Languages
  * Ini
  * JSON
  * markdown
  * PHP
  * PHP Architecture
  * PHPT Support
  * Shell Script
  * YAML
* SpellChecker
  * Hunspell
* Style Sheet
  * CSS
* Template Languages
  * Twig
* Test Tools
  * PHPSpec BDD Framework
* Version Control
  * Git
* Other Tools
  * PHPStan Support
  * Psalm Support
  * Terminal

### Config

#### Settings

* Disable some configurations

```text
Settings / Appearance & Behavior / System Settings / Autosave / Sync external changes:


Settings / Appearance & Behavior / System Settings / HTTP Proxy
```

* Configure some configurations related Symfony Framework

```text
Settings / PHP / Symfony / Container:

app/var/cache/dev/App_KernelDevDebugContainer.xml
```

> The Container field expects the path to the compiled service-container XML, not a URL.
> The filename derives from the kernel class (default `App\Kernel` → `App_KernelDevDebugContainer.xml`);
> confirm it under `app/var/cache/dev/` after the first `cache:warmup`.

```text
Settings / PHP / Symfony / Routing:

app/var/cache/dev/url_generating_routes.php
```

```text
Settings / PHP / Symfony / Profiler:

HTTP Profiler - https://127.0.0.1:8081
```

#### Menu / Help

* Edit Custom Properties

```text
# Recommended tuned settings
idea.max.content.load.filesize=20000
idea.max.intellisense.filesize=2500
idea.cycle.buffer.size=1024

# VCS file load limit (too large a value causes indexing lag)
idea.max.vcs.loaded.size.kb=20480

# Minimize typing latency (keep)
editor.zero.latency.typing=true

# Rendering optimization on Linux
sun.java2d.pmoffscreen=false
```

* Change Memory Settings

```text
Maximum Heap Size: 8192 MiB
```

* Edit Custom VM Options

```text
# Memory allocation: sized for 16GB RAM (keep -Xmx4096m on 8GB machines)
-Xms2048m
-Xmx8192m
-XX:ReservedCodeCacheSize=512m

# Core GC settings for modern JVMs (G1GC tuning)
-XX:+UseG1GC
-XX:SoftRefLRUPolicyMSPerMB=64
-XX:CICompilerCount=4
-XX:+HeapDumpOnOutOfMemoryError
-XX:-OmitStackTraceInFastThrow
-XX:+IgnoreUnrecognizedVMOptions

# Performance and stability supplements
-XX:+TieredCompilation
-XX:+UseCompressedOops
-XX:+AlwaysPreTouch
-Dsun.io.useCanonCaches=false
-Dsun.java2d.metal=false
-Djava.net.preferIPv4Stack=true
-Dfile.encoding=UTF-8

# Linux/Ubuntu graphics acceleration (adjust to hardware capability)
-Dsun.java2d.opengl=true

# Suppress unnecessary log output (performance)
-XX:-PrintGCDetails
-XX:-PrintFlagsFinal
```

## Reference

* IDE
  * [PhpStorm](https://www.jetbrains.com/phpstorm)
    * Settings
      * PHP
        * Xdebug - [Configuration](https://www.jetbrains.com/help/phpstorm/debugging-with-phpstorm-ultimate-guide.html)
      * Deployment - [Deploying application](https://www.jetbrains.com/help/phpstorm/deploying-applications.html)
      * [Symfony Framework](https://www.jetbrains.com/help/phpstorm/symfony-support.html#use_symfony_cli)
    * Plugin
      * draw.io - [Integration](https://plugins.jetbrains.com/plugin/15635-diagrams-net-integration)
