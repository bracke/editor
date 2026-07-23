with Editor.State;

package Editor.Empty_State_Guidance.Surfaces is

   function Build_All_Empty_State_Snapshots
     (S : Editor.State.State_Type) return Empty_State_Snapshot_Array;

   function Build_Main_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_File_Tree_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Quick_Open_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Project_Search_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Outline_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Diagnostics_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Build_UI_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Recent_Projects_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Config_Recovery_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

end Editor.Empty_State_Guidance.Surfaces;
