with Editor.Diagnostics;

package Editor.State_Panel is

   type Active_Diagnostic_State is record
      Has_Active : Boolean := False;
      Index      : Editor.Diagnostics.Diagnostic_Index :=
        Editor.Diagnostics.No_Diagnostic;
   end record;

end Editor.State_Panel;
