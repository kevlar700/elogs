# elogs
Embedded logging absent of runtime errors

A logging package primarily developed for embedded use, including systems
without exception propagation. Validated to SPARKs Silver level and
so is proven absent of runtime errors. The Log_Store memory occupation
is configurable via alire configration variables Max_Log_Count *
Max_Message_Length. Although a managed or ragged array or container may
provide more efficient use of memory. Utilising a fixed length String
store results in simplifying the use of SPARK.
