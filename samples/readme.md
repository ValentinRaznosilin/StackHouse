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

Special keyword "IMMEDIATE" is for mark file as an entire program already prepared for compiling and execution. It is how looks project source code after preprocessor. It is not contains any includes, macros definitions or unexpanded macros calls, labels or user function names (global names keeps present). This is exactly the form of program text that can be encoded in binary format and executed by the interpreter.

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
- Loop With Branch 
~~~
s1 := 0.0;
s2 := 0.0;
for i:=1 to 100000 do
 if i mod 2 = 0
  then s1 := s1 + i / 1.33
  else s2 := s2 + i div 3;
s1 := s1 + s2;
~~~