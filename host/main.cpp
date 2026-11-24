#include <adapters/std_host_adapter.h>
#include <as_debugger_host.h>
#include <scriptarray.h>
#include <scriptbuilder.h>
#include <scriptdictionary.h>
#include <scriptmath.h>
#include <scriptstdstring.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <charconv>
#include <chrono>
#include <csignal>
#include <filesystem>
#include <iostream>
#include <memory>
#include <string>
#include <string_view>
#include <thread>
#include <vector>

using namespace std::chrono_literals;
#ifdef AS_USE_NAMESPACE
using namespace AngelScript;
#endif

namespace
{
constexpr char ListenHost[] = "127.0.0.1";
static_assert(std::atomic_bool::is_always_lock_free);
std::atomic_bool running = true;

struct Player
{
    std::string name;
    int health;

    void Heal(asUINT amount)
    {
        health = static_cast<int>(std::min(100LL, static_cast<long long>(health) + amount));
    }
};

std::array<Player, 2> players{{{"Ada", 90}, {"Lin", 65}}};

Player* GetPlayer(asUINT index)
{
    return index < players.size() ? &players[index] : nullptr;
}

void Print(const std::string& message)
{
    std::cout << message << std::endl;
}

void ReportBuildMessage(const asSMessageInfo* message, void*)
{
    const char* kind = message->type == asMSGTYPE_ERROR ? "error" :
                       message->type == asMSGTYPE_WARNING ? "warning" : "info";
    std::cerr << message->section << ':' << message->row << ':' << message->col
              << ": " << kind << ": " << message->message << '\n';
}

bool RegisterBindings(asIScriptEngine* engine)
{
    RegisterStdString(engine);
    RegisterScriptArray(engine, true);
    RegisterScriptDictionary(engine);
    RegisterScriptMath(engine);
    return engine->RegisterGlobalFunction("void print(const string &in)", asFUNCTION(Print), asCALL_CDECL) >= 0 &&
           engine->RegisterObjectType("Player", 0, asOBJ_REF | asOBJ_NOCOUNT) >= 0 &&
           engine->RegisterObjectProperty("Player", "string name", asOFFSET(Player, name)) >= 0 &&
           engine->RegisterObjectProperty("Player", "int health", asOFFSET(Player, health)) >= 0 &&
           engine->RegisterObjectMethod("Player", "void heal(uint)", asMETHOD(Player, Heal), asCALL_THISCALL) >= 0 &&
           engine->RegisterGlobalFunction("Player@ getPlayer(uint)", asFUNCTION(GetPlayer), asCALL_CDECL) >= 0;
}

struct Script
{
    asIScriptModule* module;
    asIScriptFunction* main;
    asIScriptFunction* tick;
    asIScriptFunction* onPlayerSpawn;
};

bool LoadScripts(asIScriptEngine* engine, const std::vector<std::string>& paths, std::vector<Script>& scripts)
{
    for (const auto& path : paths)
    {
        CScriptBuilder builder;
        const std::string moduleName = "script" + std::to_string(scripts.size());
        if (builder.StartNewModule(engine, moduleName.c_str()) < 0 ||
            builder.AddSectionFromFile(path.c_str()) < 0 || builder.BuildModule() < 0)
        {
            std::cerr << "Could not build " << path << '\n';
            return false;
        }

        auto* module = builder.GetModule();
        auto* main = module->GetFunctionByDecl("void main()");
        auto* tick = module->GetFunctionByDecl("void Tick()");
        auto* onPlayerSpawn = module->GetFunctionByDecl("void OnPlayerSpawn(Player@)");
        if (!main && !onPlayerSpawn)
        {
            std::cerr << path << " must define void main() or void OnPlayerSpawn(Player@)\n";
            return false;
        }
        if (!tick && !onPlayerSpawn)
            tick = main;
        scripts.push_back({module, main, tick, onPlayerSpawn});
    }
    return true;
}

bool Execute(asIScriptContext* context, asIScriptFunction* function, Player* player = nullptr)
{
    int result = context->Prepare(function);
    if (result >= 0 && player)
        result = context->SetArgObject(0, player);
    if (result >= 0)
        result = context->Execute();
    if (result == asEXECUTION_EXCEPTION)
    {
        const char* section = nullptr;
        const int line = context->GetExceptionLineNumber(nullptr, &section);
        std::cerr << "Script exception in " << (section ? section : function->GetDeclaration())
                  << ':' << line << ": " << context->GetExceptionString() << '\n';
        return true;
    }
    if (result != asEXECUTION_FINISHED)
    {
        std::cerr << "Could not execute " << function->GetDeclaration() << " (" << result << ")\n";
        return false;
    }
    return true;
}

void Stop(int)
{
    running = false;
}
} // namespace

int main(int argc, char** argv)
{
    int port = 9002;
    bool wait = false;
    bool once = false;
    std::vector<std::string> paths;
    for (int i = 1; i < argc; ++i)
    {
        std::string_view arg = argv[i];
        if (arg == "--help")
        {
            std::cout << "Usage: angelscript-demo [--wait] [--once] [--port N] [script.as ...]\n";
            return 0;
        }
        if (arg == "--wait")
            wait = true;
        else if (arg == "--once")
            once = true;
        else if (arg == "--port")
        {
            const std::string_view value = ++i < argc ? argv[i] : "";
            const auto end = value.data() + value.size();
            const auto [ptr, error] = std::from_chars(value.data(), end, port);
            if (error != std::errc{} || ptr != end || port < 1 || port > 65535)
            {
                std::cerr << "--port requires a number from 1 to 65535\n";
                return 1;
            }
        }
        else if (arg.starts_with('-'))
        {
            std::cerr << "Unknown option " << arg << '\n';
            return 1;
        }
        else
            paths.emplace_back(arg);
    }
    if (paths.empty())
        paths = {"scripts/basic.as", "scripts/advanced.as", "scripts/engine.as"};

    Player spawnedPlayer{"Mira", 65};
    auto releaseEngine = [](asIScriptEngine* engine) { engine->ShutDownAndRelease(); };
    std::unique_ptr<asIScriptEngine, decltype(releaseEngine)> engine(asCreateScriptEngine(), releaseEngine);
    if (!engine || engine->SetMessageCallback(asFUNCTION(ReportBuildMessage), nullptr, asCALL_CDECL) < 0 ||
        engine->SetEngineProperty(asEP_INIT_GLOBAL_VARS_AFTER_BUILD, false) < 0 ||
        !RegisterBindings(engine.get()))
    {
        std::cerr << "Could not initialize the AngelScript engine and bindings\n";
        return 1;
    }

    std::vector<Script> scripts;
    if (!LoadScripts(engine.get(), paths, scripts))
        return 1;

    StdHostAdapter adapter;
    asIDBHostDebugger debugger(engine.get(), adapter, std::filesystem::current_path().generic_string());
    auto releaseContext = [](asIScriptContext* context) { context->Release(); };
    std::unique_ptr<asIScriptContext, decltype(releaseContext)> context(engine->CreateContext(), releaseContext);
    if (!context)
    {
        std::cerr << "Could not create the script context\n";
        return 1;
    }
    if (!debugger.Start(ListenHost, port))
    {
        std::cerr << "Could not listen on " << ListenHost << ':' << port << '\n';
        return 1;
    }
    std::cout << "DAP listening on " << ListenHost << ':' << port << std::endl;
    if (wait)
    {
        std::cout << "Waiting for debugger configuration..." << std::endl;
        if (!debugger.WaitForClient())
            return 1;
    }
    if (!debugger.AttachContext(context.get()))
    {
        std::cerr << "Could not attach the debugger to the script context\n";
        return 1;
    }

    std::signal(SIGINT, Stop);
    // Initializers can call script functions, so run them after the debugger is ready.
    for (const auto& script : scripts)
    {
        if (script.module->ResetGlobalVars(context.get()) < 0)
        {
            debugger.DetachContext(context.get());
            return 1;
        }
    }

    const auto run = [&](bool startup) {
        for (const auto& script : scripts)
        {
            debugger.Poll();
            if (!running)
                break;
            auto* entry = startup ? script.main : script.tick;
            if (entry && !Execute(context.get(), entry))
                return false;
            if (!startup && script.onPlayerSpawn && !Execute(context.get(), script.onPlayerSpawn, &spawnedPlayer))
                return false;
        }
        return true;
    };

    bool ok = run(true);
    while (!once && ok && running)
    {
        std::this_thread::sleep_for(250ms);
        ok = run(false);
    }
    debugger.DetachContext(context.get());
    return ok ? 0 : 1;
}
