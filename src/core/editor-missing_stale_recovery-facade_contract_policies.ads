package Editor.Missing_Stale_Recovery.Facade_Contract_Policies is

   function Stale_State_After_Content_Change
     (Surface : Target_Surface) return Target_Availability_State;
   function Navigation_Allowed (Result : Target_Validation_Result) return Boolean;
   function Replace_Apply_Allowed (Result : Target_Validation_Result) return Boolean;
   function Build_Run_Allowed (Result : Target_Validation_Result) return Boolean;
   function Recovery_State_Is_Persistable (State : Target_Availability_State) return Boolean;
   function Persistence_Field_Allowed
     (Field : Recovery_Persistence_Field) return Boolean;

end Editor.Missing_Stale_Recovery.Facade_Contract_Policies;
