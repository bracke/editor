with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Semantic_Outline_Targets is

   type Outline_Indexed_Target is record
      Available : Boolean := False;
      Path      : Unbounded_String := Null_Unbounded_String;
      Key       : Editor.Ada_Project_Index.Indexed_File_Key;
      Line      : Positive := 1;
      Column    : Positive := 1;
   end record;

   function Find_Indexed_Outline_Target
     (S             : Editor.State.State_Type;
      Id            : Editor.Commands.Command_Id;
      Service       : in out Editor.Ada_Language_Service.Service_State;
      Track_Request : Boolean := False) return Outline_Indexed_Target;

end Editor.Executor.Semantic_Outline_Targets;
