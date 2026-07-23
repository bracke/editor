with Editor.Feature_Panel;

package Editor.Feature_Diagnostics.Maintenance is

   procedure Reset_Exhausted_Projection_Predicates
     (Diagnostics : in out Diagnostics_Feature_State);

   function Validate_Diagnostic_Id_Target
     (Diagnostics         : Diagnostics_Feature_State;
      Id                  : Diagnostic_Id;
      Active_Buffer_Token : Natural) return Boolean;

   function Validate_Diagnostic_Target
     (Diagnostics         : Diagnostics_Feature_State;
      Index               : Positive;
      Active_Buffer_Token : Natural) return Boolean;

   function Validate_Row_Action
     (Diagnostics                    : Diagnostics_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Boolean;

   function Map_Diagnostic_Row_To_Item
     (Diagnostics                    : Diagnostics_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Natural;

   procedure Reset_Diagnostics_For_Buffer_Close
     (Diagnostics : in out Diagnostics_Feature_State;
      Buffer_Token : Natural);

   procedure Reset_Diagnostics_For_Project_Close
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Reset_Diagnostics_For_Workspace_Close
     (Diagnostics : in out Diagnostics_Feature_State);

   procedure Mark_Diagnostics_For_Buffer_Stale
     (Diagnostics  : in out Diagnostics_Feature_State;
      Buffer_Token : Natural);

   procedure Mark_Diagnostics_For_Source_Path_Stale
     (Diagnostics : in out Diagnostics_Feature_State;
      Old_Path    : String;
      New_Path    : String := "");

   function Clear_Build_Diagnostics
     (Diagnostics : in out Diagnostics_Feature_State) return Natural;

   procedure Reconcile_Diagnostics_After_Filter_Change
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State);

end Editor.Feature_Diagnostics.Maintenance;
