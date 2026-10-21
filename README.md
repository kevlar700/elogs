
![image](https://img.shields.io/endpoint?url=https://alire.ada.dev/badges/elogs.json)


![image](https://img.shields.io/badge/-inside-darkgreen?logo=ada&logoColor=white&labelColor=grey&logoSize=auto&style=flat-square)

![image](https://img.shields.io/badge/SPARK_Crate_of_the_Year-2024-darkgreen?style=flat-square)

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
elogs.Log_ID_Length = 16
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

#### Example Usage

```

   type Status_Code is
     (Status_OK,
      Status_SPI_Timeout,
      Status_RCC_Timeout,
      Exception_Overflow);
      
   package Locus is
   
      subtype Example is Status_Code
        with Static_Predicate => Read_Register in Status_SPI_Timeout | Exception_Overflow | Status_OK;

      subtype Read_Register is Status_Code
        with Static_Predicate => Read_Register in Status_SPI_Timeout | Status_OK;
   end Locus;


   Procedure Example (Example_Status : out Locus.Example) is
      type Readable_ID is record
         Wafer_Coordinate_X : Unsigned_16 := 0;
         Wafer_Coordinate_Y : Unsigned_16 := 0;
         Wafer_Number       : Unsigned_8 := 0;
         Lot_Number         : String (1 .. 7) := [others => ' '];
      end record
      with
        Object_Size        => 96,
        Size               => 96,
        Bit_Order          => System.Low_Order_First,
        Universal_Aliasing => True;
      --  Universal_Aliasing removes the warning "unchecked conversion
      --  implemented by copy"

      for Readable_ID use
        record
          Wafer_Coordinate_X at 0 range 0 .. 15;
          Wafer_Coordinate_Y at 0 range 16 .. 31;
          Wafer_Number       at 0 range 32 .. 39;
          Lot_Number         at 0 range 40 .. 95;
        end record;

      function To_Bytes is new
        Ada.Unchecked_Conversion (Readable_ID, Elogs.Device_ID_Bytes);

      Device_ID : constant Readable_ID :=
        (Wafer_Coordinate_X => 16#FFFF#,
         Wafer_Coordinate_Y => 16#E1E1#,
         Wafer_Number       => 177,
         Lot_Number         => "1234567");
         
         Byte : Unsigned_8;
         
   begin
   
      Elogs.Initialise
        (Software_Version  => SW_Version,
         Device_ID         => To_Bytes (Device_ID),
         Additional_Logger => GNAT.IO.Put_Line'Access));
         
         declare
               Status : Locus.Read_Register;
         begin
             Read_Register (Byte, Status);
             
             case Status is
               when Status_SPI_Timeout =>
                  Example_Status := Status;
                  Elogs.Log
                   (Log_ID  => "Xa1ScF8",
                    Message => Example_Status'Image);
                  return;
         
               when Status_OK =>
                 null;
               end;
         
      Example_Status := Status_OK;
      
      exception
         when Constraint_Error =>
            Example_Status := Exception_Overflow;
            Elogs.Log
             (Log_ID  => "B$0sNmn",
              Message => Example_Status'Image);
            return;
             
   end Example;

```

#### Example of per package additional logging
```

with RTT.IO;

package body STM32.Alogs is

   --  Drop the default buffer argument for Customised_Log API compatibility
   procedure RTT_Put_Line (Message : String) is
   begin
      RTT.IO.Put_Line (Message);
   end RTT_Put_Line;
   
   procedure Initialise
     (Software_Version : Elogs.Version_String;
      Device_ID        : Elogs.Device_ID_Bytes) is
   begin
      Elogs.Initialise (Software_Version, Device_ID);
      Log_Separator;
   end Initialise;

   procedure Log (Log_ID : Elogs.Log_ID_Type; Message : String) is

      procedure Custom_Logger is new Elogs.Customised_Log (RTT_Put_Line);

   begin
      Custom_Logger (Log_ID => Log_ID, Message => Message);
   end Log;

   procedure Status_Exception (Log_ID : Elogs.Log_ID_Type; Message : String) is

      procedure Custom_Logger is new
        Elogs.Customised_Status_Exception (RTT_Put_Line);

   begin
      Custom_Logger (Log_ID => Log_ID, Message => Message);
   end Status_Exception;

   procedure Log_Separator is
   begin
      RTT.IO.Put_Line
        ("____________________________________"
         & "____________________________________");
      RTT.IO.Put_Line ("");
   end Log_Separator;
   
end STM32.Alogs;

```

#### A note on the new shorter default length of Log_ID

Z85 is designed to maximise character usage whilst being safely used in source

code. You can maximise the entropy density of the log ID text string by

utilising the Z85 alphabet randomly or a Z85 encoder upon random bytes such as

is available from the following URL if it isn't already a crate. Compared to
Hex,

Z85 provides 45 bits of entropy vs 28.

<https://github.com/jhumphry/Ada_BinToAsc>

```
   Z85_Alphabet : constant BToA.Alphabet_85 :=
     "0123456789" &
     "abcdefghij" &
     "klmnopqrst" &
     "uvwxyzABCD" &
     "EFGHIJKLMN" &
     "OPQRSTUVWX" &
     "YZ.-:+=^!/" &
     "*?&<>()[]{" &
     "}@%$#";
```

