package Unit_Test_Build_Lock is
   function Lock_Path return String;
   function Held return Boolean;
   function Acquire (Max_Attempts : Positive := 300) return Boolean;
   procedure Release;
end Unit_Test_Build_Lock;
