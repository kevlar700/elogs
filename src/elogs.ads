pragma
  Assertion_Policy
    (Pre => Ignore, Post => Ignore, Contract_Cases => Ignore, Ghost => Ignore);
--  The pre conditions in this package are intended to be verified with SPARK
--  mode and are not meant for use at runtime.

with Elogs_Config;
with GNAT.Source_Info;
with Interfaces; use Interfaces;

--  Embedded Logging:
--  A logging package primarily developed for embedded use, including systems
--  without exception propagation. Validated to SPARKs Silver level and
--  so is proven absent of runtime errors. The Log_Store memory occupation
--  is configurable via alire configration variables Max_Log_Count *
--  Max_Message_Length. Although a managed or ragged array or container may
--  provide more efficient use of memory. Utilising a fixed length String
--  store results in simplifying the use of SPARK.

package Elogs
  with SPARK_Mode => On, Abstract_State => State, Initializes => State
is
   Max_Log_Count      : constant Positive := Elogs_Config.Max_Log_Count;
   Max_Message_Length : constant Positive := Elogs_Config.Max_Message_Length;
   Device_ID_Length   : constant Positive := Elogs_Config.Device_ID_Length;
   Version_Length     : constant Positive := Elogs_Config.Version_Length;
   Log_ID_Length      : constant Positive := Elogs_Config.Log_ID_Length;

   subtype Stringle is String (1 .. Max_Message_Length);
   type Device_ID_Bytes is array (1 .. Device_ID_Length) of Unsigned_8;
   subtype Version_String is String (1 .. Version_Length);
   Empty_Stringle  : constant Stringle := [others => ' '];
   Empty_Device_ID : constant Device_ID_Bytes := [others => 0];
   Empty_Version   : constant Version_String := [others => ' '];

   --  The Log_ID is a random log identifier for each log entry that can be
   --  easily copied and searched for within source code. It defaults to a 45
   --  bit 7 character Z85 encoded random string that should be optimal for all
   --  light runtime use cases. It can however be configured for anything you
   --  like such as an incremental number or a structured string of any length.
   --
   --   A Z85 encoder can be found at: https://github.com/jhumphry/Ada_BinToAsc
   --
   --  It utilises the following character set chosen to be maximal but safe
   --  for use in source code and terminals.
   --
   --     Z85_Alphabet : constant BToA.Alphabet_85 :=
   --       "0123456789" &
   --       "abcdefghij" &
   --       "klmnopqrst" &
   --       "uvwxyzABCD" &
   --       "EFGHIJKLMN" &
   --       "OPQRSTUVWX" &
   --       "YZ.-:+=^!/" &
   --       "*?&<>()[]{" &
   --       "}@%$#";
   --
   subtype Log_ID_Type is String (1 .. Log_ID_Length);

   --  Log_Index, the number of logs that will be stored
   type Log_Index is range 1 .. Max_Log_Count with Default_Value => 1;

   type Log_Msg_Array is array (Log_Index) of Stringle;
   type Log_ID_Array is array (Log_Index) of Log_ID_Type;

   --  Records whether each log has been processed, resetting to false when
   --  a log is overwritten. Useful for opportunistically sending logs to a
   --  server or filesystem.
   type Log_Processed_Array is array (Log_Index) of Boolean with Pack;

   type Stored is private;

   subtype ISO_Date_String is String (1 .. 10);

   type Log_Info is record
      Compilation_Date : ISO_Date_String := "yyyy-mm-dd";
      Software_Version : Version_String := Empty_Version;
      Device_ID        : Device_ID_Bytes := Empty_Device_ID;
   end record;

   Empty_Log_ID : constant Log_ID_Type := [others => ' '];
   type Retrieved_Log is record
      Log_ID  : Log_ID_Type := Empty_Log_ID;
      Message : Stringle;
   end record;

   type Additional_Logger_Type is not null access procedure (Mesage : String);

   --  Set the logs Version number and Compilation Date. This procedure can
   --  also be used to reset the Log_Store.
   --
   --  Initialise (Software_Version => "00.01.00",
   --              Device_ID        => 16#00112233445566778899AABBCC#);
   procedure Initialise
     (Software_Version : Version_String; Device_ID : Device_ID_Bytes)
   with Inline;

   --  Set the logs Version number and Compilation Date. This procedure can
   --  also be used to reset the Log_Store. This version of Initialise also
   --  enables running an arbitrary procedure along side logging
   --
   --   Initialise (Software_Version  => "00.01.00",
   --               Device_ID         => 16#00112233445566778899AABBCC#,
   --               Additional_Logger => GNAT.IO.Put_Line);
   --
   --   Note: You will want to use the generic Customised_Logger below if you
   --  wish to customise the logging process per package. The additional logger
   --  set here will be global to the application and set at runtime.
   procedure Initialise
     (Software_Version  : Version_String;
      Device_ID         : Device_ID_Bytes;
      Additional_Logger : Additional_Logger_Type)
   with Inline;

   --  Logs a message along with tracing ID.
   procedure Log (Log_ID : Log_ID_Type; Message : String);

   --  Provide a nicer facility than composition via a child package for adding
   --  custom logging.
   --   @Example
   --   procedure Log is new Customised_Log (GNAT.IO.Put_Line);
   generic
      with procedure Customised_Logger (Message : String);
   procedure Customised_Log (Log_ID : Log_ID_Type; Message : String);

   --  Indicates the numbers of Logs stored.
   function Log_Count return Natural;

   --  Retrieves the logs Version number and Compilation Date entry and
   --  Device_ID;
   function Retrieve_Log_Info return Log_Info;

   --  Retrieves a log entry to faciliate e.g. log transmissions See Log_Count
   --  to get how many logs are retrievable
   function Retrieve_Log (Log_Number : Log_Index) return Retrieved_Log;

   --  Returns a record containing the latest message and it's Log_ID
   function Latest_Log return Retrieved_Log;

   function Latest_Message return Stringle;

   --  Mark a log number as having been processed.
   procedure Mark_Processed (Log_Number : Log_Index);

   --  Unmark a log number as having been processed.
   procedure Unmark_Processed (Log_Number : Log_Index);

   --  Returns whether a log number has been marked as processed by the user.
   function Processed (Log_Number : Log_Index) return Boolean;

   --  Unmarks all stored logs indicating that all logs still need to be
   --  processed
   procedure Unmark_Processed_All;

   --  returns the Log_Index of the log that will be overwritten next and that
   --  has not been marked as processed. This function returns 0 if all logs
   --  have been marked as processed.
   function Next_To_Process return Natural;

private

   procedure Additional_Logger (Message : String) is null;

   type Stored is record
      Compilation_Date       : ISO_Date_String := "yyyy-mm-dd";
      Software_Version       : Version_String := Empty_Version;
      Device_ID              : Device_ID_Bytes := Empty_Device_ID;
      Index                  : Log_Index := 1;
      Log_Count              : Natural := 0;
      Log_IDs                : Log_ID_Array := [others => Empty_Log_ID];
      Log_Processed          : Log_Processed_Array := [others => False];
      --  Messages doesn't expand in Gnat studio currently. It did when it was
      --  an array of bounded strings but maybe coincidence. You can still view
      --  it by unchecking the box and adding print Log_Store.Messages.
      Messages               : Log_Msg_Array := [others => Empty_Stringle];
      Additional_Log_Enabled : Boolean := False;
      Additional_Log_Process : Additional_Logger_Type :=
        Additional_Logger'Access;
   end record;

   Log_Store : Stored
   with Part_Of => State;

   function Compile_Date return ISO_Date_String;

   procedure Increment_Index (Index : in out Log_Index)
   with Inline;

   function Last_Used_Index (Index : Log_Index) return Log_Index;

   procedure Increment_Count (Count : in out Natural)
   with Inline;

   --  Adds a new log in round robin fashion to the Log_Store.
   procedure Update_Log (Log_ID : Log_ID_Type; Formatted_Message : Stringle)
   with Global => (In_Out => Log_Store);

end Elogs;

--  BSD License
--
--  Copyright (C) 2026, Elansys <elansys-open_source@elansys.co>
--
--  Permission to use, copy, modify, and distribute this software for any
--  purpose with or without fee is hereby granted, provided that the above
--  copyright notice and this permission notice appear in all copies.
--
--  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
--  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
--  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
--  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
--  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
--  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
--  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
