package body Dogfood_Demo is
   procedure Run (State : in out Dogfood_State) is
   begin
      State.Value := State.Value + 1;
   end Run;

   function Known_Token return String is
   begin
      return "Dogfood_Known_Token";
   end Known_Token;
end Dogfood_Demo;
