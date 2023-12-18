with Elogs;
with Interfaces; use Interfaces;
with System;

package Elogs_Test with
  SPARK_Mode => Off
is

   type Readable_ID is record
      Wafer_Coordinate_X : Unsigned_16     := 0;
      Wafer_Coordinate_Y : Unsigned_16     := 0;
      Wafer_Number       : Unsigned_8      := 0;
      Lot_Number         : String (1 .. 7) := [others => ' '];
   end record with
     Object_Size => 96, Size => 96, Bit_Order => System.Low_Order_First;

   for Readable_ID use record
      Wafer_Coordinate_X at 0 range  0 .. 15;
      Wafer_Coordinate_Y at 0 range 16 .. 31;
      Wafer_Number       at 0 range 32 .. 39;
      Lot_Number         at 0 range 40 .. 95;
   end record;

   function Run_Tests
     (Print, Log : in     Boolean := True;
      Exceptive  :    out Elogs.Exception_T)
      return Boolean;

   function Log_Count
     (Print, Log : in Boolean;
      Expected   : in Natural)
      return Boolean;

private
   function First_Intact
     (Print, Log : in Boolean;
      Expected   : in String)
      return Boolean;

   function Seconds_Is_Exception
     (Print, Log : in Boolean)
      return Boolean;

   function Round_Robin_Latest
     (Print, Log : in Boolean)
      return Boolean;
   --  Check that the store loops around successfully and then that Latest_Message
   --  returns the most recently stored log.
   --  Note that this test is quite fragile as it depends on the loop and
   --  a log and exception above and expects that the index is back to the
   --  beginning of the Log_Store.

end Elogs_Test;
