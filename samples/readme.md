# How to run sample
- Run "cmd.exe"
- Type "sh_exec_<debug|release>.exe <project_config_filename>.json"
- Press Enter

# Project configuration file
| Field Name | Description |
| - | - |
| args | [in] Command line argumets for program |
| project | [in] Program source file |
| immediate | [out] Immediate file ("" - don't create) |
| report | [out] Report file ("" - don't create) |
| execute | [in] The name of the user-defined function to be executed |
| pressanykey | [in] true - wait user input before close console |

# Immediate files

Special keyword "IMMEDIATE" is for mark file as an entire program already prepared for compiling and execution. It is how looks project source code after preprocessor. It is not contains any includes, macros definitions or unexpanded macros calls, labels or user function names (global names keeps present). This is exactly the form of program text that can be encoded in binary format and executed by the interpreter:

| Source | Immediate |
| - | - |
| `func loop L:2 S:4` | `FUNC LOOP LOCAL:2 STACK:4` |
| ` mov 1 .L0       ` | ` MOV 1 .L0               ` |
| ` mov 0 .L1       ` | ` MOV 0 .L1               ` |
| `  :begin         ` | ` PUSH .L0 100000         ` |
| ` push .L0 100000 ` | ` JN INT <= 9             ` |
| ` jn int <= :end  ` | ` PUSH .L1 .L0            ` |
| ` push .L1 .L0    ` | ` IADD                    ` |
| ` iadd            ` | ` POP .L1                 ` |
| ` pop .L1         ` | ` INC .L0 1               ` |
| ` inc .L0 1       ` | ` JUMP 2                  ` |
| ` jump :begin     ` | ` PUSH .L1 0              ` |
| `  :end           ` | ` CALL %PRINTL            ` |
| ` push .L1 0      ` | ` RET                     ` |
| ` call %printl    ` | `END FUNC                  ` |
| ` ret             ` | `` |
| `end func         ` | `` |

# Samples list
- Hello, World! (helloworld.json)
~~~
// Simple scenario where program asks username and then print "Hello, <username>!"
~~~
- Loop (simpleloop.json)
~~~
s := 0;
for i=1 to 100000 do s := s + i;
~~~
- Loop With Branch (loopwithbranch.json) 
~~~
s1 := 0.0;
s2 := 0.0;
for i:=1 to 100000 do
 if i mod 2 = 0
  then s1 := s1 + i / 1.33
  else s2 := s2 + i div 3;
s1 := s1 + s2;
~~~
