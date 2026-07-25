with Editor.Ada_Language_Model;
with Editor.Syntax;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Language_Model.Visibility is

   procedure Mark_Generated_Source_Awareness (Analysis : in out Analysis_Result);
   procedure Mark_Conditional_Source_Awareness (Analysis : in out Analysis_Result);
   procedure Mark_With_Clause_Awareness (Analysis : in out Analysis_Result);
   procedure Mark_Use_Clause_Awareness (Analysis : in out Analysis_Result);

   procedure Add_Visibility_Clause
     (Analysis             : in out Analysis_Result;
      Kind                 : Visibility_Clause_Kind;
      Name                 : String;
      Scope                : Scope_Id := Root_Scope;
      Source_Span                : Source_Range := (others => 1);
      Is_Context_Clause    : Boolean := False;
      Has_Limited_Modifier : Boolean := False;
      Has_Private_Modifier : Boolean := False);

   function Visibility_Clause_Count
     (Analysis : Analysis_Result;
      Scope    : Scope_Id := Scope_Id'Last) return Natural;

   function Visibility_Clause_At
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Index    : Positive) return Visibility_Clause_Info;

   function Context_Clause_Count
     (Analysis : Analysis_Result) return Natural;

   function Context_Clause_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Visibility_Clause_Info;

   function Use_Clause_Count
     (Analysis : Analysis_Result;
      Scope    : Scope_Id := Scope_Id'Last) return Natural;

   function Use_Clause_At
     (Analysis : Analysis_Result;
      Scope    : Scope_Id;
      Index    : Positive) return Visibility_Clause_Info;

   function Overflowed (Analysis : Analysis_Result) return Boolean;
   function Has_Generated_Source_Awareness (Analysis : Analysis_Result) return Boolean;
   function Has_Conditional_Source_Awareness (Analysis : Analysis_Result) return Boolean;
   function Has_With_Clause_Awareness (Analysis : Analysis_Result) return Boolean;
   function Has_Use_Clause_Awareness (Analysis : Analysis_Result) return Boolean;


end Editor.Ada_Language_Model.Visibility;
