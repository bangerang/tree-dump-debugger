import lldb
import os
import shlex
import optparse

@lldb.command("tdump")
def handle_tdump_command(debugger, expression, ctx, result, internal_dict):
    
    res = lldb.SBCommandReturnObject()
    interpreter = debugger.GetCommandInterpreter()

    commands = [
        'e -l swift -- import {}'.format(ctx.target),
        'e -l swift -- import UIKit',
        'e -l swift -- TreeDumpDebugger.present({})'.format(expression),
        'e -l swift -- CATransaction.flush()'
        ]

    for command in commands:
        interpreter.HandleCommand(command, res)
        if res.GetError():
            result.SetError(res.GetError())
            return

    target = debugger.GetSelectedTarget()
    process = target.GetProcess()
    result.SetStatus(lldb.eReturnStatusSuccessContinuingNoResult)
    debugger.SetAsync(True)
    process.Continue()

    

