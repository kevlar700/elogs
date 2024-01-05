with Ada.Unchecked_Conversion;
with GNAT.IO;

package body Elogs_Test with
  SPARK_Mode => Off
is

   SW_Version : constant String := "00.01.00";

   Device_ID : constant Readable_ID :=
     (Wafer_Coordinate_X => 16#FFFF#,
      Wafer_Coordinate_Y => 16#E1E1#,
      Wafer_Number       => 177,
      Lot_Number         => "1234567");

   Log_Overflow : constant String (1 .. Elogs.Max_Message_Length + 11) :=
     [others => 'X'];

   function Run_Tests
     (Print, Log : in     Boolean := True;
      Exceptive  :    out Elogs.Exception_T)
      return Boolean
   is
      function To_Bytes is new Ada.Unchecked_Conversion
        (Readable_ID, Elogs.Device_ID_Bytes);

      First_Log_ID     : constant String   := "08A567C391E17867";
      All_Tests_Passed : Boolean           := True;
      Base_Log_ID      : Elogs.Log_ID_Type := "30E3AEB1F1B1A04D";
   begin
      Elogs.Initialise
        (Software_Version => SW_Version,
         Device_ID        => To_Bytes (Device_ID));

      Elogs.Log
        (Log_ID  => First_Log_ID,
         Message => "First is a Log");

      Elogs.Status_Exception
        (Log_ID    => "CC1EFD74778D0AB4",
         Message   => "Second is an exception",
         Exceptive => Exceptive);
      --  Normally we would address the exception but not for this testing.
      pragma Warnings (Off, "if statement has no effect");
      if Exceptive then
         null;
      end if;
      pragma Warnings (On, "if statement has no effect");

      --  Check that the log count does now equal two entries
      if not Log_Count
          (Print    => Print,
           Log      => Log,
           Expected => 2)
      then
         All_Tests_Passed := False;
      end if;

      --  fill up the log
      for I in 1 .. Elogs.Max_Log_Count - 2
      loop
         Base_Log_ID (1 .. I'Image'Length) := I'Image;
         Elogs.Log
           (Log_ID  => Base_Log_ID,
            Message => Log_Overflow);
      end loop;

      if not Log_Count
          (Print    => Print,
           Log      => Log,
           Expected => Elogs.Max_Log_Count)
      then
         All_Tests_Passed := False;
      end if;

      if not First_Intact
          (Print    => Print,
           Log      => Log,
           Expected => First_Log_ID)
      then
         All_Tests_Passed := False;
      end if;

      if not Seconds_Is_Exception
          (Print => Print,
           Log   => Log)
      then
         All_Tests_Passed := False;
      end if;

      --  Note that this test is quite fragile as it depends on the loop and
      --  a log and exception above and expects that the index is back to the
      --  beginning of the Log_Store.
      if not Round_Robin_Latest
          (Print => Print,
           Log   => Log)
      then
         All_Tests_Passed := False;
      end if;

      Exceptive := False;
      --  Was originally defaulted to False but setting it manually makes SPARK
      --  happier.
      return All_Tests_Passed;
   end Run_Tests;

   function Log_Count
     (Print, Log : in Boolean;
      Expected   : in Natural)
      return Boolean
   is
      Reported : Natural;
   begin
      Reported := Elogs.Log_Count;
      if Reported /= Expected then
         declare
            Output : constant String :=
              "Log_Count should have been: " & Expected'Image & " but was " &
              "actually: " & Reported'Image;
         begin
            if Print then
               GNAT.IO.Put_Line (Output);
            end if;

            if Log then
               Elogs.Log
                 (Log_ID  => "113D6461562322AB",
                  Message => Output);
            end if;
         end;
         return False;
      end if;

      if Print then
         GNAT.IO.Put_Line ("Log_Count test successful");
      end if;
      return True;
   end Log_Count;

   function First_Intact
     (Print, Log : in Boolean;
      Expected   : in String)
      return Boolean
   is
      Retrieved_Log : Elogs.Retrieved_Log;
   begin
      Retrieved_Log := Elogs.Retrieve_Log (1);
      if Retrieved_Log.Log_ID /= Expected then
         declare
            Output : constant String :=
              "The first log should have been: " & Expected &
              " but was actually: " & Retrieved_Log.Log_ID;
         begin
            if Print then
               GNAT.IO.Put_Line (Output);
            end if;

            if Log then
               Elogs.Log
                 (Log_ID  => "7C033A6A8BA3CC0F",
                  Message => Output);
            end if;
         end;
         return False;
      end if;

      if Print then
         GNAT.IO.Put_Line ("First_Intact test successful");
      end if;
      return True;
   end First_Intact;

   function Seconds_Is_Exception
     (Print, Log : in Boolean)
      return Boolean
   is
      Retrieved_Log : constant Elogs.Retrieved_Log := Elogs.Retrieve_Log (2);
      Found         : constant String              :=
        Retrieved_Log.Message
          (Elogs.Stringle'First ..
               (Elogs.Stringle'First + (Elogs.Exceptive_Prepend'Length - 1)));
   begin
      if Found /= Elogs.Exceptive_Prepend then
         declare
            Output : constant String :=
              "Seconds_Is_Exception: Expected to find: " &
              Elogs.Exceptive_Prepend & " but actually found: " & Found;
         begin
            if Print then
               GNAT.IO.Put_Line (Output);
            end if;

            if Log then
               Elogs.Log
                 (Log_ID  => "4A9EBB6F71627A6C",
                  Message => Output);
            end if;
         end;
         return False;
      end if;

      if Print then
         GNAT.IO.Put_Line ("Seconds_Is_Exception test successful");
      end if;
      return True;

   end Seconds_Is_Exception;

   function Round_Robin_Latest
     (Print, Log : in Boolean)
      return Boolean
   is
      Round_Robin_Msg : constant String     := "Round robin log";
      Retrieved_Log   : Elogs.Retrieved_Log := Elogs.Retrieve_Log (1);
      Compare         : String (1 .. Round_Robin_Msg'Length);
      Compare2        : String (1 .. Round_Robin_Msg'Length);
   begin

      Elogs.Log
        (Log_ID  => "0B34D9BCCADA2B8F",
         Message => Round_Robin_Msg);

      Retrieved_Log := Elogs.Retrieve_Log (1);
      Compare       := Elogs.Latest_Message (1 .. Compare'Length);
      Compare2      := Retrieved_Log.Message (1 .. Compare'Length);

      if Compare = Round_Robin_Msg and then Compare = Compare2 then
         if Print then
            GNAT.IO.Put_Line ("Round_Robin_Latest test successful");
         end if;
         return True;
      end if;

      declare
         Output : constant String :=
           "Round_Robin_Latest test failed: Expected: """ & Round_Robin_Msg &
           """ Latest : """ & Compare & """ First: """ & Compare2 & """";
      begin
         if Print then
            GNAT.IO.Put_Line (Output);
         end if;

         if Log then
            Elogs.Log
              (Log_ID  => "7A9D8275C823AE37",
               Message => Output);
         end if;
      end;

      return False;
   end Round_Robin_Latest;

end Elogs_Test;

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
