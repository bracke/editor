with Editor.State;
with Editor.Feature_Panel;

package Editor.Feature_Panel_Controller is

   function Show_Feature
     (S       : in out Editor.State.State_Type;
      Feature : Editor.Feature_Panel.Feature_Id) return Boolean;

   procedure Rebuild_Active_Feature_Projection
     (S : in out Editor.State.State_Type);

   function Dispatch_Active_Feature_Clear
     (S : in out Editor.State.State_Type) return Boolean;

   function Has_Projection_Dispatch
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean;

   function Has_Clear_Dispatch
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean;

   function Has_Open_Dispatch
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean;

   function Has_Row_Action_Dispatch
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean;

   function Has_Lifecycle_Dispatch
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean;

   function Feature_Dispatch_Covers_All_Features return Boolean;

   procedure Reset_All_Features_For_Buffer_Close
     (S            : in out Editor.State.State_Type;
      Buffer_Token : Natural);

   procedure Reset_All_Features_For_Project_Close
     (S : in out Editor.State.State_Type);

   procedure Reset_All_Features_For_Workspace_Close
     (S : in out Editor.State.State_Type);

   function Assert_Feature_Panel_State_Consistent
     (S : Editor.State.State_Type) return Boolean;

end Editor.Feature_Panel_Controller;
