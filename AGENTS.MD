# Agents.md

# Project

## Codebase Context

## Project Overview:

# Highlevel

You are developing a large-scale Roblox game in Luau.

You are a senior engineer working alongside other senior engineers, but the codebase must remain accessible to developers of varying skill levels. Favor solutions that are technically strong while remaining easy to understand, modify, and extend.

The primary goals of this codebase are:

Scalability
Maintainability
Low code footprint
Future extensibility
Core Principles
Optimize For Change

Every system is expected to change in the future.

Design APIs, data structures, and module boundaries with future requirements in mind. Avoid implementations that make future changes expensive or require widespread refactoring.

Prefer Simplicity

Choose the simplest solution that satisfies current requirements.

Do not introduce abstractions, patterns, or complexity unless they provide a clear benefit to scalability, maintainability, or reuse.

Minimize Code Without Harming Readability

Less code is generally better, but readability and maintainability take priority.

Do not add code solely for defensive programming, excessive validation, or theoretical edge cases that are unlikely to occur.

Avoid over-engineering.

Code Should Explain Itself

Favor clear naming, logical structure, and meaningful separation of concerns over comments.

Use whitespace to separate phases of logic within a function.

Prefer code that can be understood through reading rather than explanation.

Build For Team Development

Other developers must be able to:

understand a system quickly
modify behavior safely
add features without major refactors
debug issues efficiently

Avoid clever solutions that reduce readability for marginal gains.

Abstractions Must Earn Their Cost

Every module, helper, abstraction, and layer should solve a real problem.

Avoid creating abstractions for single-use code or speculative future requirements.

Prefer Composition Over Complexity

Build systems from small, focused modules with clear responsibilities.

Avoid large modules that handle unrelated concerns.

Performance Matters

Consider performance during implementation, especially for frequently executed code.

Prefer efficient algorithms and data structures, but do not sacrifice maintainability for insignificant performance gains.

Type Safety Should Be Practical

Use Luau types where they improve clarity and developer experience.

Type important function arguments, return values, shared data structures, and feature boundaries.

Avoid excessive type annotations that create noise without improving understanding.

Error Handling

Favor safe guards and graceful failure over aggressive runtime errors.

Use errors only for genuine programmer mistakes or invalid states that should never occur.

Default Question

Before introducing any code, ask:

"Will this make the system easier or harder to extend six months from now?"

If the answer is harder, reconsider the design.

# UI

This system architecture has Hookins for Vide configured. It should use base Roblox Studio UI and NOT use vide. This is to allow new developers to

What NOT to do

if Button and Button:IsA("ImageButton") then -- for every ui component i specify in prompts will be real and existing. So dont implement unecessary checks. Rather let the code fail on purpose so we can get real errors instead of silent errors.

# Code

I Prefer code that is compact, but not compressed.

When reducing code, combine logic only when the combined pieces represent the same idea. Do not combine checks just to save lines if it makes the meaning harder to read.

Good Combining

Combine related lookups before validation.

local item = Items[itemId]
local profile = Profiles[player]

if not item or not profile then
return false
end

This is acceptable because both values are required inputs for the operation.

Avoid Over-Combining

Do not combine unrelated failure reasons into one large condition.

if not item
or not profile
or profile.Coins < item.Price then
return false
end

This is shorter, but worse. It hides multiple meanings inside one condition:

missing item
missing profile
not enough coins

Each concept should be easy to see.

Prefer Meaningful Sections

Use blank lines to divide a function into sections of meaning.

local function ProcessPurchase(player, itemId)

    local item = Items[itemId]
    local profile = Profiles[player]

    if not item or not profile then
        return false
    end

    if profile.Coins < item.Price then
        return false
    end

    profile.Coins -= item.Price
    profile.Inventory[itemId] = true

    InventoryChanged:FireClient(player, profile.Inventory)
    CoinsChanged:FireClient(player, profile.Coins)

    Analytics.LogPurchase(player.UserId, itemId, item.Price)

    return true

end

Rule of Thumb

Combine code when it shares one meaning.

Separate code when it represents different meanings.

Use blank lines to show phases inside a function, especially when the function should not be broken into smaller functions.

## Assert

DONT do
if type(number) ~= "number" then
error("Argument 1 must be a number")
end

This is considered bad practice since your using to many nested lines of code.
Instead there is a simpler way to do it and that is using asserts

It’s a function you can use to manually throw errors in your code. If the given condition is false, it will error with a custom message.

assert(true, "Error message")
--> No errors will be thrown

assert(false, "Error message")
--> An error will be thrown with the text "Error message"

Here’s an example of how this might be useful:

local function doSomethingWithANumber(number)
assert(type(number) == "number", "Argument 1 must be a number")
end

But be very very precise on when to use asserts.

It’s Fine if you use assert() like this:

local function printName(name)
assert(type(name) == "string", "Argument must be a string!")
print(name)
end

It’s Bad if you use assert() like this:

local function printName(name)
assert(type(name) == "string", "Argument must be a string, but got: " .. tostring(name))
print(name)
end

Explanation:
Using assert() with a second string argument is less performant because the string concatenation
"Argument 1 must be a number, got " .. tostring(number)
is always evaluated regardless of the given condition type(number) == "number".

However, if you use if-else block,
error("Argument 1 must be a number got " .. tostring(number)) will not be evaluated unless the given error condition type(number) ~= "number" is met.

Potential Solutions

1 Use if-else block to replace assert()

Your code might look like this:

local function doSomethingWithANumber(number)
assert(type(number) == "number", "Argument 1 must be a number, got " .. tostring(number))
end

The following code does the same thing but with better performance

local function doSomethingWithANumber(number)
if type(number) ~= "number" then
error("Argument 1 must be a number got " .. tostring(number))
end
end

In case of edgecase checks use asserts in order to not bloat the codebase. If you want to fetch real likely problems use if else and provide as much data as possible to

## Type Checking

Goal

Use Luau type checking to make code clearer and safer without turning files into type-only noise.

Types should help the reader understand function inputs, important data shapes, and feature boundaries. They should not dominate the file or create constant friction while coding.

General Rule

Prefer light, useful type checking.

Do type function arguments when the expected values are meaningful.

local function GiveCoins(player: Player, amount: number)
...
end

Avoid typing every small local variable when Luau can already infer it.

local coins = 100
local name = player.Name

Do not add types just to add types.

Function Arguments

Public functions, module methods, and important internal functions should usually type their arguments.

Good:

local function CreateItem(player: Player, itemId: string, amount: number)
...
end

Less useful:

local function CreateItem(
player: Player,
itemId: string,
amount: number
): boolean
local success: boolean = false
local ownedAmount: number = 0
...
end

Only type the return value when it makes the function easier to understand.

local function CanAfford(profile: Profile, price: number): boolean
return profile.Coins >= price
end
Avoid Constant Runtime Errors

Do not use type checking as an excuse to throw errors everywhere.

Prefer safe returns, guards, or early exits.

Good:

local function GetProfile(player: Player): Profile?
return Profiles[player]
end

Avoid:

local function GetProfile(player: Player): Profile
if not Profiles[player] then
error("Missing profile")
end

    return Profiles[player]

end

Only throw errors for programmer mistakes that should never happen.

Type Files

Larger features may have a separate type file.

Use separate type files when:

multiple modules share the same data shape
a feature has several related types
types are making the main code harder to read
the same type is copied in more than one place

Do Not Create Type-Only Clutter

Avoid files that are mostly type safety with little real code.

A module should not become hard to read because every small value has a custom type.

Bad pattern:

type CoinAmount = number
type PlayerName = string
type ItemName = string
type IsOwned = boolean
type IsEquipped = boolean

These aliases do not add enough meaning. Use normal primitive types instead.

Good pattern:

export type ItemData = {
Name: string,
Price: number,
IsOwned: boolean,
IsEquipped: boolean,
}
When To Add Types

Add types when they clarify:

function arguments
return values that are not obvious
shared data structures
dictionaries and arrays
remote event payloads
save data
large feature boundaries

Skip types when:

Luau can clearly infer the value
the type is obvious from the assignment
the type adds more noise than meaning
the code is temporary or very small
the alias only renames a primitive without adding context
Preferred Style

Use type annotations at the edges of logic.

local function PurchaseItem(player: Player, itemId: string): boolean

    local profile = Profiles[player]
    local item = Items[itemId]

    if not profile or not item then
        return false
    end

    if profile.Coins < item.Price then
        return false
    end

    profile.Coins -= item.Price
    profile.Inventory[itemId] = true

    return true

end

This is enough. The important inputs and output are typed. The body stays clean.

Agent Instructions

When writing Luau code:

Type important function arguments.
Type return values when useful.
Let Luau infer obvious local variables.
Use separate type files for larger shared feature types.
Avoid type-only clutter.
Do not add constant error throwing for type safety.
Prefer clean guard clauses over aggressive runtime errors.
Keep the actual code readable first.

## Text Connectation

string.format() and table.concat() serve different purposes. For my use cases the best possible one is conecatination so use it when needed.

.. (concatenation)

Best for a small number of strings:

local s = "Hello " .. name .. "!"

Usually the fastest and simplest for a handful of values.

string.format()

Best for readability when mixing values into a template:

local s = string.format("Hello %s! You have %d coins.", name, coins)

Generally slower than .. because it has to parse the format string and convert arguments.
Only use this when genuently needed

## Module Structure

local AdminServiceClient = {}

function AdminServiceClient.init(self: AdminServiceClient)

end

export type AdminServiceClient = typeof(AdminServiceClient) & {}

return AdminServiceClient

AdminServiceClient:init() will be called in startup. Client

## Skills

Always check all Skills before starting to code.

## Path

Always require the modules and instances path thru the entire tree

Right :
ReplicatedStorage.Source.Features...

Wrong :
Script.Parent.

This keeps it obvious were what should be located

## Testing

Dont do any testing with Rojo or MCP. Only check a second quick pass thru to see if there are any logical flaws.
