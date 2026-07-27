with Ada.Strings.Unbounded;
with Editor.Input_Field;
with Editor.Search;

package Editor.State_Search is

   type Search_Runtime_State is record
      --  Active-buffer find state. It is transient, in-memory, and never
      --  persisted.
      Active_Find_Query   : Ada.Strings.Unbounded.Unbounded_String;
      Active_Find_Matches : Editor.Search.Search_Match_Vectors.Vector;
      Active_Find_Match   : Editor.Search.Search_Match := Editor.Search.No_Match;
      Active_Find_Stale   : Boolean := False;
      Active_Find_Wrapped : Boolean := False;
      Active_Find_Case_Sensitive : Boolean := False;
      Active_Find_Whole_Word : Boolean := False;
      Active_Find_Source_Buffer_Token : Natural := 0;

      --  Active-buffer replace state. Replace is a transient extension of
      --  canonical find and is never persisted.
      Active_Replace_Text : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Active_Replace_Error_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Active_Replace_Prompt : Boolean := False;

      Active_Find_Input  : Editor.Input_Field.Input_Field_State;
      Active_Find_Prompt : Boolean := False;
   end record;

end Editor.State_Search;
