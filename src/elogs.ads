pragma Assertion_Policy
  (Pre => Ignore, Post => Ignore, Contract_Cases => Ignore, Ghost => Ignore);
--  The pre conditions in this package are intended to be verified with SPARK
--  mode and are not meant for use at runtime.

with Ada.Characters.Latin_1;
with Elogs_Config;
with GNAT.Source_Info;
with Interfaces; use Interfaces;

--  @summary
--  Embedded Logging

--  @description
--  A logging package primarily developed for embedded use, including systems
--  without exception propagation. Validated to SPARKs Silver level and
--  so is proven absent of runtime errors. The Log_Store memory occupation
--  is configurable via alire configration variables Max_Log_Count *
--  Max_Message_Length. Although a managed or ragged array or container may
--  provide more efficient use of memory. Utilising a fixed length String
--  store results in simplifying the use of SPARK.

package Elogs with
  SPARK_Mode  => On,
  Abstract_State => State,
  Initializes => State
is
   Max_Log_Count      : constant Positive := Elogs_Config.Max_Log_Count;
   Max_Message_Length : constant Positive := Elogs_Config.Max_Message_Length;
   Device_ID_Length   : constant Positive := Elogs_Config.Device_ID_Length;
   Version_Length     : constant Positive := Elogs_Config.Version_Length;

   subtype Exception_T is Boolean;
   --  Indicates an exceptional situation has occurred.
   --
   --  Where code flow decisions are required then an alternative application
   --  specific status should be provided separately. My personal preference
   --  is enums with static predicates.
   --
   --  Exception_T was originally defaulted to False but setting it manually in
   --  the happy path to False, makes SPARK happier.

   subtype Stringle is String (1 .. Max_Message_Length);
   type Device_ID_Bytes is array (1 .. Device_ID_Length) of Unsigned_8;
   subtype Version_String is String (1 .. Version_Length);
   Empty_Stringle  : constant Stringle        :=
     [others => Ada.Characters.Latin_1.Space];
   Empty_Device_ID : constant Device_ID_Bytes := [others => 0];
   Empty_Version   : constant Version_String  :=
     [others => Ada.Characters.Latin_1.Space];

   subtype Log_ID_Type is String (1 .. 16);
   --  The Log_ID is a 64bit random hex UUID log identifier that can be easily
   --  copied and searched for within source code.

   type Log_Index is range 1 .. Max_Log_Count with
     Default_Value => 1;
     --  Log_Index, the number of logs that will be stored

   type Log_Msg_Array is array (Log_Index) of Stringle;
   type Log_ID_Array is array (Log_Index) of Log_ID_Type;
   type Log_Processed_Array is array (Log_Index) of Boolean with
     Pack;
     --  Records whether each log has been processed, resetting to false when
     --  a log is overwritten. Useful for opportunistically sending logs to a
     --  server or filesystem.

   type Stored is private;

   subtype ISO_Date_String is String (1 .. 10);

   type Log_Info is record
      Compilation_Date : ISO_Date_String := "yyyy-mm-dd";
      Software_Version : Version_String  := Empty_Version;
      Device_ID        : Device_ID_Bytes := Empty_Device_ID;
   end record;

   Empty_Log_ID : constant Log_ID_Type := [others => ' '];
   type Retrieved_Log is record
      Log_ID  : Log_ID_Type := Empty_Log_ID;
      Message : Stringle;
   end record;

   procedure Initialise
     (Software_Version : Version_String;
      Device_ID        : Device_ID_Bytes) with
     Inline;
   --  Set the logs Version number and Compilation Date. This procedure can
   --  also be used to reset the Log_Store.
   --
   --  Initialise (Software_Version => "00.01.00",
   --              Device_ID        => "

   procedure Log
     (Log_ID  : Log_ID_Type;
      Message : String) with
     Pre => Message'Length < Max_Message_Length;
   --  Logs a message along with tracing information.

   Exceptive_Prepend : constant String := "Exception: ";
   procedure Status_Exception
     (Log_ID    :     Log_ID_Type;
      Message   :     String;
      Exceptive : out Exception_T) with
     Pre => Message'Length < (Max_Message_Length - Exceptive_Prepend'Length);
   --  Creates a Log entry into the ring buffer (Log_Store) and sets Exceptive
   --  to True. The message shall have Exceptive_Prepend prepended.
   --
   --   @param Log_ID
   --  provides log tracing in any compilation mode such as when debug
   --  information is unavailable.
   --
   --   @Param Message
   --  The fixed length string to enter into the log.
   --
   --   @Param Exceptive
   --  indicates that an exception has occurred
   --
   --
   --  Example use
   --   Job (Exceptive : out Exception_T)
   --   is
   --   begin
   --    Elogs.Status_Exception
   --     (Log_ID    => "0E8B6E4104989186",
   --      Message   => "Output String is of an incorrect length"
   --      Exceptive => Exceptive);
   --   end Job;
   --
   --   Job (Exceptive => Exceptive);
   --     if Exceptive then
   --        Carry on as best as possible and optionally log further context
   --        or restart the machine
   --     end if;
   --
   --  This is not meant for usual logical flow where an enum is often useful
   --  but rather intended for exceptional conditions such as external errors
   --  and programmer error in cases where footguns cannot be avoided. An
   --  example would be timeouts that should never occur. However I would
   --  exclude logical timeouts that are expected to occur that depend upon
   --  conditions such as contention.

   procedure Status_Exception
     (Log_ID  : Log_ID_Type;
      Message : String) with
     Pre => Message'Length < (Max_Message_Length - Exceptive_Prepend'Length);
   --  The same as Status_Exception above except that this procedure does not
   --  require an Exceptive boolean
   --
   --  The purpose being that whilst an exception should generally be handled
   --  as a non code flow error Handling that as a combined yet clear status
   --  code perhaps as an predicated enum in the package(s) may be preferred.

   function Log_Count return Natural;
   --  Indicates the numbers of Logs stored.

   function Retrieve_Log_Info return Log_Info;
   --  Retrieves the logs Version number and Compilation Date entry and
   --  Device_ID;

   function Retrieve_Log
     (Log_Number : Log_Index)
      return Retrieved_Log;
   --  Retrieves a log entry to faciliate e.g. log transmissions See Log_Count
   --  to get how many logs are retrievable

   function Latest_Log return Retrieved_Log;
   --  Returns a record containing the latest message and it's Log_ID

   function Latest_Message return Stringle;

   procedure Mark_Processed (Log_Number : Log_Index);
   --  Mark a log number as having been processed.

   procedure Unmark_Processed (Log_Number : Log_Index);
   --  Unmark a log number as having been processed.

   function Processed
     (Log_Number : Log_Index)
      return Boolean;
   --  Returns whether a log number has been marked as processed by the user.

   procedure Unmark_Processed_All;
   --  Unmarks all stored logs indicating that all logs still need to be
   --  processed

   function Next_To_Process return Natural;
   --  returns the Log_Index of the log that will be overwritten next and that
   --  has not been marked as processed. This function returns 0 if all logs
   --  have been marked as processed.

private

   type Stored is record
      Compilation_Date : ISO_Date_String     := "yyyy-mm-dd";
      Software_Version : Version_String      := Empty_Version;
      Device_ID        : Device_ID_Bytes     := Empty_Device_ID;
      Index            : Log_Index           := 1;
      Log_Count        : Natural             := 0;
      Log_IDs          : Log_ID_Array        := [others => Empty_Log_ID];
      Log_Processed    : Log_Processed_Array := [others => False];
      Messages         : Log_Msg_Array       := [others => Empty_Stringle];
      --  Messages doesn't expand in Gnat studio currently. It did when it was
      --  an array of bounded strings but maybe coincidence. You can still view
      --  it by unchecking the box and adding print Log_Store.Messages.
   end record;

   Log_Store : Stored with
     Part_Of => State;

   function Compile_Date return ISO_Date_String;

   procedure Increment_Index (Index : in out Log_Index) with
     Inline;

   function Last_Used_Index
     (Index : Log_Index)
      return Log_Index;

   procedure Increment_Count (Count : in out Natural) with
     Inline;

   procedure Update_Log
     (Log_ID            : Log_ID_Type;
      Formatted_Message : Stringle) with
     Global => (In_Out => Log_Store);
   --  Adds a new log in round robin fashion to the Log_Store.

end Elogs;

--  ISC License (Simplified BSD)
--
--  Copyright (c) 2023, Kevin Chadwick Copyright (c) 2023, Elansys Limited
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
