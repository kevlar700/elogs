with Elogs;
with Interfaces; use Interfaces;
with System;

package Elogs_Test with
  SPARK_Mode => Off
is

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
     --  Check that the store loops around successfully and then that
     --  Latest_Message returns the most recently stored log. Note that
     --  this test is quite fragile as it depends on the loop and a log and
     --  exception above and expects that the index is back to the beginning
     --  of the Log_Store.

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
