with Elogs_Test;
with Elogs;

with Ada.Command_Line;

procedure Elogs_Test_Run is
   Exceptive    : Elogs.Exception_T;
   Tests_Passed : Boolean;
begin
   Tests_Passed := Elogs_Test.Run_Tests
       (Print     => True,
        Log       => True,
        Exceptive => Exceptive);

   if Exceptive or else not Tests_Passed
   then
      Ada.Command_Line.Set_Exit_Status (Code => 1);
   end if;

   Ada.Command_Line.Set_Exit_Status (Code => 0);

end Elogs_Test_Run;
