/*!
**  stmux -- Simple Terminal Multiplexing for Node Environments
**  Copyright (c) 2017 Ralf S. Engelschall <rse@engelschall.com>
**
**  Permission is hereby granted, free of charge, to any person obtaining
**  a copy of this software and associated documentation files (the
**  "Software"), to deal in the Software without restriction, including
**  without limitation the rights to use, copy, modify, merge, publish,
**  distribute, sublicense, and/or sell copies of the Software, and to
**  permit persons to whom the Software is furnished to do so, subject to
**  the following conditions:
**
**  The above copyright notice and this permission notice shall be included
**  in all copies or substantial portions of the Software.
**
**  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
**  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
**  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
**  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
**  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
**  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
**  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

{
    var unroll = options.util.makeUnroll(location, options)
    var ast    = options.util.makeAST   (location, options)
}

split
    =   _ "[" _ dir:directive _ dirs:(_ ":" _ directive)* _ "]" _ {
            return ast("split").set({ vertical: true }).add(unroll(dir, dirs, 3))
        }
    /   _ "[" _ dir:directive _ dirs:(_ ".." _ directive)* _ "]" _ {
            return ast("split").set({ horizontal: true }).add(unroll(dir, dirs, 3))
        }

directive
    =   split
    /   command

command
    =   opts:options? _ cmd:string {
            return ast("command").set({ cmd: cmd.get("value") }).add(opts)
        }

options
    =   f:option l:(_ option)* {
            return unroll(f, l, 1)
        }

option "short or long option"
    =   s:("-f" / "--focus") {
            return ast("option").set({ name: "focus", value: true })
        }
    /   s:("-r" / "--restart") {
            return ast("option").set({ name: "restart", value: true })
        }
    /   "-d" _ a:number {
            return ast("option").set({ name: "delay", value: parseInt(a.get("value")) })
        }
    /   "--delay" (ws / "=") a:number {
            return ast("option").set({ name: "delay", value: parseInt(a.get("value")) })
        }
    /   "-t" _ a:string {
            return ast("option").set({ name: "title", value: a.get("value") })
        }
    /   "--title" (ws / "=") a:string {
            return ast("option").set({ name: "title", value: a.get("value") })
        }

string "quoted string literal or bareword"
    =   "\"" s:((stringEscapedChar / [^"])*) "\"" {
            return ast("string").set({ value: s.join("") })
        }
    /   "'" t:$(("\\'" / [^'])*) "'" {
            return ast("string").set({ value: t.replace(/\\'/g, "'") })
        }
    /   s:$((![\r\n\t\v\f \[\]:.-] .)*) {
            return ast("string").set({ value: s })
        }

stringEscapedChar "escaped string character"
    =   "\\\\" { return "\\"   }
    /   "\\\"" { return "\""   }
    /   "'"    { return "'"    }
    /   "\\b"  { return "\b"   }
    /   "\\v"  { return "\x0B" }
    /   "\\f"  { return "\f"   }
    /   "\\t"  { return "\t"   }
    /   "\\r"  { return "\r"   }
    /   "\\n"  { return "\n"   }
    /   "\\e"  { return "\x1B" }
    /   "\\x" n:$([0-9a-fA-F][0-9a-fA-F]) {
            return String.fromCharCode(parseInt(n, 16))
        }
    /   "\\u" n:$([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) {
            return String.fromCharCode(parseInt(n, 16))
        }

number "numeric literal"
    =   s:$([+-]?) "0b" n:$([01]+) {
            return ast("number").set({ value: parseInt(s + n, 2) })
        }
    /   s:$([+-]?) "0o" n:$([0-7]+) {
            return ast("number").set({ value: parseInt(s + n, 8) })
        }
    /   s:$([+-]?) "0x" n:$([0-9a-fA-F]+) {
            return ast("number").set({ value: parseInt(s + n, 16) })
        }
    /   n:$([+-]? [0-9]* "." [0-9]+ ([eE] [+-]? [0-9]+)?) {
            return ast("number").set({ value: parseFloat(n) })
        }
    /   n:$([+-]? [0-9]+) {
            return ast("number").set({ value: parseInt(n, 10) })
        }

_ "blank"
    =   (co / ws)*

co "comment"
    =   "//" (![\r\n] .)*
    /   "/*" (!"*/" .)* "*/"

ws "whitespaces"
    =   [ \t\r\n]+

