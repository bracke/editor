with Editor.Buffer_Types;

package Editor.Buffer_Switcher_Model.Audits is

   type Selected_Buffer_List_Audit is record
      Row_Count                        : Natural := 0;
      Selected_Row_Index               : Natural := 0;
      Selected_Row_Valid               : Boolean := True;
      Selected_Row_Is_Buffer           : Boolean := True;
      Selected_Runtime_Id_Registered   : Boolean := True;
      Selection_Cleared_When_No_Rows    : Boolean := True;
      Selection_Index_Clamped_To_Rows   : Boolean := True;
      Selection_Skips_Status_Rows       : Boolean := True;
      Selection_Is_Transient            : Boolean := True;
      Selection_Not_Persisted           : Boolean := True;
      Selection_Not_Keybinding_Payload  : Boolean := True;
      Selected_Buffer_Id                : Editor.Buffer_Types.Buffer_Id :=
        Editor.Buffer_Types.No_Buffer;
   end record;

end Editor.Buffer_Switcher_Model.Audits;
