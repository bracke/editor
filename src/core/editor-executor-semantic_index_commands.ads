with Editor.State;

package Editor.Executor.Semantic_Index_Commands is

   function Is_Ada_Source_Path
     (Path : String) return Boolean;

   procedure Publish_Service_Diagnostics_To_Feature
     (S            : in out Editor.State.State_Type;
      Path         : String;
      Buffer_Token : Natural);

   procedure Refresh_Project_Language_Index
     (S                  : in out Editor.State.State_Type;
      Build_Semantics    : Boolean;
      Indexed_File_Count : out Natural;
      Indexed_Symbols    : out Natural;
      Skipped_File_Count : out Natural;
      Read_Error_Count   : out Natural);

   procedure Load_Global_Active_Preserving_Language_Index
     (S : in out Editor.State.State_Type);

   procedure Rebuild_Language_Index_After_File_Lifecycle
     (S : in out Editor.State.State_Type);

   procedure Clear_Service_Semantic_Diagnostics_From_Feature
     (S : in out Editor.State.State_Type);

end Editor.Executor.Semantic_Index_Commands;
