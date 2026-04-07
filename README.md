[![Alire](https://img.shields.io/endpoint?url=https://alire.ada.dev/badges/elogs.json)](https://alire.ada.dev/crates/elogs.html)

[![image](https://img.shields.io/badge/-inside-darkgreen?logo=ada&logoColor=white&labelColor=grey&logoSize=auto&style=flat-square)](https://ada-lang.io/)
[![Awarded](https://img.shields.io/badge/SPARK_Crate_of_the_Year-2024-darkgreen?style=flat-square)](https://blog.adacore.com/ada-spark-crate-of-the-year-2024-winners-announced) 

# elogs 
Embedded logging absent of runtime errors

A logging package primarily developed for embedded use, including systems   
without exception propagation. Validated to SPARKs Silver level and so is  
proven absent of runtime errors.   

The Log_Store memory occupation is configurable via alire configration   
Max_Log_Count and Max_Message_Length (Bytes) as well as Log_ID_Length (Bytes).   

The size of Log_ID_Length is also configurable by entering the following into   
the alire.toml of any crate that depends on elogs.   

```
[configuration.values]
elogs.Log_ID_Length = 7
```
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
