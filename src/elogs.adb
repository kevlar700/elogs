package body Elogs with
  SPARK_Mode, Refined_State => (State => Log_Store)
is

   function Compile_Date return ISO_Date_String is
      Compiled : constant ISO_Date_String :=
        GNAT.Source_Info.Compilation_ISO_Date;
   begin
      return Compiled;
   end Compile_Date;

   procedure Initialise
     (Software_Version : in Version_String;
      Device_ID        : in Device_ID_Bytes)
   is
   begin
      Log_Store.Compilation_Date := Compile_Date;
      Log_Store.Software_Version := Software_Version;
      Log_Store.Device_ID        := Device_ID;
      Log_Store.Index            := 1;
      Log_Store.Log_Count        := 0;
      Log_Store.Log_IDs          := [others => Empty_Log_ID];
      Log_Store.Log_Processed    := [others => False];
      Log_Store.Messages         := [others => Empty_Stringle];
   end Initialise;

   procedure Update_Log
     (Log_ID            : in Log_ID_Type;
      Formatted_Message : in Stringle)
   is
   begin
      --  TODO: Locking. Protected types are not desirable as they are not
      --  compatible with every runtime or SPARKs flow analysis.
      Log_Store.Log_IDs (Log_Store.Index)       := Log_ID;
      Log_Store.Messages (Log_Store.Index)      := Formatted_Message;
      Log_Store.Log_Processed (Log_Store.Index) := False;
      Increment_Index (Log_Store.Index);
      Increment_Count (Log_Store.Log_Count);
   end Update_Log;

   procedure Log
     (Log_ID  : in Log_ID_Type;
      Message : in String)
   is
      Formatted_Message : Stringle := [others => Ada.Characters.Latin_1.Space];
   begin

      for F in Message'Range loop
         if F < Formatted_Message'Last then
            Formatted_Message (F) := Message (F);
         else
            exit;
         end if;
      end loop;

      Update_Log
        (Log_ID            => Log_ID,
         Formatted_Message => Formatted_Message);
   end Log;

   procedure Status_Exception
     (Log_ID    : in     Log_ID_Type;
      Message   : in     String;
      Exceptive :    out Exception_T)
   is
   begin
      Log
        (Log_ID  => Log_ID,
         Message => Exceptive_Prepend & Message);

      Exceptive := True;
   end Status_Exception;

   procedure Status_Exception
     (Log_ID  : in Log_ID_Type;
      Message : in String)
   is
   begin
      Log
        (Log_ID  => Log_ID,
         Message => Exceptive_Prepend & Message);

   end Status_Exception;

   procedure Increment_Index (Index : in out Log_Index) is
   begin
      if Index = Log_Index'Last then
         Index := Log_Index'First;
      else
         Index := Index + 1;
      end if;
   end Increment_Index;

   function Last_Used_Index
     (Index : in Log_Index)
      return Log_Index
   is
   begin
      if Index = Log_Index'First then
         return Log_Index'Last;
      else
         return Index - 1;
      end if;
   end Last_Used_Index;

   procedure Increment_Count (Count : in out Natural) is
   begin
      if Count < Max_Log_Count then
         Count := Count + 1;
      end if;
   end Increment_Count;

   function Log_Count return Natural is
   begin
      return Log_Store.Log_Count;
   end Log_Count;

   function Retrieve_Log_Info return Log_Info is
      Retrieved : Log_Info;
   begin
      Retrieved.Compilation_Date := Log_Store.Compilation_Date;
      Retrieved.Software_Version := Log_Store.Software_Version;
      Retrieved.Device_ID        := Log_Store.Device_ID;
      return Retrieved;
   end Retrieve_Log_Info;

   function Retrieve_Log
     (Log_Number : in Log_Index)
      return Retrieved_Log
   is
      Retrieved : Retrieved_Log;
   begin
      Retrieved.Log_ID  := Log_Store.Log_IDs (Log_Number);
      Retrieved.Message := Log_Store.Messages (Log_Number);
      return Retrieved;
   end Retrieve_Log;

   function Processed
     (Log_Number : in Log_Index)
      return Boolean
   is
   begin
      return Log_Store.Log_Processed (Log_Number);
   end Processed;

   procedure Mark_Processed (Log_Number : in Log_Index) is
   begin
      Log_Store.Log_Processed (Log_Number) := True;
   end Mark_Processed;

   procedure Unmark_Processed (Log_Number : in Log_Index) is
   begin
      Log_Store.Log_Processed (Log_Number) := False;
   end Unmark_Processed;

   procedure Unmark_Processed_All is
   begin
      for M in Log_Store.Log_Processed'Range loop
         Log_Store.Log_Processed (M) := False;
      end loop;
   end Unmark_Processed_All;

   function Next_To_Process return Natural is
      Logs_Stored : constant Natural := Log_Count;
   begin
      if Logs_Stored > 0 and then Logs_Stored < Natural (Log_Index'Last) then
         for F in Log_Index'First .. Log_Index (Logs_Stored) loop
            if not Processed (F) then
               return Natural (F);
            end if;
         end loop;
      end if;

      for F in Log_Store.Index .. Log_Index'Last loop
         if not Processed (F) then
            return Natural (F);
         end if;
      end loop;

      for F in Log_Index'First .. Log_Store.Index loop
         if not Processed (F) then
            return Natural (F);
         end if;
      end loop;

      return 0;
   end Next_To_Process;

   function Latest_Log return Retrieved_Log is
   begin
      return Retrieve_Log (Last_Used_Index (Log_Store.Index));
   end Latest_Log;

   function Latest_Message return Stringle is
   begin
      return Latest_Log.Message;
   end Latest_Message;

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
