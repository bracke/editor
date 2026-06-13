package Dogfood_Demo is
   type Dogfood_State is record
      Value : Integer := 0;
   end record;

   procedure Run (State : in out Dogfood_State);
   function Known_Token return String;
end Dogfood_Demo;
