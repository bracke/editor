with Editor.Feature_Panel;
with Editor.Project;
with Editor.Recent_Projects;
with Editor.Workspace_Persistence;

package Editor.State_Project is

   type Project_Scoped_State_Summary is record
      Has_Project_Root            : Boolean := False;
      File_Tree_Node_Count        : Natural := 0;
      File_Tree_Expansion_Count   : Natural := 0;
      Quick_Open_Result_Count     : Natural := 0;
      Project_Search_Result_Count : Natural := 0;
      Bookmark_Count               : Natural := 0;
      Bookmarks_Visible            : Boolean := False;
      Search_Results_Row_Count    : Natural := 0;
      Has_Project_Search_Query    : Boolean := False;
      Feature_Panel_Row_Count     : Natural := 0;
      Feature_Panel_Selected_Row  : Natural := 0;
      Feature_Panel_Has_Selection : Boolean := False;
      Feature_Panel_Visible       : Boolean := False;
      Feature_Panel_Focused       : Boolean := False;
      Feature_Panel_Fingerprint   : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Outline_Item_Count          : Natural := 0;
      Outline_Has_Items           : Boolean := False;
      Outline_Fingerprint         : Natural := 0;
      Feature_Message_Row_Count   : Natural := 0;
      Feature_Search_Result_Count : Natural := 0;
      Feature_Diagnostic_Row_Count : Natural := 0;
      Has_Pending_Project_Target  : Boolean := False;
   end record;

   type Project_Runtime_State is record
      Project : Editor.Project.Project_State;
      Recent_Projects : Editor.Recent_Projects.Recent_Project_List;

      --  Transient Recent Projects list selection. This is never written to
      --  Recent Projects or workspace persistence.
      Recent_Project_Selected_Index : Natural := 0;

      --  Transient Recent Projects focus marker. This is UI-only focus state,
      --  not part of recent-project or workspace persistence.
      Recent_Projects_Focused : Boolean := False;

      --  Transient UI-only restore feedback. The latest visible restore
      --  feedback may be projected as current command feedback only until the
      --  next ordinary interaction replaces restore context with normal state.
      Post_Restore_Feedback_Current : Boolean := False;
      Last_Restore_Summary_Available : Boolean := False;
      Last_Restore_Summary :
        Editor.Workspace_Persistence.Workspace_Restore_Summary;
   end record;

end Editor.State_Project;
