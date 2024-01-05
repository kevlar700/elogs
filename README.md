# elogs
Embedded logging absent of runtime errors

A logging package primarily developed for embedded use, including systems   
without exception propagation. Validated to SPARKs Silver level and so is  
proven absent of runtime errors.   

The Log_Store memory occupation is configurable via alire configration   
variables Max_Log_Count * Max_Message_Length (bytes).   

Although a managed or ragged array or container may provide more efficient   
use of memory. Utilising a fixed length String store results in simplifying   
the use of SPARK.   

An interesting feature of this package is that there are very few Pre and Post   
conditions enabling the SPARK proving. Instead the type system intuitively   
provides most of the information to gnatprove automatically and gnatprove made   
a few pointers for consideration. Aside from annotating package global variable   
use. Very few changes were required such as re-ordering a calculation to avoid   
any chance of overflow. This has convinced me that the use of SPARK is a far  
less daunting prospect than I had expected and a tool that can be used generally   
upto silver level with less commitment than I had realised, enabled by Adas   
excellent type system.
