import std/[logging]
export logging

var logger* = newConsoleLogger()
var consoleLog = newConsoleLogger()
addHandler(consoleLog)