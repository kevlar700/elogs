with Ada.Unchecked_Conversion;
with GNAT.IO;

package body Elogs_Test
  with SPARK_Mode => Off
is

   SW_Version : constant String := "00.01.00";

   Log_Overflow : constant String (1 .. Elogs.Max_Message_Length + 11) :=
     [others => 'X'];

   function Run_Tests return Boolean is
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

      Initial_Log_Count : constant Natural := 2;

      First_Log_ID : constant String := "*JmnTd?";

      All_Tests_Passed : Boolean := True;
      Base_Log_ID      : Elogs.Log_ID_Type := "xc[9u)U";

      type Status_Code is (First_Is_A_Log, Exception_Second_Is_An_Exception);
      Status : Status_Code;
   begin
      Elogs.Initialise
        (Software_Version  => SW_Version,
         Device_ID         => To_Bytes (Device_ID),
         Additional_Logger => GNAT.IO.Put_Line'Access);

      Status := First_Is_A_Log;

      Elogs.Log (Log_ID => First_Log_ID, Message => Status'Image);

      Status := Exception_Second_Is_An_Exception;

      Elogs.Log
        (Log_ID  => "k*YYt9>",
         Message => Exception_Second_Is_An_Exception'Image);

      --  Check that the log count does now equal two entries
      if not Log_Count (Expected => Initial_Log_Count) then
         All_Tests_Passed := False;
      end if;

      --  fill up the log
      for I in 1 .. Elogs.Max_Log_Count - Initial_Log_Count loop
         Base_Log_ID (1 .. I'Image'Length) := I'Image;
         Elogs.Log (Log_ID => Base_Log_ID, Message => Log_Overflow);
      end loop;

      GNAT.IO.Put_Line
        ("If Initialise with an additional logger process was successful then "
         & "you should see many log entries above with XXXXX...");

      if not Log_Count (Expected => Elogs.Max_Log_Count) then
         All_Tests_Passed := False;
      end if;

      if not First_Intact (Expected => First_Log_ID) then
         All_Tests_Passed := False;
      end if;

      --  Note that this test is quite fragile as it depends on the loop and
      --  a log and exception above and expects that the index is back to the
      --  beginning of the Log_Store.
      if not Round_Robin_Latest then
         All_Tests_Passed := False;
      end if;

      return All_Tests_Passed;
   end Run_Tests;

   function Log_Count (Expected : Natural) return Boolean is
      Reported : Natural;
   begin
      Reported := Elogs.Log_Count;
      if Reported /= Expected then
         Elogs.Log
           (Log_ID  => "YYu5Eop",
            Message =>
              "Log_Count should have been: "
              & Expected'Image
              & " but was "
              & "actually: "
              & Reported'Image);
         return False;
      end if;

      GNAT.IO.Put_Line ("7g3cK.5" & ": " & "Log_Count test successful");
      return True;
   end Log_Count;

   function First_Intact (Expected : String) return Boolean is
      Retrieved_Log : Elogs.Retrieved_Log;
   begin
      Retrieved_Log := Elogs.Retrieve_Log (1);
      if Retrieved_Log.Log_ID /= Expected then
         Elogs.Log
           (Log_ID  => "C%%:3/H",
            Message =>
              "The first log should have been: "
              & Expected'Image
              & " but was actually: "
              & Retrieved_Log.Log_ID);
         return False;
      end if;

      GNAT.IO.Put_Line ("gI+2(Fj" & ": " & "First_Intact test successful");
      return True;
   end First_Intact;

   function Round_Robin_Latest return Boolean is
      Round_Robin_Msg : constant String := "Round robin log";
      Retrieved_Log   : Elogs.Retrieved_Log := Elogs.Retrieve_Log (1);
      Compare         : String (1 .. Round_Robin_Msg'Length);
      Compare2        : String (1 .. Round_Robin_Msg'Length);
   begin

      Elogs.Log (Log_ID => "AH.L:c[", Message => Round_Robin_Msg);

      Retrieved_Log := Elogs.Retrieve_Log (1);
      Compare := Elogs.Latest_Message (1 .. Compare'Length);
      Compare2 := Retrieved_Log.Message (1 .. Compare'Length);

      if Compare = Round_Robin_Msg and then Compare = Compare2 then
         GNAT.IO.Put_Line
           ("?IvVK/8" & ": " & "Round_Robin_Latest test successful");
         return True;
      end if;

      GNAT.IO.Put_Line
        ("hPn*DeA"
         & ": "
         & "Round_Robin_Latest test failed: Expected: """
         & Round_Robin_Msg
         & """ Latest : """
         & Compare
         & """ First: """
         & Compare2
         & """");

      return False;
   end Round_Robin_Latest;

end Elogs_Test;

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
