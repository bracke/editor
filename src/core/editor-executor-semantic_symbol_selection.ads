with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Model;
with Editor.Executor.Semantic_Navigation_Commands;
with Editor.State;

package Editor.Executor.Semantic_Symbol_Selection is

   type Selected_Semantic_Symbol is record
      Available : Boolean := False;
      Name      : Unbounded_String := Null_Unbounded_String;
      Kind      : Editor.Ada_Language_Model.Symbol_Kind :=
        Editor.Ada_Language_Model.Symbol_Unknown;
      Profile   : Unbounded_String := Null_Unbounded_String;
   end record;

   function To_Navigation_Symbol
     (Symbol : Selected_Semantic_Symbol)
      return Editor.Executor.Semantic_Navigation_Commands.Semantic_Symbol;

   function Current_Semantic_Symbol
     (S : Editor.State.State_Type) return Selected_Semantic_Symbol;

   function Current_Completion_Symbol
     (S : Editor.State.State_Type) return Selected_Semantic_Symbol;

   function Current_Semantic_Symbol_Name
     (S : Editor.State.State_Type) return String;

end Editor.Executor.Semantic_Symbol_Selection;
