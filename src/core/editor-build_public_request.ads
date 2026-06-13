with Editor.Build_UI;
with Editor.External_Producers;
with Editor.Build_Working_Context;

package Editor.Build_Public_Request is

   type Public_Build_Request_Conversion_Result is record
      Status  : Editor.Build_UI.Public_Build_UI_Validation_Status :=
        Editor.Build_UI.Build_UI_Rejected_Not_Visible;
      Request : Editor.External_Producers.Build_Run_Request;
      Input   : Editor.External_Producers.Public_Build_Command_Input;
   end record;

   function Build_Public_Request_From_UI_State
     (State : Editor.Build_UI.Public_Build_UI_State)
      return Public_Build_Request_Conversion_Result;

   function Assert_Public_Build_Command_UX_Foundation_Coherent
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean;

   function Assert_Public_Build_Working_Context_Foundation_Coherent
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean;

end Editor.Build_Public_Request;
