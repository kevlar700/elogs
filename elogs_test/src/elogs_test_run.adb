with Elogs_Test;
with Elogs;

with Ada.Command_Line;

procedure Elogs_Test_Run is
   Tests_Passed : Boolean;
begin
   Tests_Passed := Elogs_Test.Run_Tests;

   if not Tests_Passed then
      Ada.Command_Line.Set_Exit_Status (Code => 1);
   end if;

   Ada.Command_Line.Set_Exit_Status (Code => 0);

end Elogs_Test_Run;

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
